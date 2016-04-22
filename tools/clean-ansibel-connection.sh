#!/bin/bash

set -x

rm /tmp/ansible-*
rm ~/.ansible -rf
rm ~/.ssh/known_hosts
sshpass -p httc ssh root@10.0.2.138 "rm -rf /root/.ansible"
sshpass -p httc ssh root@10.0.2.140 "rm -rf /root/.ansible"
