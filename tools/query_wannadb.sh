#!/bin/bash

set -x

#sudo -u buildd ssh wbadm@10.0.2.107 wanna-build --dist=jessie -A amd64 --list=$1
sudo -u buildd ssh wbadm@10.0.2.107 /srv/wanna-build/bin/wanna-build-statistics --dist=jessie --database=amd64
