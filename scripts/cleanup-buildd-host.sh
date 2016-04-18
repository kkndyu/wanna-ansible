#!/bin/sh

set -e

#
# if buildd or sbuild is running ...
#
# if echo `ps -ef` | grep -e buildd ; then

OUTPUT=`ps -ef`

if echo "$OUTPUT" | grep -q -e buildd >/dev/null ; then
	echo "buildd is still running ... exit"
	# exit 1
fi

echo " -----------------------------------------"

#
# keep it from starting again ...
#
rm -f /etc/cron.d/buildd

kill -HUP `cat /run/crond.pid`

#
# FIXME: umount schroot mount points
#

if cat /proc/mounts | grep -e /var/lib/schroot/mount ; then

	#
	# try to terminate them 
	#
	schroot --end-session --all-sessions
	
	if cat /proc/mounts | grep -e /var/lib/schroot/mount ; then
		echo "some schroot sessions are still active ... exit"
		exit 1
	fi
fi


#
# and finally, see if we can umount buildd volume ; stop immediately if fails
#
test -d /buildd_vol && umount /buildd_vol 

#
# un-install buildd & sbuild
#
apt-get -y purge buildd sbuild libsbuild-perl schroot

apt-get -y autoremove

userdel buildd
userdel sbuild

#
# remove buildd data completely
#
rm -fr /var/lib/buildd

rm -fr /var/lib/schroot
rm -fr /etc/schroot




