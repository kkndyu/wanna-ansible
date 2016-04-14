#!/bin/bash

ARCH=amd64
SUITE=jessie

# use pipe to avoid redirect I/O
sudo -u wbadm /usr/bin/wanna-build -A $ARCH --dist=$SUITE --list=all |
awk  ' {split($1,parts,"/");if(parts[2]!="") print parts[2]}' |
sed  's/:$//g' | # get package name and remove empty line
while read line; do
    sudo -u wbadm /usr/bin/wanna-build -A $ARCH --dist=$SUITE --simulate-dose --override --needs-build $line -v
done
