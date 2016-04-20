#!/bin/bash

set -x

rm /tmp/ansible-*
rm ~/.ansible -rf
rm ~/.ssh/known_hosts
sshpass -p httc ssh root@10.0.2.137 "rm -rf /root/.ansible"
