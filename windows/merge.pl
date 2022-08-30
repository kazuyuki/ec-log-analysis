#!/usr/bin/perl -w

if ($#ARGV != 0){
	print("Error : Input root of log directories.\n");
	exit 1;
}

opendir(IN, $ARGV[0]);
@files = readdir(IN) or die ("could not open directory");
closedir(IN);

my $tab="\t";

foreach $dir (sort @files){
	if((-d $dir) && ($dir ne ".") && ($dir ne "..")){
		opendir(IN, "$dir/log") or next;
		my @files2 = readdir(IN) or next;
		foreach $file (sort @files2) {
			#print("[D] $f\n");
			if ($file =~ /userlog/){
				#open(IN2, "nkf -w $dir/log/$file | ") or next;
				open(IN2, "$dir/log/$file") or next;
				print("[D] reading [$dir/log/$file]\n");
				while(<IN2>){
					#  format "date","PID & TID","log level" into "date", "hostname", "log level"
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
my $init = 0;
my $timeprev;
my $timecurr;
foreach $line (sort @lines){
	# print "[D]$line";

	chop $line;
	$year = $month = $mday = $hour = $min = $sec = $line;
	$year	=~ s/^(.{4}).*/$1/;
	$month	=~ s/^.{5}(.{2}).*/$1/;
	$mday	=~ s/^.{8}(.{2}).*/$1/;
	$hour	=~ s/^.{11}(.{2}).*/$1/;
	$min	=~ s/^.{14}(.{2}).*/$1/;
	$sec	=~ s/^.{17}(.{2}).*/$1/;
	$month	-= 1;
	$year	-= 1900;

	eval{ timelocal( $sec, $min, $hour, $mday, $month, $year ); };
	if($@){next;}

	$timecurr = timelocal( $sec, $min, $hour, $mday, $month, $year );

	if(!$init){
		# $timeprev = timelocal( $sec, $min, $hour, $mday, $month, $year );
		$timeprev = timelocal( 0, $min, $hour, $mday, $month, $year );
		$timeprev += 60;
		$init = 1;
	}

	while($timecurr > $timeprev){
		my($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($timeprev);
		# printf("$timeprev : $timecurr : %d/%02d/%02d %02d:%02d:%02d.000\n", $year+1900, $month+1, $mday, $hour, $min, $sec);
		printf("%d/%02d/%02d %02d:%02d:%02d.000\n", $year+1900, $month+1, $mday, $hour, $min, $sec);
		if     ($timecurr - $timeprev > 60*60*24){
			eval{
				$timeprev = timelocal(0, 0, 0, $mday+1, $month, $year);
			};
			if($@){
				$timeprev += 60*60*24;
			}
		} elsif($timecurr - $timeprev > 60*60){
			eval{
				$timeprev = timelocal(0, 0, $hour+1, $mday, $month, $year);
			};
			if($@){
				$timeprev += 60*60;
			}
		} else {
			eval{
				$timeprev = timelocal(0, $min+1, $hour, $mday, $month, $year);
			};
			if($@){
				$timeprev += 60;
			}
		}
	}
	print $line . "\n";
}
