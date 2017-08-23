#!/usr/bin/perl -w

$| = 1;

use warnings;
use strict;

use Carp qw(cluck longmess shortmess);

use Time::HiRes qw ( time alarm sleep );	# high precision time
use Scalar::Util qw(looks_like_number);
use Data::Dumper::Concise;
use Config::IniHash;
use Term::ReadKey;
use JSON;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use rmvars;
use webuiserver;
use misc;
use config;
use jhash;

use threads ('yield', 'stack_size' => 64*4096, 'exit' => 'threads_only', 'stringify');
use threads::shared;

# =============================================================================
# Vars
# =============================================================================


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

&save_file($lock_file, $$);

# =============================================================================

&config::load;
&config::load_info;
# start webserver

our $server_pid :shared;
$server_pid = 0;
my $thr;
if($config::app{main}{webserver})
{
# 	$server_pid = webuiserver->new(8080)->background();
	$thr = threads->create('start_thread');
	$thr->detach();
}

sub start_thread
{
	$server_pid = webuiserver->new(8080)->run();

}

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
	&check_cmds;
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
	if($stop_count && $stop_count < $play_count)
	{
		print "* Hit play limit $stop_count. stopping playback after next file.\n";
		$stop_count = 0;
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
	&jhash::save($config::info_file, \%info) if($play_count % $config::app{main}{sync_every} == 0);
 	sleep(1);
}
&rmp_exit;

# =============================================================================
# Subs
# =============================================================================

sub rmp_exit
{
	unlink $lock_file;
 	kill 9, $server_pid;

	&jhash::save($config::info_file, \%info);

	exit;
}

sub get_keyboard
{
	my $key = '';
	my $timeout = time + 0.3;
# 	ReadMode 4;
	ReadMode 0;
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

sub history_add
{
	my $file	= shift;
	&quit("ERROR history_add: \$parent_hash{$file} is undef\n" . Dumper(\%parent_hash)) if ! defined $parent_hash{$file};
	my $parent	= $parent_hash{$file};

	push @{ $info{$parent}{history} }, $file;
	$history_hash{$file} = 1;
	&trim_history($parent);
	&file_append($history_file, "$file\n");
	&misc::trim_log($history_file, 10);
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

	if (lc $^O eq 'mswin32')
	{
		$play_file =~ s/\//\\/g;	# some windows apps do not like / in paths
		$cmd = "cmd /c \"$config::app{main}{player_cmd} \"$play_file\"\" > NUL" ;
	}

# 	print "CMD = $cmd\n"  if $config::app{main}{debug};
	system($cmd);
}

sub random_select
{
	my $dir		= &dir_stack_select;
	my @tmp		= ();
	my $play_file	= '';

	for my $file (@{$info{$dir}{contents}})
	{
		next if defined $info{$dir}{$file};
		push @tmp, $file;
	}

	if (defined $info{$dir}{history} && scalar @{$info{$dir}{history}} >= $info{$dir}{count})
	{
		print "WARNING: unexpected need to trim history for '$dir' possible reasons are files have been moved/deleted or rmplayer error.\n";
		&trim_history($dir);
	}

	my @tmp2 = @tmp;
	@tmp = ();

	for my $file(@tmp2)
	{
		next if ( defined $history_hash{$file});
		push @tmp, $file;
	}

	my $list_count = scalar @tmp;
	my $rand = int(rand($list_count));
	$play_file = $tmp[$rand] if defined $tmp[$rand];

	if($play_file eq '')
	{
		&quit("ERROR: random_select: failed to select a file from '$dir',  \$play_file is undef, Array count: $list_count, dumping selection array\n" . Dumper(\@tmp));
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

	my @tmp		= &readf($que_file);
	$play_file	= $tmp[0]		if defined $tmp[0];

	return '' if $play_file eq '';

	shift @tmp;
 	&save_file_arr($que_file, \@tmp);

 	print "* QUEUED: '$play_file'\n";

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

	for my $cmd (&readf($cmd_file))
	{
		next if $cmd eq '' || $cmd =~ /^(\s|\n|\r)*$/;
		if($cmd =~ /^STOP/)
		{
			$STOP = 1;
			print "*\n* Stopping playback.. \n";
		}

		elsif($cmd =~ /^PLAY/)
		{
			$stop_count = $play_count = 0;

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
		elsif($cmd =~ /^DISABLE\t+(.*)/)
		{
			my $key = $1;
			print "* DISABLE $key\n";

			$config::dirs{$key}{enabled} = 0;
			&reload;
		}
		elsif($cmd =~ /^ENABLE\t+(.*)/)
		{
			my $key = $1;
			print "* DISABLE $key\n";

			$config::dirs{$key}{enabled} = 1;
			&reload;
		}
		elsif($cmd =~ /^LIMIT=(\d+)/)
		{
			$stop_count = $1;
			$play_count = 0;
			print "* INFO: Playback will stop after $stop_count files\n";
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

sub load_ignore_list
{
	my @ignore = &readf_clean($ignore_file);

	for my $file (@ignore)
	{
		print "DEBUG: adding '$file' to ignore hash\n" if $config::app{main}{debug};
		$ignore_hash{$file} = 1;
	}
}

sub update_ignore
{
	my $file = shift;

	if (!-f $file)
	{
		print "* ERROR: update_ignore '$file' is not a file\n";
		&rmp_exit;
	}
	$ignore_hash{$file} = 1;
	&file_append($ignore_file, $file);
}


sub dir_stack_select
{
	my $r = int(rand($rand_range));

	for my $k (sort { $dir_stack{$a} <=> $dir_stack{$b} } keys %dir_stack)
	{
		return $k if $r < $dir_stack{$k};
	}
}

sub reload
{
	&config::save;
	&config::load_playlist;
	&config::load_dir_stack;
}

sub quit
{
	my $string = shift;
	cluck $string;
	kill 9, $server_pid;
	exit;
}
