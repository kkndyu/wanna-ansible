Wanna-ansible
=============

Wanna-ansible is a wanna/buildd automation compilation project, using ansible as auto-configuration and batch shell execution.

wanna-ansible
├── ansible.cfg
├── bin                               ansible submodule
├── control-buildd.yml                enable/disable buildd
├── control-wannabuild.yml            reset/query packages state in wannadb
├── hosts                             
├── install-buildd.yml                clean up then install buildd
├── install-wannabuild.yml            clean up then install wannabuild
├── library                           customize ansible modules
├── needs-build                       list file for control-wannabuild.yml
├── README.md
├── roles                             customise ansible roles
├── scripts                           scripts haven't playbooked
├── TODO
├── tools                             tools for convenience
├── uninstall-buildd.yml              uninstall buildd
└── uninstall-wannabuild.yml          uninstall wannabuild

Roles
=====

   * debootstrap generate a chroot image
   * sshcert initialize enviroment for ssh connections using certification, divide into server/client part
   * postgresql install the database
   * buildd depends on sshcert, install buildd
   * wannabuild depends on sshcert postgresql, install wannabuild

Install
=======

1. [Option] Update the chroot image in download server 
ansible-playbook tools/get-chroot-image.yml

2. install buildd
ansible-playbook install-buildd.yml -e HOST=*

3. install wannabuild
ansible-playbook install-wannabuild.yml -e HOST=*

4. reset packages in wannadb
ansible-playbook control-wannabuild.yml -t reset-all,debug -e HOST=* -e STATE=all

5. enable buildd
ansible-playbook control-buildd.yml -t enable-buildd,debug -e HOST=*

Usage
=====

1. clear wannadb, all packages of a suite
ansible-playbook ./control-wannabuild.yml -t clear-wannadb,debug  -e HOST=buildd4* -e SUITE=jessie-proposed-updates

2. [optional]query status of wannadb
ansible-playbook ./control-wannabuild.yml -t query-statistic,debug  -e HOST=buildd4* -e SUITE=jessie-proposed-updates

3. import packages to wannadb
ansible-playbook ./control-wannabuild.yml -t import,debug  -e HOST=buildd4*

4. compare version between repo and wannadb, update new version and set Needs-Build in wannadb
ansible-playbook ./tools/compare-wannadb.yml -e HOST=buildd4*

5. [optional]update chroot tar.gz in buildd machines
ansible-playbook ./control-buildd.yml -t update-chroot,debug -l buildd4*


