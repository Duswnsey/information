//셋업
const express = require('express');
const app = express();
const port = 3001; //포트 번호를 바꿀 수 있음
const mysql = require('mysql');
//db셋팅
const db = mysql.createConnection({
    host     : 'localhost',
    port     : 3306,
    user     : 'root',
    password : 'a',
    database : 'wait'
});
db.connect();
app.use(express.json()) //post요청에서 body 얻는 기능
//동일 출처 허용(인데 어짜피 세션채크하면 보안 문제를 걱정할 필요가 없기 때문에 모든 출처를 다 허용)
app.use((req, res, next) => {
    res.append('Access-Control-Allow-Origin', ['*']);
    res.append('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
    res.append('Access-Control-Allow-Headers', 'Content-Type');
    next();
});
app.use(cookieParser(process.env.SALT));
app.use(session({
    secret: process.env.SALT, // 암호화하는 데 쓰일 키
    resave: false, // 세션을 언제나 저장할지 설정함
    saveUninitialized: true, // 세션에 저장할 내역이 없더라도 처음부터 세션을 생성할지 설정
    cookie: {	//세션 쿠키 설정 (세션 관리 시 클라이언트에 보내는 쿠키)
    httpOnly: true, // 자바스크립트를 통해 세션 쿠키를 사용할 수 없도록 함
    Secure: true
    },
    name: 'session-cookie' // 세션 쿠키명 디폴트값은 connect.sid이지만 다른 이름을 줄수도 있다.
  }));
// 라우터
app.get('/', (req, res) => {
    res.send("༼ つ ◕_◕ ༽つ페치<br>┻━┻ ︵ヽ(`Д´)ﾉ︵ ┻━┻안해!!!<br>ヾ(⌐■_■)ノ♪이게 되네")
})
//주제 리스트를 불러오는 API
app.get('/dabg', (req,res) => {
    //주제 목록을 반환한다(not found but found)
    db.query(`SELECT * FROM dabglist`, (err, _res) => {if (err) {throw err;} res.send(_res)})
})
//주제 만드는 API 
app.post('/dabg', (req, res) => {
    let name = req.body.name
    let discription = req.body.discription
    db.query('SELECT * FROM dabglist WHERE name=?', [name], (err, _res) => { //동명의 주제의 정보를 받아오기
        if (err) {throw err;} else if (_res[0] == undefined) { //동명의 주제가 안존재한다면
            //주제를 생성한다    
            db.query(`INSERT INTO dabglist (name, discription) VALUES (?, ?)`, [name, discription], (err, _res) => {if (err) {throw err;} else {res.send('주제가 성공적으로 생성되었습니다.')}})
        } else {res.send("이미 존제하는 주제 이름입니다.");}
    })
})
//주제를 수정하는 API
app.post('/dabg/:dabgname/edit', (req, res) => {
    let dabg   = req.params.dabgname; //before
    let name   = req.body.name; //after
    let discription  = req.body.discription; //after
    //not found but found
    //dabglist, lyoikilist, doclist, cmtlist 에서 해당 dabg에 속해있는 모든 요소들을 새로운 이름으로 마이그래이션한다. (따라서 영역, 글, 댓글이 많으면 그만큼 많은 시간이 소요될 수 있으나 그런거 생각하니까 nodejs 쓰는거지...)
    db.query(`UPDATE dabglist set name=?,discription=? WHERE name=?`, [name, discription, dabg], (err, _res) => {if (err) {throw err}})
    db.query(`UPDATE lyoikilist set dabg=? WHERE dabg=?`, [name, dabg], (err, _res) => {if (err) {throw err}})
    db.query(`UPDATE doclist set dabg=? WHERE dabg=?`, [name, dabg], (err, _res) => {if (err) {throw err}})
    db.query(`UPDATE cmtlist set dabg=? WHERE dabg=?`, [name, dabg], (err, _res) => {if (err) {throw err} else {res.send("주제를 수정하는 중입니다.")}})
})
//주제를 삭제하는 API
app.delete('/dabg/:dabgname', (req, res) => {
    let dabg = req.params.dabgname
    //해당 주제에 속해있는 모든 요소를 삭제(not found but found)
    db.query(`DELETE FROM dabglist WHERE name=?`, [dabg], (err, _res) => {if (err) {throw err}})
    db.query(`DELETE FROM lyoikilist WHERE dabg=?`, [dabg], (err, _res) => {if (err) {throw err}})
    db.query (`DELETE FROM doclist WHERE dabg=?`, [dabg], (err, _res) => {if (err) {throw err}})
    db.query (`DELETE FROM cmtlist WHERE dabg=?`, [dabg], (err, _res) => {if (err) {throw err} else {res.send("주제를 삭제하는 중입니다.")}})
})
//영역 리스트를 불러오는 API
app.get('/dabg/:dabgname', (req, res) => {
    //해당 주제에서 영역 리스트를 반환(not found but found)
    db.query(`SELECT * FROM lyoikilist WHERE dabg=?`, [req.params.dabgname], (err, result) => {if (err) {throw err;} else {res.send(result)}})
})
//영역을 생성하는 API
app.post('/dabg/:dabgname', (req, res) => {
    let name = req.body.name
    let discription = req.body.discription
    let dabg = req.params.dabgname
    //해당 영역에서 동명의 이름을 가진 영역을 찾는다
    db.query(`SELECT * FROM lyoikilist WHERE name=? AND dabg=?`, [name, dabg], (err, _res) => {
        if (err) {throw err;} else if (_res[0] == undefined) { //동명의 영역이 없으면
            //해당 영역을 만든다
            db.query(`INSERT INTO lyoikilist (name, discription, dabg, lastid) VALUES (?,?,?,0)`, [name, discription, dabg] , (err, _res) => {if (err) {throw err;} else {res.send('성공적으로 영역을 생성하였습니다.');}})
        } else {res.send('이미 존재하는 영역입니다.')}
    })
})
//영역을 수정하는 API
app.post('/dabg/:dabgname/:lyoiki/edit', (req, res) => {
    let dabg   = req.params.dabgname;
    let lyoiki = req.params.lyoiki;
    let name   = req.body.name;
    let discription  = req.body.discription;
    //해당 영역에 속해있는 모든 요소를 삭제 (not found but found)
    db.query(`UPDATE lyoikilist set name=?,discription=? WHERE dabg=? AND name=?`, [name, discription, dabg, lyoiki], (err, _res) => {if (err) {throw err}})
    db.query(`UPDATE doclist set lyoiki=? WHERE dabg=? AND lyoiki=?`, [name, dabg, lyoiki], (err, _res) => {if (err) {throw err}})
    db.query(`UPDATE cmtlist set lyoiki=? WHERE dabg=? AND lyoiki=?`, [name, dabg, lyoiki], (err, _res) => {if (err) {throw err} else {res.send('성공')}})
})
//글을 가져오는 API
app.get('/dabg/:dabgname/:lyoiki', (req, res) => {
    let dabg = req.params.dabgname
    let lyoiki = req.params.lyoiki
    //고의적인 not found but found
    db.query(`SELECT * FROM doclist WHERE dabg=? AND lyoiki=?`, [dabg, lyoiki], (err, _res) => {
        if (err) {throw err} else if (_res[0] == undefined) {
            res.header(404);
            res.send("[]")
        } else {res.send(_res)}
    })
})
//글을 생성하는 API
app.post('/dabg/:dabgname/:lyoikiname', (req, res) => {
    let title = req.body.title
    let body = req.body.body
    let dabg = req.params.dabgname
    let lyoiki = req.params.lyoikiname
    //해당 영역의 lastid값을 가져온다
    db.query(`SELECT * FROM lyoikilist WHERE name=? AND dabg=?`, [lyoiki, dabg], (err, _res) => {
        if (err) {throw err} else {
            let lastid = _res[0].lastid
            let id = lastid+1
            //lastid값을 id로한 글을 만든다
            db.query(`INSERT INTO doclist (dabg, lyoiki, title, body, id) VALUES (?, ?, ?, ?, ${lastid})`, [dabg, lyoiki, title, body], (err, _res) => {if (err) {throw err;} else {res.send('성공적으로 글을 생성하였습니다')}})
            //db의 lastid값에 1을 추가한다.
            db.query(`UPDATE lyoikilist SET lastid=? WHERE dabg=? AND name=?`, [id, dabg, lyoiki], (err, _res) => {if (err) {throw err;}})
        }
    })
})

//글 정보를 불러오는 API
app.get('/info/:dabg/:lyoiki/:doc', (req, res) => {
    let dabg = req.params.dabg;
    let lyoiki = req.params.lyoiki;
    let doc = req.params.doc;
    //해당 글을 조회한다
    db.query(`SELECT * FROM doclist WHERE dabg=? AND lyoiki=? AND id=?`, [dabg, lyoiki, doc], (err, _res) => {
        if (err) {throw err;} else if (_res[0] == undefined) { //해당 글이 없으면
            res.status(404);
            res.send("해당 글은 존제하지 않는 글입니다.");
        } else {res.send(_res[0])} //글이 있으면 그 글의 정보를 보낸다.
    })
})
//영역을 삭제하는 API
app.delete('/dabg/:dabgname/:lyoiki', (req, res) => {
    let dabg = req.params.dabgname
    let lyoiki = req.params.lyoiki
    //해당 영역에 있는 모든 요소를 삭제한다
    db.query(`DELETE FROM lyoikilist WHERE dabg=? AND name=?`, [dabg, lyoiki], (err, _res) => {if (err) {throw err}})
    db.query (`DELETE FROM doclist WHERE dabg=? AND lyoiki=?`, [dabg, lyoiki], (err, _res) => {if (err) {throw err}})
    db.query (`DELETE FROM cmtlist WHERE dabg=? AND lyoiki=?`, [dabg, lyoiki], (err, _res) => {if (err) {throw err} else {res.send("영역을 삭제하는중 입니다.")}})
})
//글을 삭제하는 API
app.delete('/dabg/:dabgname/:lyoiki/:id', (req, res) => {
    let dabg = req.params.dabgname
    let lyoiki = req.params.lyoiki
    let id = req.params.id
    //해당 글에 속해있는 모든 요소를 삭제한다
    db.query (`DELETE FROM doclist WHERE dabg=? AND lyoiki=? AND id=?`, [dabg, lyoiki, id], (err, _res) => {if (err) {throw err}})
    db.query (`DELETE FROM cmtlist WHERE dabg=? AND lyoiki=? AND docid=?`, [dabg, lyoiki, id], (err, _res) => {if (err) {throw err} else {res.send("글을 성공적으로 삭제해였습니다.")}})
})
//글을 수정하는 API
app.post('/dabg/:dabgname/:lyoiki/:doc/edit', (req, res) => {
    let dabg   = req.params.dabgname;
    let lyoiki = req.params.lyoiki;
    let doc    = req.params.doc;
    let body   = req.body.body;
    let title  = req.body.title;
    //해당 글을 수정한다
    db.query(`UPDATE doclist set title=?,body=? WHERE dabg=? AND lyoiki=? AND id=?`, [title, body, dabg, lyoiki, doc], (err, _res) => {if (err) {throw err}})
})
//댓글 리스트를 불러오는 API
app.get('/dabg/:dabg/:lyoiki/:doc/comment', (req, res) => {
    let dabg = req.params.dabg;
    let lyoiki = req.params.lyoiki;
    let doc = req.params.doc;
    //해당 글의 댓글 리스트를 반환한다.
    db.query(`SELECT * FROM cmtlist WHERE dabg=? AND lyoiki=? AND docid=?`, [dabg, lyoiki, doc], (err, _res) => {if (err) {throw err;} else {res.send(_res)}})
})
//댓글을 쓰는 API
app.post('/dabg/:dabg/:lyoiki/:doc', (req, res) => {
    let body = req.body.body;
    let dabg = req.params.dabg;
    let lyoiki = req.params.lyoiki;
    let doc = req.params.doc;
    //해당 글에 댓글을 단다
    db.query(`INSERT INTO cmtlist (dabg, lyoiki, docid, body) VALUES (?,?,?,?)`, [dabg, lyoiki, doc, body], (err, _res) => {if (err) {throw err;} else {res.send("성공적으로 댓글을 달았습니다.")}})
})
//유저를 생성하는 API
app.post('/user/make', (req, res) => {
    let username = req.body.name
    let password = req.body.password
    let discription = req.body.discription
    db.query(`SELECT * FROM wait.users WHERE name=?`, [username], (err, _res) => {if (err) { throw err }
        else if (_res[0] == undefined) { db.query(`INSERT INTO users (name, password, discription) VALUES (?, ?, ?)`, [username, password, discription], (err, _res) => { res.send("성공")})}
        else {res.send ("이미 존제하는 이름입니다.")}
    })
    //let encrypted = hash_하는거_있잖아(password + process.env.SALT)
})
//주제 정보
app.get(`/info/:dabgname`, (req, res) => {
    db.query(`SELECT * FROM dabglist WHERE name=?`, [req.params.dabgname], (err, _res) => {if (err) {throw err} else {res.send (_res[0])}})})
//영역 정보
app.get(`/info/:dabgname/:lyoikiname`, (req, res) => {
    db.query(`SELECT * FROM lyoikilist WHERE dabg=? AND name=?`, [req.params.dabgname, req.params.lyoikiname], (err, _res) => {if (err) {throw err} else {res.send(_res[0])}})
})
//document
app.get('/doc', (req, res) => {
    res.sendFile(__dirname + '/man.html')
})
//404
app.get('/*', (req, res) => {
    res.status(404)
    res.send("<title>404 Not found 404</title>혹시 당신 크룰링 하려는거야..? 아님 URL을 잘못 입력했어??? 미안하지만 여기엔 API 문서와 API 라우터밖에 없어... 뭘 가지고 싶으면 내가 가지고 있는 전부인 404를 줄깨")
})

app.listen(port, () => {console.log(`app listening on ${port}`)})