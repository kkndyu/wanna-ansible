#!/bin/bash

set -e

_dir=$(dirname $0)

_dir=$(readlink -f $_dir)

# make debconf not interact with user
export DEBIAN_FRONTEND="noninteractive"

install_pkgs() {

	apt-get --yes --no-install-recommends --allow-unauthenticated install $@
}


if [ ! -d /srv/wanna-build ]; then

	mkdir -p /srv/wanna-build
	
	if [ -f "$_dir/wanna-build-source.tar.gz" ]; then
	
		echo "extracting wanna-build ..."
		tar xzf $_dir/wanna-build-source.tar.gz -C /srv/wanna-build
		
	else
	
		#
		# download the latest source code
		#
		if ! which git ; then install_pkgs git ; fi
		
		cd /srv
		git clone https://buildd.debian.org/git/wanna-build.git/
	fi
	
	#
	# run as root ...
	#
	ln -s /srv/wanna-build/bin/wanna-build /usr/bin/wanna-build
fi

#
# postgresql-9.1 for Wheezy
#
VER=9.4

#
# first, install PostgreSQL database, if needed
#	
if ! which psql; then
	echo "installing PostgreSQL database ..."
	
	install_pkgs postgresql-$VER postgresql-${VER}-debversion
fi

#
# install other required packages ...
#
if [ ! -f "/usr/lib/perl5/DBI.pm" ]; then

	echo "install required packages ..."
	
	install_pkgs procmail
	install_pkgs dctrl-tools moreutils

	install_pkgs libdpkg-perl

	install_pkgs libdbi-perl libyaml-tiny-perl libhash-merge-perl libstring-format-perl libtimedate-perl

	#
	# for YAML::XS package
	#
	install_pkgs libyaml-libyaml-perl

	#
	# for URI::Escape package
	#
	install_pkgs liburi-perl
 
	install_pkgs libdbd-pg-perl
 
	#
	# edos-debcheck REMOVED; should we install "edos-distcheck" ?
	#
	install_pkgs dose-builddebcheck 
fi

if ! which sendmail ; then
	install_pkgs sendmail
fi

#
# create "wbadm" account
#
if ! grep -e wbadm /etc/passwd; then

	adduser --disabled-password --gecos "" wbadm
	
	#
	# working directory for "wbadm"
	#
	mkdir /srv/wanna-build/tmp
	chmod 750 /srv/wanna-build/tmp
	chown wbadm /srv/wanna-build/tmp
	
	echo wanna-build user "wbadm" created.
fi

PG_CONFIG_FILE=/etc/postgresql/$VER/main/pg_hba.conf

if ! grep -e wbadm $PG_CONFIG_FILE ; then

	cat >> $PG_CONFIG_FILE <<EOF

#
# all local connections to PostgreSQL trusted for the wanna-build user
#
local   all             wbadm                                   trust

EOF

	echo $PG_CONFIG_FILE changed, restarting PostgreSQL ...
	
	/etc/init.d/postgresql restart
fi

PG_SERVICE_FILE=/etc/postgresql-common/pg_service.conf

if [ ! -f $PG_SERVICE_FILE ]; then

	cat > $PG_SERVICE_FILE <<EOF

[wanna-build]
dbname=wannadb
user=wbadm

[wanna-build-privileged]
dbname=wannadb
user=wbadm

EOF

	echo pg_service.conf created, restarting PostgreSQL ...
	
	/etc/init.d/postgresql restart
fi


#
# FOR DEBUG PURPOSE ... drop it if already existed !
#
sudo -u postgres /usr/lib/postgresql/$VER/bin/dropdb wannadb  || : 

init_wanna_db() {

	cat >/tmp/create-wbadm-user.sql <<EOF

CREATE USER wbadm WITH PASSWORD 'celinux2014';
GRANT ALL PRIVILEGES ON DATABASE wannadb TO wbadm;
ALTER USER wbadm CREATEUSER CREATEROLE;

EOF

	sudo -u postgres psql -d wannadb -f /tmp/create-wbadm-user.sql

	sudo -u postgres psql -d wannadb -f /srv/wanna-build/schema/main-tables.sql

	echo "main-tables.sql OK"

	cat >/tmp/roles.sql <<EOF

CREATE ROLE amd64;
ALTER ROLE amd64 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE buildd_amd64;
ALTER ROLE buildd_amd64 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN;

CREATE ROLE mips64el;
ALTER ROLE mips64el WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE buildd_mips64el;
ALTER ROLE buildd_mips64el WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN;

CREATE ROLE ppc64el;
ALTER ROLE ppc64el WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE buildd_ppc64el;
ALTER ROLE buildd_ppc64el WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN;

CREATE ROLE ppc64;
ALTER ROLE ppc64 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE buildd_ppc64;
ALTER ROLE buildd_ppc64 WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN;

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN;

--
-- wb-buildd, wb_all, wb_security, wbadm
--
CREATE ROLE "wb-buildd";
ALTER ROLE "wb-buildd" WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN;

CREATE ROLE wb_all;
ALTER ROLE wb_all WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE wb_security;
ALTER ROLE wb_security WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN;

CREATE ROLE wbadm;
ALTER ROLE wbadm WITH NOSUPERUSER INHERIT CREATEROLE CREATEDB LOGIN;

--
-- privilledges
--
GRANT amd64    TO wb_all GRANTED BY wbadm;
GRANT mips64el TO wb_all GRANTED BY wbadm;
GRANT ppc64el  TO wb_all GRANTED BY wbadm;
GRANT ppc64    TO wb_all GRANTED BY wbadm;

GRANT wb_all TO buildd_amd64 GRANTED BY wbadm;
GRANT wb_all TO buildd_mips64el GRANTED BY wbadm;
GRANT wb_all TO buildd_ppc64el GRANTED BY wbadm;
GRANT wb_all TO buildd_ppc64 GRANTED BY wbadm;

GRANT wb_all TO "wb-buildd" GRANTED BY wbadm;
GRANT wb_all TO wbadm GRANTED BY wbadm;

EOF

	sudo -u postgres psql -d wannadb -f /tmp/roles.sql || :

	echo "roles.sql OK"
	
	ARCHES="amd64 mips64el ppc64el ppc64"

	rm -f /tmp/arches-tables.sql
	for arch in $ARCHES; do sed -e "s/ARCH/$arch/g" < /srv/wanna-build/schema/arches-tables.in >> /tmp/arches-tables.sql ; done

	sudo -u postgres psql -d wannadb -f /tmp/arches-tables.sql 
	
	echo "arches-tables.sql OK"
	
	cat >/tmp/init-db.sql <<EOF
--
-- architectures and distributions to be supported;
--

INSERT INTO distributions(distribution,build_dep_resolver,archive) VALUES ('jessie','',''), ('sid','','');

INSERT INTO architectures(architecture) VALUES ('amd64'), ('mips64el'), ('ppc64el'), ('ppc64');

INSERT INTO distribution_architectures(distribution,architecture) VALUES ('jessie','amd64'), ('jessie','mips64el'), ('jessie','ppc64el'), ('jessie','ppc64');

INSERT INTO locks(distribution,architecture) VALUES ('jessie','amd64'), ('jessie','mips64el'), ('jessie','ppc64el'),('jessie','ppc64');

INSERT INTO distribution_architectures(distribution,architecture) VALUES ('sid','amd64'), ('sid','mips64el'), ('sid','ppc64el'), ('sid','ppc64');

INSERT INTO locks(distribution,architecture) VALUES ('sid','amd64'), ('sid','mips64el'), ('sid','ppc64el'), ('sid','ppc64');

EOF
	
	sudo -u postgres psql -d wannadb -f /tmp/init-db.sql
	
	echo "init-db.sql OK"
}

#
# A better way to check if a specific database exists or not ...
#
# sudo -u postgres /usr/lib/postgresql/9.1/bin/psql -c "SELECT datname FROM pg_database;" | grep wannadb
#
sudo -u postgres /usr/lib/postgresql/$VER/bin/psql -d wannadb -c "SELECT version();" || :

if test $? -ne 2 ; then
	#
	# create wanna-build DB
	#
	sudo -u postgres /usr/lib/postgresql/$VER/bin/createdb wannadb

	echo "initialize wannadb ..."

	init_wanna_db # 2>&1 > /dev/null
fi


