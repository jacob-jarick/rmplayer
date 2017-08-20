#!/usr/bin/perl -w

$| = 1;

use warnings;
use strict;

use Carp qw(cluck longmess shortmess);
use FindBin qw/$Bin/;
use Time::HiRes qw ( time alarm sleep );	# high precision time
use Scalar::Util qw(looks_like_number);
use Data::Dumper::Concise;
use Config::IniHash;
use JSON;

use lib			"$Bin/lib";
use rmvars;
# use webuiserver;
use misc;
use config;
use jhash;

# =============================================================================
# Vars
# =============================================================================

our %history_hash	= ();
our %ignore_hash	= ();
our %last_modtime	= ();
our %in_dirs_file	= ();

our $percent		= 0.90;

my $ascii = q{
			          o
			 o       /
			  \     /
			   \   /
			    \ /
		+------------v-------------+
		|  __________________      |
		| /          ,  ooo  \     |
		| |  ---=====|#O#### | (\) |
		| | d        `  \ )  |     |
		| |   ,;`,      | |  | (-) |
		| |  // o ',    | |  |     |
		| \  ' o \ /,   | |  /     |
		|  ------------------      |
		+--------------------------+
		   []                 []

};

my $help_txt = "Run and access web ui from http://localhost:8080\n";

# =============================================================================
# Main
# =============================================================================

# load config

&config::load;

our %dh = ();
{
	my $ref = &jhash::load($info_file);
	%dh = %$ref if defined $ref;
}

# =============================================================================
# check for lock file
# =============================================================================

if(-f $lock_file)	# check if there is already a lockfile
{
	my @tmp = &readf($lock_file);
	my $pid = $tmp[0];
	my $exists = 0;
	if($pid =~ /^(\d+)/)
	{
		$pid = $1;
		$exists = kill 0, $pid;
	}

	if(!$exists)
	{
		print	"\n\n\n\n\n",
		"*******************************************************************************\n",
		"* stale lockfile $lock_file removed. *\n",
		"*******************************************************************************\n\n\n\n\n\n";
		unlink $lock_file;
	}
	else
	{
		print	"\n\n\n\n\n",
		"*******************************************************************************\n",
		"* lockfile $lock_file exists. EXITING *\n",
		"*******************************************************************************\n\n\n\n\n\n";

		print	"* bye o/\n\n\n";
		sleep(1);
		exit;
	}
}

# create lock file
&save_file($lock_file, $$);

# =============================================================================

# load %dh if file exists.

my $first_load = 1;
&reload;

# start webserver

our $server_pid = 0;
# $server_pid = webuiserver->new(8080)->background();

# =============================================================================
# Print start message

print
"
**=============================================================**
*              rmplayer - Written by Jacob Jarick               *
**=============================================================**
*
* Version:		$version
* OS:			$^O
*
* Web UI:		http://localhost:8080/
* Web UI PID:		$server_pid
*
* Daemon PID:		$$
*
* Player cmd:		$config::app{main}{player_cmd}
* Kill Player cmd:	$config::app{main}{kill_cmd}
*
**=============================================================**
$ascii
";

# =============================================================================
# Main Loop

my $play_count			= 0;
my $loops_since_refresh		= 0;
my $FIRST_STOP			= 1;
our $STOP			= 0;

while(1)
{
	#----------------------------------------------
	# stop check

	if($STOP)
	{
		if($FIRST_STOP)
		{
			$FIRST_STOP = 0;
			print "* STOPPED. Waiting to Resume";
		}
		next;
	}
	$FIRST_STOP = 1;

	#----------------------------------------------
	# check play count limit

	$play_count++;
	if($main::play_count_limit &&  $main::play_count_limit < $play_count)
	{
		print "* Hit count limit $main::play_count_limit. stopping playback after next file.\n";
		$main::play_count_limit = 0;
		$STOP = 1;
	}

	# --------------------------------------------
	# queue or randomly select play file

	my $file = '';
	$file = &check_que;
	$file = &random_select if($file eq '');

	&play($file);
}
&rmp_exit;

# =============================================================================
# Subs
# =============================================================================

sub rmp_exit
{
	unlink $lock_file;
# 	print Dumper(\%dh);
	kill 9, $server_pid;

	&jhash::save($dh_file, \%main::dh);

	exit 0;
}

# ---------------------------
# play file

sub play
{
	my $play_file = shift;
	if (! $play_file)
	{
		print "ERROR: play: \$play_file is undef\n";
		&rmp_exit;
	}
	if (! -f $play_file)
	{
		print "ERROR: play: play_file '$play_file' does not exist\n";
		&rmp_exit;
	}

	my $name = $play_file;
	$name =~ s/^.*\///;

	if (! -f $play_file)
	{
		print "\nERROR: play file '$play_file' does not exist\n";
		&rmp_exit;
	}

	print "* $name\n";
	&save_file($current_file, $play_file);
	my $cmd = "$config::app{player_cmd} \"$play_file\" > /dev/null 2>&1";
	$cmd = "$config::app{player_cmd} \"$play_file\" > NUL" if $windows;

	system($cmd);
}

sub random_select
{
	my $d		= &dir_stack_select;
	my @tmp		= ();
	my $rand	= 0;
	my $play_file	= '';

	for my $f (@{$main::dh{$d}{'contents'}})
	{
		next if defined $main::dh{$d}{$f};
		push @tmp, $f;
	}

	my @tmp2 = @tmp;
	@tmp = ();

	if (defined $main::dh{$d}{'history'} && scalar @{$main::dh{$d}{'history'}} >= $main::dh{$d}{'count'})
	{
		print "WARNING: unexpected need to trim history for '$d' possible reasons are files have been moved/deleted or rmplayer error.\n";
		&trim_history($d);
		#exit;
	}

	my $w = 0;
	for my $f(@tmp2)
	{
		if ( defined $dh{$d}{'history_hash'}{$f})
		{
			#print "found '$f' in history, removing\n";
			next;
		}
		#print "Added $f to selection\n";
		push @tmp, $f;
	}

	my $list_count = @tmp;
	$rand = int(rand($list_count));
	$play_file = $tmp[$rand];

	if(!$play_file)
	{
		print "ERROR: random_select: failed to select a file from '$d',  \$play_file is undef, Array count: $list_count, dumping selection array\n";
		print Dumper(\@tmp);
	}


	return $play_file;
}
# ------------------------------
# read in que file

sub check_que
{
	my $play_file			= '';
	my $mod_time			= (stat($que_file))[9];
	$mod_time			= 0 if !defined $mod_time; # for windows
	$last_modtime{$que_file}	= 0 if ! defined $last_modtime{$que_file};

	return '' if $mod_time == $last_modtime{$que_file};

	$last_modtime{$que_file} = $mod_time;

	my @tmp	= &readf($que_file);
	my $que	= '';
	my $a	= '';

	$que = $tmp[0] if defined $tmp[0];

	if($que ne '')
	{
		# check if its a user qued file
		if(!-f $que)
		{
			print "*\n ERROR!, \"$que\" does not exist\n";
		}
		else
		{
			$play_file = $que;
		}
		&save_file_arr($que_file, \@tmp);
	}
	return $play_file;
}

# check for mode adjustments

sub check_cmds
{
	my $mod_time = (stat($cmd_file))[9];
	$mod_time = 0 if !defined $mod_time; # for windows
	$last_modtime{$cmd_file} = 0 if ! defined $last_modtime{$cmd_file};
	return if $mod_time == $last_modtime{$cmd_file};
	$last_modtime{$cmd_file} = $mod_time;

	my @tmp = &readf($cmd_file);
	my $que = "";
	my $a = "";
	my $loop = 1;

	#print "tmp =  @tmp";

	my $got_exit = 0;

	for my $cmd (@tmp)
	{
		chomp $cmd;
		next if !$cmd || $cmd eq '';
		if($cmd =~ /^STOP/)
		{
			$STOP = 1;
			print "*\n* Stopping playback.. ";
		}

		elsif($cmd =~ /^PLAY/)
		{
			# return play_count_limit to default vaule only when stopped.
			$main::play_count_limit	= $main::play_count_limit_default	if $main::play_count_limit_default	> 0 && $STOP;

			# reset play limit if stopped
			$play_count	= 0		if $STOP;

			print "*\n* Resuming playback\n" if $STOP;
			print "*\n* Skipping to next file\n" if !$STOP;
			$STOP = 0;
		}
		elsif($cmd =~ /^IGNORE\t(.*)$/)
		{
			my $file = $1;
			print "*\n* WebUI asked me to ignore '$file'\n";

			&update_ignore($file);
		}
		elsif($cmd =~ /^RELOAD/)
		{
			print "*\n* $1.\n" if($cmd =~ /^RELOAD\s+(.*)$/);
			print "*\n* Reload requested.\n";

			&reload;
		}
		elsif($cmd =~ /^EXIT/)
		{
			print "*\n* Exit requested.\n";

			$got_exit = 1;
		}
		else
		{
			print "*\n* WARNING: Unknown command found: '$cmd'\n";
		}

	}
	&null_file($cmd_file);	# zero file
	&rmp_exit if $got_exit;
}

sub update_ignore
{
	my $file = shift;

	if (!-f $file)
	{
		print "* ERROR: update_ignore '$file' is not a file\n";
		&rmp_exit;
	}

	my $f = $file;
	&file_append($ignore_file, $file);
}



# ---------------------------------------------------
# check to see if we need to trim dirs history

sub trim_history
{
	my $dir = shift;

	my $history_length = 0;
	   $history_length = scalar(@{$dh{$dir}{'history'}}) if defined $dh{$dir}{'history'};

	my $percent_played = $history_length / $dh{$dir}{'count'};

	if
	(
		$percent_played > $main::percent ||
		$history_length >= ($dh{$dir}{'count'} - 2)		# sometimes a dir has a tiny amount of files (eg 6) resulting in history not being trimmed with 5 out of 6 being played as % played is only ~83%
	)
	{
		# deduct a random percentage between 1-$bump% (stops it trimming constantly)
		my $bump = 5;
		# if dir has small amount of files increase bump size.
		$bump = 10 if $dh{$dir}{'count'} < 100;

		my $c = (1+rand($bump)) / 100;
		my $trim_n = int((1-($percent-$c)) * $dh{$dir}{'count'});	# get amount of files to trim
		$trim_n = 2 if $trim_n <= 1;	# always trim at least 2 files

		print "DEBUG: Trimming History for '$dir', removing $trim_n entrys.\n" if $DEBUG;

		$c = 0;
		while($c <= $trim_n)
		{
			my $f = shift(@{$dh{$dir}{'history'}});	# remove an entry from the front of array
			delete $dh{$dir}{'history_hash'}{$f}; #if ! is_in_array($f, $dh{$dir}{'history'});		# delete shifted array value history hash IF it is not still in the array (dupes occur due to user queuing)
			$c++;
		}
	}
	#store \%main::dh, $dh_file;# if $SYNC;
}


sub load_playlist
{
	my @dirs2 = ();
	print "LOADING DIRS: ";

	for my $k (keys %config::dirs)
	{
		my $d = $config::dirs{$k}{path};

		if ($config::dirs{$k}{recursive})
		{
			print "load_playlist: STUB: load recursive\n";
		}
		if(! -d $config::dirs{$k}{path})
		{
			print "WARNING: '$k' path '$config::dirs{$k}{path}' invalid\n";
			next;
		}
		print '.';
		$in_dirs_file{$d} = 1; # remember which directories are defined

		@{ $main::dh{$d}{'contents'} } = &dir_files($d);
		my @tmp = @{ $main::dh{$d}{'contents'} };

		# remove ignored files
		for my $f(@tmp)
		{
			@{ $main::dh{$d}{'contents'} } = grep { $_ ne $f } @{ $main::dh{$d}{'contents'} } if defined $ignore_hash{$f};
		}

		$main::dh{$d}{'count'}		= scalar(@{ $main::dh{$d}{'contents'} } );
		$main::dh{$d}{'disabled'}	= 0;

		  foreach my $key (keys %{$dh{$d}{'history_hash'}})
		 {
		 	if (! -f $key)
		 	{
		 		print "\n* WARNING: $key has been moved or deleted\n";
		 		delete $dh{$d}{'history_hash'}{$key};
		 	}
		 	if (! is_in_array($key, $dh{$d}{'history'}))
		 	{
		 		print "\n* WARNING: $key is in history hash but not in history array. Deleting from history hash\n";
		 		#exit;
		 		delete $dh{$d}{'history_hash'}{$key};
		 		#sleep(1);
		 	}
		 }

		@tmp = ();
		for my $key (@{$dh{$d}{'history'}})
		{
			if(!defined $dh{$d}{'history_hash'}{$key})
			{
				print "\n* WARNING: $key is in history array but not in history hash. Deleting from history array\n";
				next;
			}
			push @tmp, $key;
		}
		@{$dh{$d}{'history'}} = @tmp;

		&trim_history($d); # trim history on playlist load
	}
	print " done.\n";

	# now cleanup the hash file

	for my $d (keys %dh)
	{
		if(! defined $in_dirs_file{$d})
		{
			delete $main::dh{$d};
		}
	}
}

sub load_ignore_list
{
	# load ignore list
	my @ignore = &readf($ignore_file);

	for my $f (@ignore)
	{
		chomp $f;
		next if $f !~ m/\S+/;
		print "DEBUG: adding '$f' to ignore hash\n" if $DEBUG;
		$ignore_hash{$f} = 1;
	}
}

sub load_dir_stack
{
	my $c = 0;
	$main::dir_stack = ();
	for my $k(keys %dh)
	{
		#print "$k - $dh{$k}{'count'}\n";

		if ($main::dh{$k}{'disabled'})
		{
			#print "* Disabling $k\n";
			next;
			#sleep(10);
		}

		my $nw = $dh{$k}{'count'};

		if(defined $main::wght_hash{$k})
		{
			$nw = int($main::wght_hash{$k} * $dh{$k}{'count'});
			#print "reweighting $k to $nw\n";
		}
		$c += $nw;
		$main::dir_stack{$k} = $c;
	}
	$main::rand_range = $c;
	print "DEBUG: load_dir_stack: highest result for random select is $c\n" if $DEBUG;
}

sub dir_stack_select
{
	my $r = int(rand($main::rand_range));

	for my $k (sort { $main::dir_stack{$a} <=> $main::dir_stack{$b} } keys(%main::dir_stack))
	{
		if($r < $main::dir_stack{$k})
		{
			#print "$r Selected $k\n";
			return $k;
		}
	}
}

sub reload
{
	print "reload STUB\n";
}

sub get_sub_dirs
{
	my $dir = shift;
	opendir DIR, $dir or return;
	my @contents = map "$dir/$_", sort grep !/^\.\.?$/, readdir DIR;
	closedir DIR;
	for my $c (@contents)
	{
		next if !(!-l $c && -d $c);
	 	&get_sub_dirs($c);
 		push @main::get_sub_dirs_arr, $c;
	}

	return @main::get_sub_dirs_arr;
}
