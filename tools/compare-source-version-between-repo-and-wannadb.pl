#!/usr/bin/perl
use strict;
use DBI; 
use DBD::Pg; 
use Dpkg::Version; # apt-get install libdpkg-perl

#
# Get Sources.gz
#
unless (-e '/tmp/Sources') {
    `wget -O /tmp/Sources.gz  http://mirrors.163.com/debian/dists/jessie/main/source/Sources.gz`;
    system 'gunzip /tmp/Sources.gz';
}


#
# read in paragraph mode
#
open SOURCES , "/tmp/Sources";
local($/)="";
my %hash;

#
# Get a hash contain packages with the highest version
#
while (<SOURCES>) {

    my( $_pkg, $_ver, $_arch, $_section);

    # /i case-insensitive
    # /m let ^ and $ also match next to embedded \n
    /^Package:\s*(\S+)$/mi and $_pkg = $1;
    /^Version:\s*(\S+)$/mi and $_ver = $1;
    /^Architecture:\s*(\S+)$/mi and $_arch = $1;
    /^Section:\s*(\S+)$/mi and $_section = $1;

    if (!defined $_pkg or !defined $_ver) {
        warn "Invalid stanza :\n$_" ;
        next;
    }

    # package like gcc-4.9 has multi version in Source
    # choose the one with highest version
    if ( exists $hash{$_pkg} ) {
        my $v1 = Dpkg::Version->new($hash{$_pkg});
        my $v2 = Dpkg::Version->new($_ver); 
        if ( $v1 < $v2 ) { 
            #printf("%-35s %-35s %-35s\n", $_pkg, $_ver, $hash{$_pkg});
            $hash{$_pkg} = $_ver; 
        }
    } else {
        $hash{$_pkg} = $_ver;
    }
}

my $dbname='wannadb'; 
my $uname='wbadm'; 
my $pw='celinux2014'; 
my $host='127.0.0.1'; 
my $port="5432";
my $dbh=DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port",$uname,$pw,{AutoCommit => 1}); 

#
# Traverse the hash, compare with wannadb
#
my ($pcount, $count) = (0, 0);
foreach my $key (sort keys %hash) {
    my $sth=$dbh->prepare("select *  from packages where package = \'$key\' and distribution = \'jessie\'"); 
    $sth->execute();

    while (my $row = $sth->fetchrow_hashref) {
        my $v1 = Dpkg::Version->new($hash{$key});
        my $v2 = Dpkg::Version->new($row->{version}); 
        if ( $v1 >  $v2 ) { 
            printf("%-35s %-35s %-35s\n", $key, $row->{version}, $hash{$key});
            $count++;
        }
    }

    $pcount++;
}
print "There are $pcount packages, $count of them need to update\n";
close SOURCES;
$dbh->disconnect();
