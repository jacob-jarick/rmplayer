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
use Term::ReadKey;
use JSON;

use lib			"$Bin/lib";
use rmvars;
use webuiserver;
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
our %dir_stack		= ();
our %info		= ();
our $percent		= 0.90;

our $rand_range		= 1;

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

{
	my $ref = &jhash::load($info_file);
	%info = %$ref if defined $ref;
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
		print	"n",
		"*******************************************************************************\n",
		"* stale lockfile $lock_file removed. *\n",
		"*******************************************************************************\n\n";
		unlink $lock_file;
	}
	else
	{
		print	"\n",
		"*******************************************************************************\n",
		"* lockfile $lock_file exists. EXITING *\n",
		"*******************************************************************************\n\n";

		print	"* bye o/\n";
		exit;
	}
}

# create lock file
&save_file($lock_file, $$);

# =============================================================================

my $first_load = 1;
&reload;

# start webserver

our $server_pid		= 0;
$server_pid		= webuiserver->new(8080)->background();

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

&load_playlist;
&load_dir_stack;
&jhash::save($config::info_file, \%info);
# print Dumper(\%info);

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

	die "ERROR: could not find any files\n" if $file eq '';

	&play($file);
	&history_add($file);
	&check_keyboard($file);
	&check_cmds;
	&jhash::save($config::info_file, \%info) if($play_count % 3 == 0);
	sleep(1);
}
&rmp_exit;

# =============================================================================
# Subs
# =============================================================================

sub rmp_exit
{
	unlink $lock_file;
# 	kill 9, $server_pid;

	&jhash::save($config::info_file, \%info);

	exit;
}

sub get_keyboard
{
	my $key = '';
	my $timeout = time + 0.3;
	ReadMode 4;
	while ($timeout>time && not defined ($key = ReadKey(-1)))
	{
		sleep(0.01);	# No key yet

	}
	ReadMode 0;
	return $key;
}

sub check_keyboard
{
	my $file = shift;
	my $key = &get_keyboard;
	return if ! defined $key || $key eq '';
	if($key eq 'q')
	{
		print "* Got the quit key, quitting :)\n\nThankyou come again.\n\n";
		&rmp_exit;
	}

	# check for files to ignore
	if($key eq 'Q')
	{
		print "* Got the ignore key, ignoring $file.\n\n";
		&update_ignore($file);
	}
}

# ---------------------------
# play file

sub file_parent
{
	my $file = shift;

	for my $k(keys %config::dirs)
	{
		my @tmp = @{ $info{$k}{contents} };
		return $k if &is_in_array($file, \@tmp );
	}
	&quit("file_parent: unable to find parent for '$file'\n");
}

sub history_add
{
	my $file = shift;
	my $parent = &file_parent($file);

	push @{ $info{$parent}{history} }, $file;
	$info{$parent}{history_hash}{$file}	= 1;
	&trim_history($parent);
}

sub play
{
	my $play_file = shift;
	if (! defined $play_file)
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

	my $cmd	= "$config::app{main}{player_cmd} \"$play_file\" > /dev/null 2>&1";
	$cmd	= "$config::app{main}{player_cmd} \"$play_file\" > NUL" if lc $^O eq 'mswin32';

	system($cmd);
}

sub random_select
{
	my $d		= &dir_stack_select;
	my @tmp		= ();
	my $rand	= 0;
	my $play_file	= '';

	for my $f (@{$info{$d}{contents}})
	{
		next if defined $info{$d}{$f};
		push @tmp, $f;
	}

	my @tmp2 = @tmp;
	@tmp = ();

	if (defined $info{$d}{history} && scalar @{$info{$d}{history}} >= $info{$d}{count})
	{
		print "WARNING: unexpected need to trim history for '$d' possible reasons are files have been moved/deleted or rmplayer error.\n";
		&trim_history($d);
	}

	for my $f(@tmp2)
	{
		next if ( defined $info{$d}{history_hash}{$f});
		push @tmp, $f;
	}

	my $list_count = @tmp;
	$rand = int(rand($list_count));
	$play_file = $tmp[$rand] if defined $tmp[$rand];

	if(! defined $play_file || $play_file eq '')
	{
		print "ERROR: random_select: failed to select a file from '$d',  \$play_file is undef, Array count: $list_count, dumping selection array\n";
		print Dumper(\@tmp);
		exit;
	}

	return $play_file;
}
# ------------------------------
# read in que file

sub check_que
{
	return '' if !-f $que_file;

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
	my $mod_time		= (stat($cmd_file))[9];
	$mod_time		= 0 if !defined $mod_time; # for windows
	$last_modtime{$cmd_file}= 0 if ! defined $last_modtime{$cmd_file};

	return if $mod_time == $last_modtime{$cmd_file};

	$last_modtime{$cmd_file} = $mod_time;

	my @tmp		= &readf($cmd_file);

	for my $cmd (@tmp)
	{
		next if $cmd eq '' || $cmd =~ /^(\s|\n|\r)*$/;
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
			&null_file($cmd_file);
			&rmp_exit;
		}
		else
		{
			print "*\n* WARNING: Unknown command found: '$cmd'\n";
		}

	}
	&null_file($cmd_file);	# zero file
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
	   $history_length = scalar(@{$info{$dir}{history}}) if defined $info{$dir}{history};

	my $percent_played = $history_length / $info{$dir}{count};

	if
	(
		$percent_played > $main::percent ||
		$history_length >= ($info{$dir}{count} - 2)		# sometimes a dir has a tiny amount of files (eg 6) resulting in history not being trimmed with 5 out of 6 being played as % played is only ~83%
	)
	{
		# deduct a random percentage between 1-$bump% (stops it trimming constantly)
		my $bump = 5;
		# if dir has small amount of files increase bump size.
		$bump = 10 if $info{$dir}{count} < 100;

		my $c = (1+rand($bump)) / 100;
		my $trim_n = int((1-($percent-$c)) * $info{$dir}{count});	# get amount of files to trim
		$trim_n = 2 if $trim_n <= 1;	# always trim at least 2 files

		print "DEBUG: Trimming History for '$dir', removing $trim_n entrys.\n" if $DEBUG;

		$c = 0;
		while($c <= $trim_n)
		{
			my $f = shift(@{$info{$dir}{history}});	# remove an entry from the front of array
			delete $info{$dir}{history_hash}{$f} if defined $info{$dir}{history_hash}{$f};
			$c++;
		}
	}
}

sub load_playlist
{
	print "LOADING DIRS: ";

	for my $k (keys %config::dirs)
	{
		&quit("load_playlist: \$config::dirs{$k}{path} is undef")			if ! defined $config::dirs{$k}{path};
		&quit("ERROR: dirs.ini invalid path for '$k' - '$config::dirs{$k}{path}'\n")	if !-d $config::dirs{$k}{path};
		print '.';

		my @tmp = @{ $info{$k}{contents} } = &dir_files($config::dirs{$k}{path});

		# remove ignored files
		for my $i(@tmp)
		{
			@{ $info{$k}{contents} } = grep { $_ ne $i } @{ $info{$k}{contents} } if defined $ignore_hash{$i};
		}

		$info{$k}{count} = scalar(@{ $info{$k}{contents} } );

		foreach my $key (keys %{$info{$k}{history_hash}})
		{
			if (! -f $key)
			{
				print "\n* WARNING: $key has been moved or deleted\n";
				delete $info{$k}{history_hash}{$key};
			}
			if (! &is_in_array($key, $info{$k}{history}))
			{
				print "\n* WARNING: $key is in history hash but not in history array. Deleting from history hash\n";
				delete $info{$k}{history_hash}{$key};
			}
		}

		@tmp = ();
		for my $key (@{$info{$k}{history}})
		{
			if(!defined $info{$k}{history_hash}{$key})
			{
				print "\n* WARNING: $key is in history array but not in history hash. Deleting from history array\n";
				next;
			}
			push @tmp, $key;
		}
		@{$info{$k}{history}} = @tmp;

 		&trim_history($k); # trim history on playlist load
	}

	print " done.\n";

	# now cleanup the hash file
	for my $key (keys %info)
	{
		my $found = 0;
		for my $k2(keys %config::dirs)
		{
			if ($key eq $k2)
			{
				$found++;
				last;
			}
		}
		delete $info{$key} if !$found;
	}
}

sub load_ignore_list
{
	my @ignore = &readf_clean($ignore_file);

	for my $f (@ignore)
	{
		print "DEBUG: adding '$f' to ignore hash\n" if $DEBUG;
		$ignore_hash{$f} = 1;
	}
}

sub load_dir_stack
{
	my $c		= 0;
	%dir_stack	= ();

	for my $k(keys %config::dirs)
	{
		next if $config::dirs{$k}{disabled};

		&quit("ERROR load_dir_stack: \$config::dirs{$k}{weight} is undef") if ! defined $config::dirs{$k}{weight};
		&quit("ERROR load_dir_stack: \$info{$k}{count} is undef" . Dumper(\%info) ) if ! defined $info{$k}{count};

		my $nw = $info{$k}{count};

		$nw = int( ($config::dirs{$k}{weight}/100) * $info{$k}{count});
		$c += $nw;
		$dir_stack{$k} = $c;
	}
	$rand_range = $c;
	print "DEBUG: load_dir_stack: highest result for random select is $c\n" if $DEBUG;
}

sub dir_stack_select
{
	my $r = int(rand($rand_range));

	for my $k (sort { $dir_stack{$a} <=> $dir_stack{$b} } keys(%main::dir_stack))
	{
		if($r < $dir_stack{$k})
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

sub quit
{
	my $string = shift;
	cluck $string;
	exit;
}
