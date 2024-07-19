# Please, run this script as root user!!!
# You have to run this script after make partition, and mount root partition. to $ISDIR
# also, make build user before run this script
# How to make builder user:
# https://www.linuxfromscratch.org/lfs/view/systemd/chapter04/addinguser.html

ISDIR="/mnt/ynjn" # mount root partition here
BUILDERNAME="ynjn"

cd $ISDIR
mkdir -v sources
chmod -v a+wt ./sources
wget https://www.linuxfromscratch.org/lfs/view/systemd/wget-list-systemd
wget --input-file=wget-list-systemd --continue --directory-prefix=./sources
chown root:root ./sources/*
mkdir -pv ./{etc,var} ./usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i ./$i
done

case $(uname -m) in
  x86_64) mkdir -pv ./lib64 ;;
esac
mkdir -pv ./tools
chown -v lfs ./{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac