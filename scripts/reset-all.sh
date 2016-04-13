#!/bin/bash

ARCH=amd64
SUITE=jessie
sudo -u wbadm /usr/bin/wanna-build -A $ARCH --dist=$SUITE --list=all > /tmp/package-all.list
awk -vFS=':' ' {split($1,parts,"/");print parts[2]}' /tmp/packages.list > /tmp/package-names-all.list
sed -i '/^\s*$/d' /tmp/package-names-all.list
#        cat /tmp/package-names-all.list -print0 |  xargs -0 sudo -u wbadm /usr/bin/wanna-build -A {{ARCH}} --dist={{SUITE}}
for i in `cat /tmp/package-names-all.list`; do
   sudo -u wbadm /usr/bin/wanna-build -A $ARCH --dist=$SUITE --simulate-dose --override --needs-build $i -v
   done
