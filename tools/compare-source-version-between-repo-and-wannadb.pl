#!/usr/bin/perl

use Dpkg::Version; # apt-get install libdpkg-perl

#$v1 = Dpkg::Version->new(‘2:1.0~rc3++svn20100804-0.2squeeze1‘);
#$v2 = Dpkg::Version->new(‘2:1.0~rc3++final.dfsg1-1‘); 
#if ( $v1 > $v2 ) { print “Ver. 1 is Newer\n”; }
#if ( $v1 < $v2 ) { print “Ver. 2 is Newer\n”; } 

#
# Get Sources.gz
#

#my $sources = `wget -O /tmp/Sources.gz  http://mirrors.163.com/debian/dists/jessie/main/source/Sources.gz`;
#system 'gunzip /tmp/Sources.gz';
#print $sources;


open SOURCES , "/tmp/Sources";
my $count = 0;

#
# read in paragraph mode
#
local($/)="";

while (<SOURCES>) {
    $count++;

    my( $_pkg, $_ver, $_arch, $_section);

    $_arch = "-";

    /^Package:\s*(\S+)$/mi and $_pkg = $1;

    /^Version:\s*(\S+)$/mi and $_ver = $1;

    /^Architecture:\s*(\S+)$/mi and $_arch = $1;

    /^Section:\s*(\S+)$/mi and $_section = $1;

    if (!defined $_pkg or !defined $_ver) {
        warn "Invalid stanza :\n$_" ;
        next;
    }

    printf("%-35s %-35s %-35s %-8s\n", $_pkg, $_ver, $_arch, $_section);
}
print "$count\n";
close SOURCES;
