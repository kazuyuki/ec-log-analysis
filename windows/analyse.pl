#!/usr/bin/perl -w

#
# Usage:
#
#	
#	./analyse.pl [TimeDelta] [Log directry] [filename]
#	./analyse.pl 0 . userlog
#
#	filename	log ディレクトリ直下のファイル名にマッチする文字列を指定する

use Cwd;
use Time::Local 'timelocal';

my ($sec, $min, $hour, $mday, $month, $year, $wday, $stime);
my @dirs = ();
my %lines = ();
my $msg;

if ($#ARGV < 2){
	print("Usaage : $0 [delta_T] [log directories root] [filename]\n");
	exit 1;
}

my $cwd = Cwd::getcwd();
opendir(IN, $cwd."/".$ARGV[1]);
@files = readdir(IN) or die ("Error : Could not open directory");
closedir(IN);

# Node2 - Node1 = timedelta:
my $timedelta = $ARGV[0];
my $timeadjust = 0;
my $tab="\t";

foreach $dir (sort @files){
	if (( -d $dir ) && ($dir ne ".") && ($dir ne "..")){
		opendir(IN, "$dir/log") or next;
		my @files2 = readdir(IN) or next;
		push @dirs, $dir;
		foreach $file (sort @files2) {
			if($file =~ /^$ARGV[2]/){
				open(IN2, "$dir/log/$file");
				# push @dirs, $dir;
				printf("[D] $dir/log/$file\n");
				while(<IN2>){
					next if (!/^\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d\.\d\d\d/);
					chop;
					# s/($&)(.*)/$1 $2/;
					@tmp = split(/[\s,]/);
					$mdate	= shift(@tmp);
					$mtime	= shift(@tmp);
					$msg	= join(' ', @tmp);

##----------
##
## Reform
##
#
# こんなのを
# 2021/07/21 09:32:56.673[17272] 2021/07/21 09:32:56 [I] [UCEserver] at [192.168.72.4]: Powered on done. (0)
#
# こうする
# 2021/07/21 09:32:56.673[I] [UCEserver] at [192.168.72.4]: Powered on done. (0)
#
#					$msg =~ s/^\[\d+\] \d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d //;
#----------

					# userlogNN.log から PID TID を消す
					$msg =~ s/ [0-9a-f]{8} [0-9a-f]{8} //;

					# 無駄なメッセージを行ごと消す
					next if ($msg =~ /Cluster Disk Resource Performance Data can't be collected because a performance monitor is too numerous./);

##----------
##
## Cut
##
#
# こんなのを消す
# 2021/07/21 10:11:30.673[10457]   vmid=\$(vim-cmd vmsvc/getallvms 2>&1 | grep 'UCEserver/UCEserver.vmx' | awk '{print \$1}')
#
#					next if($msg =~ /^\[\d+\] [^\[]/);
#					next if($msg =~ /^\[\d+\]/);
#----------

					$year = $month = $mday = $hour = $min = $sec = $msec = "$mdate $mtime";
					$year	=~ s/^(....)\/..\/.. ..:..:....../$1/;
					$month	=~ s/^....\/(..)\/.. ..:..:....../$1/;
					$mday	=~ s/^....\/..\/(..) ..:..:....../$1/;
					$hour	=~ s/^....\/..\/.. (..):..:....../$1/;
					$min 	=~ s/^....\/..\/.. ..:(..):....../$1/;
					$sec 	=~ s/^....\/..\/.. ..:..:(..)..../$1/;
					$msec	=~ s/^....\/..\/.. ..:..:...(...)/$1/;
					$month	-= 1;
					# $year	+= 100;
					$epoch = timelocal($sec, $min, $hour, $mday, $month, $year);
					$epoch -= $timeadjust;
					$line = sprintf("$epoch $dir$tab$msg\n");
					push @{$lines{$dir}}, $line;
				}
				close(IN2);
			}
		}
		$tab .= "\t";
		$timeadjust += $timedelta;
		closedir(IN);
	}
}

# foreach (@dirs){ print "[[D]] $_\n" }; exit;

my $t1 = 0;	# time for node1
my $t2 = 0;	# time for node2
my $timecurr = 0;
my $timeprev = 0;
while(1){
	my $line = "";
	if ((scalar(@{$lines{$dirs[0]}}) == 0) &&
	    (scalar(@{$lines{$dirs[1]}}) == 0)) {
		last;
	}
	elsif (scalar(@{$lines{$dirs[0]}}) == 0) {
		$line = shift @{$lines{$dirs[1]}};
	}
	elsif (scalar(@{$lines{$dirs[1]}}) == 0) {
		$line = shift @{$lines{$dirs[0]}};
	} else {
		$t1 = $lines{$dirs[0]}[0];
		$t2 = $lines{$dirs[1]}[0];
		$t1 =~ s/^(\d*).*/$1/;
		$t2 =~ s/^(\d*).*/$1/;
		if ( $t1 < $t2 ) {
			$line = shift @{$lines{$dirs[0]}};
		} else {
			$line = shift @{$lines{$dirs[1]}};
		}
	}

	$timecurr = $line;
	$timecurr =~ s/^(\d+) (.*)/$1/;
	if($timeprev == 0){
		$timeprev = $timecurr;
	}
	my $msg = $2;

	while($timecurr > $timeprev){
		my($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($timeprev);
		if ($timecurr - $timeprev > 60*60*24){
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
		} elsif($timecurr - $timeprev > 60){
			eval{
				$timeprev = timelocal(0, $min+1, $hour, $mday, $month, $year);
			};
			if($@){
				$timeprev += 60;
			}
		} else {
			last;
		}
		($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($timeprev);
		printf("%d/%02d/%02d %02d:%02d:%02d.000\n", $year+1900, $month+1, $mday, $hour, $min, $sec);
	}
	$timeprev = $timecurr;
	($sec, $min, $hour, $mday, $month, $year, $wday, $stime) = localtime($timecurr);
	my $date = sprintf("%d/%02d/%02d %02d:%02d:%02d.%03d", $year+1900, $month+1, $mday, $hour, $min, $sec, $msec);
	print "$date $msg\n";
}
