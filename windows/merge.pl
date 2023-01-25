#!/usr/bin/perl -w
use strict;
use warnings;

if ($#ARGV != 0){
	print("USAGE : $0 [root of log directories]\n");
	exit 1;
}

opendir(IN, $ARGV[0]) or die ("[E] opendir($ARGV[0]):($!)");
my @files = readdir(IN) or die ("[E] readdir:($!)");
closedir(IN);
chdir $ARGV[0];

my $tab="\t";
my @lines;
foreach my $dir (sort @files){
	if((-d $dir) && ($dir ne ".") && ($dir ne "..")){
		opendir(IN, "$dir/log") or next;
		my @files2 = readdir(IN) or next;
		foreach my $file (sort @files2) {
			if ($file =~ /userlog/){
				#open(IN2, "nkf -w $dir/log/$file | ") or next;
				open(IN2, "$dir/log/$file") or next;
				print("[D] reading [$dir/log/$file]\n");
				while(<IN2>){
					#  format "date", "PID & TID", "log level"
					#  into   "date", "hostname",  "log level"
					s/^(.+? .+? )(.+? .+? )([INFO |WARN |ERROR]+)\s+/$1$dir $3$tab/;
					push @lines, $_;
				}
				close(IN2);
			}
		}
		closedir(IN);
	}else{
		next;
	}
	$tab .= "\t";
}

use Time::Local qw( timelocal );
my $timeprev = 0;
my $timecurr;
foreach my $line (sort @lines){
	# print "[D] $line";
	my ($year,$month,$mday,$hour,$min,$sec) = (0,0,0,0,0,0);
	if ($line =~ m/^(....)\/(..)\/(..) (..):(..):(..).... /) {
		($year,$month,$mday,$hour,$min,$sec) = ($1,$2,$3,$4,$5,$6);
	} else {
		next;
	}
	$month	-= 1;
	$year	-= 1900;

	eval{
		$timecurr = timelocal( $sec, $min, $hour, $mday, $month, $year )
	};
	if($@) {
		print "[E] Exception on eval() ($year/$month/$mday $hour:$min:$sec)";
		exit;
		# next;
	}

	if( $timeprev == 0 ){
		$timeprev = timelocal( 0, ($min + 1) , $hour, $mday, $month, $year );
	}

	while($timecurr > $timeprev){
		my($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($timeprev);
		printf("%d/%02d/%02d %02d:%02d:%02d.000\n", $year+1900, $month+1, $mday, $hour, $min, $sec);
		if ($timecurr - $timeprev > 60*60*24){
			$timeprev += 60*60*24;
		} elsif($timecurr - $timeprev > 60*60){
			$timeprev += 60*60;
		} else {
			$timeprev += 60;
		}
	}
	print $line;
}
