#!/bin/bash
set -e

# Ansible transports arguments to modules in a file. The
# path to the arguments file is in $1, and the file
# contains the module's arguments like this:
#
#       name="Name" value=15 dest=/tmp/destfile
#
# This is a little dangerous (!?!), but I'm going to ask
# the current shell to parse that file; it will set
# variables accordingly.

ARCHIVE='local'
SUITE_FOR_PAS="jessie"
SUITES="jessie"
ARCHES="amd64"
MIRROR_SOURCE="http://10.0.2.129/bxbos"
source ${1}   # Very, *very*, dangerous!

cd /srv/wanna-build/triggers
. common

#
# There are two exec command in this script
# the 1st redirect &1 &2 to file
# the last restore it back
#
# Ansible module need json as return value 
# If stdout or stderr output to standard
# json will invalid and moudle will failed
#
exec > $ARCHIVE_BASE/trigger.log 2>&1
echo "`date`: Running trigger for $ARCHIVE ..." 


filter_out_nonfree() {
    local INPUT="$1"
    local OUTPUT="$2"

    gunzip -c "$INPUT" | grep-dctrl -v -r -F Section 'non-free/.*' | gzip -c > "$OUTPUT"
}

main() {
    # When no action specified in trap
    # Default activity is to exit shell
    # here specify cleanup, defined in common
	trap cleanup ERR TERM HUP INT QUIT

	ensure_lock
	ensure_workdir

	for suite in $SUITES
	do
        test -f /srv/buildd.debian.org/web/quinn-diff/${suite}/Packages-arch-specific && rm -f /srv/buildd.debian.org/web/quinn-diff/${suite}/Packages-arch-specific
        wget -P /srv/buildd.debian.org/web/quinn-diff/${suite}/ https://buildd.debian.org/quinn-diff/${SUITE_FOR_PAS}/Packages-arch-specific
    done

	# Fetch the most recent Packages and Sources files.
	for suite in $SUITES
	do
        test -f $ARCHIVE_BASE/archive/$suite/main/source/Sources.gz && rm -f $ARCHIVE_BASE/archive/$suite/main/source/Sources.gz
        wget -P $ARCHIVE_BASE/archive/$suite/main/source/ $MIRROR_SOURCE/dists/$suite/main/source/Sources.gz

		for arch in $ARCHES
		do
            test -f $ARCHIVE_BASE/archive/$suite/main/binary-$arch/Packages.gz && rm -f $ARCHIVE_BASE/archive/$suite/main/binary-$arch/Packages.gz
			wget -P $ARCHIVE_BASE/archive/$suite/main/binary-$arch/ $MIRROR_SOURCE/dists/$suite/main/binary-$arch/Packages.gz
		done
	done

	for suite in $SUITES
	do
		SOURCES="Sources.$suite.incoming-filtered.gz"
		filter_out_nonfree "$ARCHIVE_BASE/archive/$suite/main/source/Sources.gz" "$SOURCES"
		PACKAGES="$ARCHIVE_BASE/archive/$suite/main/binary-%ARCH%/Packages.gz"
		trigger_wb_update "$suite" "$ARCHES" "$SOURCES" "$PACKAGES"
	done

	cleanup
}

    #"log": $(cat $ARCHIVE_BASE/trigger.log)
    #"log": "$(cat $ARCHIVE_BASE/trigger.log | tr "\n" "+" | sed "s/’//g" | sed "s/‘//g")"
    #"log": "Thu May 12 23:43:34 CST 2016: Running trigger for local ...+--"




main

#
# change stdout to json list
# add "" to the beginning and ending in each line
# replace \n to ,\n
# add [] to the b/e of the whole log
# like:
# [
#     "line",
#     "second line"
# ]
#
echo "[" > $ARCHIVE_BASE/trigger.log.list
awk -vRS='\n' -vORS=',\n' '{NF=NF;print "\t""\""$0"\""}' $ARCHIVE_BASE/trigger.log >> $ARCHIVE_BASE/trigger.log.list
echo -e "\t\"done\"\n]" >> $ARCHIVE_BASE/trigger.log.list

exec 1>/dev/tty

if [ $? -eq 0 ]; then
    #echo "{\"changed\":true, \"msg\": \"OK\", \"log\": \"$(cat $ARCHIVE_BASE/trigger.log)\"}"
    #echo "{\"changed\":true, \"msg\": \"OK\"}"
    cat <<EOF 
{
    "changed": true,
    "msg": "OK",
    "stdout": "$(cat $ARCHIVE_BASE/trigger.log | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')",
    "stdout_lines": $(cat $ARCHIVE_BASE/trigger.log.list)

}
EOF
    exit 0
else
    echo "{\"failed\":true, \"msg\": \"some error\"}"
    exit 0;
fi
