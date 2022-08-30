#!/bin/perl -w

#
# USAGE:
#
# ./timedelta.pl < blade1ecxbus1.localdomain/log/rc.log.cur
#

use strict;
use warnings;
use Time::Local;

my $line;
while (<STDIN>) {
	chomp;
	if (/SRVTIME/) {
		$line = $_;

# my $begin = '2009/07/30 11:15:36.180';
# my $end   = '2009/07/30 11:15:37.191';

my $begin = $line;
my $end = $line;

$begin	 =~ s/^([0-9]{4})\/([0-9]{2})\/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]{3}).*$/$1\/$2\/$3 $4:$5:$6\.$7/;
$end	 =~ s/^.*([0-9]{4})\/([0-9]{2})\/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]{3}).*$/$1\/$2\/$3 $4:$5:$6\.$7/;

my ($begin_year, $begin_mon, $begin_mday, $begin_hour, $begin_min, $begin_sec, $begin_msec) =
            $begin =~ /^([0-9]{4})\/([0-9]{2})\/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]{3})$/;
my ($end_year, $end_mon, $end_mday, $end_hour, $end_min, $end_sec, $end_msec) =
            $end   =~ /^([0-9]{4})\/([0-9]{2})\/([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]{3})$/;

my $begin_time = timelocal($begin_sec, $begin_min, $begin_hour, $begin_mday, $begin_mon-1, $begin_year-1900);
my $end_time   = timelocal($end_sec, $end_min, $end_hour, $end_mday, $end_mon-1, $end_year-1900);
my $diff = "$end_time.$end_msec" - "$begin_time.$begin_msec";

printf("   $end - $begin = %.3f\n", $diff);
	}
}
