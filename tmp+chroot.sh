# Please, run this script as builder user!!!
# How to make builder user:
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter04/addinguser.html
# set variables
ISDIR="/mnt/ynjn"

# binutils
tar -xf binutils-2.42.tar.xz
cd binutils-2.42
mkdir -v build
cd       build
../configure --prefix=$ISDIR/tools \
             --with-sysroot=$ISDIR\
             --target=$(uname -m)-ynjun-linux-gnu   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
make
make install
cd ../..
rm -rf binutils-2.42

# gcc
tar -xf gcc-14.1.0.tar.xz
cd gcc-14.1.0
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
../configure                  \
    --target=$(uname -m)-ynjun-linux-gnu         \
    --prefix=$ISDIR/tools       \
    --with-glibc-version=2.39 \
    --with-sysroot=$ISDIR      \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
make
make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($(uname -m)-ynjun-linux-gnu-gcc -print-libgcc-file-name)`/include/limits.h
cd ..
rm -rf gcc-14.1.0

# linux AIP headers
tar -xf linux-6.9.9.tar.xz
cd linux-6.9.9
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $ISDIR/usr
cd ..
rm -rf linux-6.9.9

# glibc
tar -xf glibc-2.39.tar.xz
cd glibc-2.39
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $ISDIR/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $ISDIR/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $ISDIR/lib64/ld-lsb-x86-64.so.3
    ;;
esac
patch -Np1 -i ../glibc-2.39-fhs-1.patch
mkdir -v build
cd       build
echo "rootsbindir=/usr/sbin" > configparms
../configure                             \
      --prefix=/usr                      \
      --host=$(uname -m)-ynjun-linux-gnu                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=$ISDIR/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib
make
make DESTDIR=$ISDIRinstall
sed '/RTLDLIST=/s@/usr@@g' -i $ISDIR/usr/bin/ldd
cd ../..
rm -rf glibc-2.39

# libstdc++
tar -xf gcc-14.1.0.tar.xz
cd gcc-14.1.0
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$(uname -m)-ynjun-linux-gnu                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$(uname -m)-ynjun-linux-gnu/include/c++/14.1.0
make
make DESTDIR=$ISDIRinstall
rm -v $ISDIR/usr/lib/lib{stdc++{,exp,fs},supc++}.la
cd ../..
rm -rf gcc-14.1.0

# m4
tar -xf m4-1.4.19.tar.xz
cd m4-1.4.19.tar.xz
./configure --prefix=/usr \
                  --host=$(uname -m)-ynjun-linux-gnu \
                  --build=$(build-aux/config.guess)
make && make DESTDIR=/mnt/$INSTALL_DIR install
cd ..
rm -rf m4-1.4.19

# ncurses
tar -xf ncurses-6.5.tar.gz
cd ncurses-6.5.tar.gz
sed -i s/mawk// configure
mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$(uname -m)-ynjun-linux-gnu              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping
make
make DESTDIR=$ISDIRTIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $ISDIR/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $ISDIR/usr/include/curses.h
cd ..
rm -rf ncurses-6.5

# bash
cd bash-5.2.21
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$(uname -m)-ynjun-linux-gnu                    \
            --without-bash-malloc              \
            bash_cv_strtold_broken=no
make
make DESTDIR=$ISDIRinstall
ln -sv bash $INSTALL_DIR/bin/sh
cd ..
rm -rf bash-5.2.21

# coreutils
tar -xf coreutils-9.5.tar.xz
cd coreutils-9.5
./configure --prefix=/usr                     \
            --host=$(uname -m)-ynjun-linux-gnu                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make
make DESTDIR=$ISDIRinstall
mv -v $ISDIR/usr/bin/chroot              $ISDIR/usr/sbin
mkdir -pv $ISDIR/usr/share/man/man8
mv -v $ISDIR/usr/share/man/man1/chroot.1 $ISDIR/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $ISDIR/usr/share/man/man8/chroot.8
cd ..
rm -rf coreutils-9.5

# diffutils
tar -xf diffutils-3.10.tar.xz
cd diffutils-3.10
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf diffutils-3.10

# file
tar -xf file-5.45.tar.gz
cd file-5.45
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$(uname -m)-ynjun-linux-gnu --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$ISDIRinstall
rm -v $ISDIR/usr/lib/libmagic.la
cd ..
rm -rf file-5.45

# findutils
tar -xf findutils-4.10.0.tar.xz
cd findutils-4.10.0
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$(uname -m)-ynjun-linux-gnu                 \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf findutils-4.10.0

#gawk
tar -xf gawk-5.3.0.tar.xz
cd gawk-5.3.0
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf gawk-5.3.0

# grep
tar -xf grep-3.11.tar.xz
cd grep-3.11
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf grep-3.11

#gzip
tar -xf gzip-1.13.tar.xz
cd gzip-1.13
./configure --prefix=/usr --host=$(uname -m)-ynjun-linux-gnu
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf gzip-1.13

# make
tar -xf make-4.4.1.tar.gz
cd make-4.4.1
./configure --prefix=/usr   \
            --without-guile \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf make-4.4.1

# patch
tar -xf patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf patch-2.7.6

#sed
tar -xf sed-4.9.tar.xz
cd sed-4.9
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf sed-4.9

# tar
tar -xf tar-1.35.tar.xz
cd tar-1.35
./configure --prefix=/usr   \
            --host=$(uname -m)-ynjun-linux-gnu \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$ISDIRinstall
cd ..
rm -rf tar-1.35

# xz
tar -xf xz-5.6.2.tar.xz
cd xz-5.6.2
./configure --prefix=/usr                     \
            --host=$(uname -m)-ynjun-linux-gnu                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.2
make
make DESTDIR=$ISDIRinstall
rm -v $ISDIR/usr/lib/liblzma.la
cd ..
rm -rf xz-5.6.2

# binutils
tar -xf binutils-2.42.tar.xz
cd binutils-2.42
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$(uname -m)-ynjun-linux-gnu            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make
make DESTDIR=$ISDIRinstall
rm -v $ISDIR/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd ../..
rm -rf binutils-2.42

# gcc
tar -xf gcc-14.1.0.tar.xz
cd gcc-14.1.0
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -v build
cd       build
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$(uname -m)-ynjun-linux-gnu                                \
    --target=$(uname -m)-ynjun-linux-gnu                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$(uname -m)-ynjun-linux-gnu/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$ISDIR                     \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make
make DESTDIR=$ISDIRinstall
ln -sv gcc $ISDIR/usr/bin/cc
cd ../..
rm -rf gcc-14.1.0

# chown
chown --from lfs -R root:root $ISDIR/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $ISDIR/lib64 ;;
esac

# mount syspartition
mkdir -pv $ISDIR/{dev,proc,sys,run}
mount -v --bind /dev $ISDIR/dev
mount -vt devpts devpts -o gid=5,mode=0620 $ISDIR/dev/pts
mount -vt proc proc $ISDIR/proc
mount -vt sysfs sysfs $ISDIR/sys
mount -vt tmpfs tmpfs $ISDIR/run
if [ -h $ISDIR/dev/shm ]; then
  install -v -d -m 1777 $ISDIR$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $ISDIR/dev/shm
fi

# change root
chroot "$ISDIR" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
