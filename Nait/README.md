# 놀고 있습니다.
//코드 분활을 하지 않은 코드입니다.
//댓글 삭제 및 수정이 불가능한 코드입니다.
//API요청을 하면 더미 데이터가 전송되는 (모바일)데이터 낭비 코드입니다...?
//예외처리를 하지 않은 not found but found 코드입니다...?
//API doc 없데이트해야함
//SQL쿼리문 이모지 넣으면 서버 터짐
이 코드 보는 꿀팁
뭔가 긴 영어로된 초록색이 있다? 하면 그건 SQL 쿼리문임
SQL문에서는 if else구문이 자주 나오는데 한줄에 있는건 주로 예외처리 압축한거니까 else부터 보면 됨
dabglist태이블:주제 목록
name, discription
lyoikilist태이블:영역 목록
name, discription, dabg, lastid(해당 영역에서 마지막으로 생성된 글의 id)
doclist태이블:글 목록
title, body, dabg, lyoiki
cmtlist태이블:댓글 목록
body,dabg,lyoiki,docid
