#!/usr/bin/perl -w

$| = 1;

use warnings;
use strict;

use Carp qw(cluck longmess shortmess);
use FindBin qw/$Bin/;

use Config::IniHash;

use lib			"$Bin/lib";
use rmvars;
use webuiserver;
use memsubs;

use Data::Dumper::Concise;
use Storable;

use Time::HiRes qw ( time alarm sleep );	# high precision time
use Scalar::Util qw(looks_like_number);

# =============================================================================
# Vars
# =============================================================================

our $home	= '';

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

our $rand_range	= 0;
our @get_sub_dirs_arr = ();

our %dh = ();	# dirs hash
our %dir_stack = ();	# dir stack

our %last_modtime = ();	# used to keep track of modified times on files so we do not thrash the disk to much.


my $print_delay_seconds	= 0.1;

my $help_txt = "Run and access web ui from http://localhost:8080\n";

our @wght_list		= ();
our @wght_value		= ();
our %history_hash	= ();
our %ignore_hash	= ();

our $play_count_limit	= 0;

# FLAGS

our $DEBUG		= 0;
our $SYNC		= 0;



our $sync_every		= 3;
our $kill_cmd		= '';

# Files


# misc

my $file		= '';

my @files		= ();
our @dirs		= ();

my $play_cmd		= '';
my $mode_txt		= '';
my $percent_txt		= '';
my $que			= '';
my $help		= '';
my $questring		= '';

my $file_count		= 0;
our $percent		= 0.90;		# percent of file count to build history up to until trimming occurs

my $last_modtime_cq = 1;

our $play_count_limit_default	= 0;

# =============================================================================
# Main
# =============================================================================

# load config

&config::load;

# =============================================================================
# check for lock file
# =============================================================================

if(-f $play_lock_file)	# check if there is already a lockfile
{
	open(FILE, $play_lock_file) or die "ERROR: couldnt open $play_lock_file to read: $!\n";
	my @tmp = <FILE>;
	close(FILE);
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
		"* stale lockfile $play_lock_file removed. *\n",
		"*******************************************************************************\n\n\n\n\n\n";
		unlink $play_lock_file;
	}
	else
	{
		my $name = $file;
		$name =~ s/^.*\///;

		print	"\n\n\n\n\n",
		"*******************************************************************************\n",
		"* lockfile $play_lock_file exists. EXITING *\n",
		"*******************************************************************************\n\n\n\n\n\n";

		print	"* bye o/\n\n\n";
		sleep(1);
		exit;
	}
}

# create lock file
&file_save($play_lock_file, $$);

# zero some files.

&save_file($limit_file, $main::play_count_limit);

# =============================================================================

# load %dh if file exists.

if( -f $dh_file)
{
	my $ref = retrieve($dh_file);
	%dh = %$ref;
}
else
{
	print "WARNING: '$dh_file' not found\n";
	sleep(2);
}

# cleanup %dh
for my $k (keys %dh)
{
	delete $dh{$k} if !-d $k;			# dir no longer exists
	delete $dh{$k} if $k =~ /(\\\\|\/\/)/;		# cleanup mess I made
}

# read in play command
my @tmp = &readf($player_cmd_file);
$play_cmd = $tmp[0];
chomp $play_cmd;

# read in kill player command
@tmp = &readf($kill_player_cmd_file);
$kill_cmd = $tmp[0];
chomp $kill_cmd;

undef @tmp;

my $first_load = 1;
&reload;

# start webserver

our $server_pid = 0;
$server_pid = webuiserver->new(8080)->background();

# load history
# NOTE history.txt is used for displaying play history in webui
# %dh contains history used by random file selector,

my @history = &readf($history_file);

sleep (0.2);

# Clear screen


if(!$DEBUG)
{
	if($windows)
	{
	#	system("cls");
	}
	else
	{
		system("clear");
	}
}
#
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
* Player cmd:		$play_cmd
* Kill Player cmd:	$kill_cmd
*
**=============================================================**
$ascii
";

# =============================================================================
# Main Loop


my $play_count_limit_tmp = 0;
my $loops_since_refresh = 0;
my $FIRST_STOP = 1;
my $roller_index = 0;
our $STOP = 0;

my $sync_counter = 0;
while(1)
{
	$play_file = '';

	$sync_counter++;
	if ($sync_counter > $sync_every)
	{
		$SYNC = 1;
		$sync_counter = 0;
	}
	else
	{
		$SYNC = 0;
	}

	#&check_quit;
	&check_cmds;

	#----------------------------------------------
	# stop check

	if($STOP)
	{
		if($FIRST_STOP)
		{
			$FIRST_STOP = 0;
			print "* STOPPED. Waiting to Resume ..._,.-'`";
		}
		&do_roller;
		#sleep $print_delay_seconds;
		next;
	}
	$FIRST_STOP = 1;

	#----------------------------------------------
	# check play count limit

	$play_count_limit_tmp++;
	if($main::play_count_limit &&  $main::play_count_limit < $play_count_limit_tmp)
	{
		print "* Hit count limit $main::play_count_limit. stopping playback after next file.\n";
		$main::play_count_limit = 0;
		&save_file($limit_file, '0');
		$STOP = 1;
	}
	if(!$main::play_count_limit)
	{
		$play_count_limit_tmp = 0;
	}

	# --------------------------------------------
	# queue or randomly select play file

	&check_que;

	# manual mode exit check

	$play_file = &random_select if(!$play_file);
	&play;

	if(&check_quit == 2)	# dont update history when going backwards
	{
		next;
	}
	&update_history;
}
&rmp_exit;

# =============================================================================
# Subs
# =============================================================================

sub rmp_exit
{
	unlink $play_lock_file;
# 	print Dumper(\%dh);
	kill 9, $server_pid;

	store \%main::dh, $dh_file;

	exit 0;
}

# ---------------------------
# play file

sub play
{
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

	print "* ";
	print "$questring$name";
	print" \n";
	$questring = '';
	&save_file($current_file, $play_file);
	my $cmd = "$play_cmd \"$play_file\" > /dev/null 2>&1";
	$cmd = "$play_cmd \"$play_file\" > NUL" if $windows;

#	&update_history;
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
	my $mod_time = (stat($que_file))[9];
	$mod_time = 0 if !defined $mod_time; # for windows
	$last_modtime{$que_file} = 0 if ! defined $last_modtime{$que_file};
	return if $mod_time == $last_modtime{$que_file};
	$last_modtime{$que_file} = $mod_time;

	my @tmp = &readf($que_file);
	my $que = "";
	my $a = "";

	while(!$que && @tmp)
	{
		$a = shift @tmp;
		chomp $a;
		if($a)
		{
			$que = $a;
			last;
		}
	}

	if($que)
	{
		# check if its a user qued file
		if(!-f $que)
		{
			print "*\n ERROR!, \"$que\" does not exist\n";
		}
		else
		{
			$play_file = $que;
			$questring = "QUEUED: ";
		}
		&save_file_arr($que_file, \@tmp);
	}
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
			print color 'bold' if !$windows;
			print "*\n* Stopping playback.. ";
			print color 'reset'  if !$windows;
		}

		elsif($cmd =~ /^PLAY/)
		{
			# return play_count_limit to default vaule only when stopped.
			$main::play_count_limit	= $main::play_count_limit_default	if $main::play_count_limit_default	> 0 && $STOP;

			# reset play limit if stopped
			$play_count_limit_tmp	= 0		if $STOP;

			print color 'bold'  if !$windows;
			print "*\n* Resuming playback\n" if $STOP;
			print "*\n* Skipping to next file\n" if !$STOP;
			$STOP = 0;
			print color 'reset'  if !$windows;
		}
		elsif($cmd =~ /^IGNORE\t(.*)$/)
		{
			my $file = $1;
			print color 'bold'  if !$windows;
			print "*\n* WebUI asked me to ignore '$file'\n";
			print color 'reset'  if !$windows;

			&update_ignore($file);
		}
		elsif($cmd =~ /^RELOAD/)
		{
			print color 'bold'  if !$windows;
			print "*\n* $1.\n" if($cmd =~ /^RELOAD\s+(.*)$/);
			print "*\n* Reload requested.\n";
			print color 'reset'  if !$windows;

			&reload;
		}
		elsif($cmd =~ /^EXIT/)
		{
			print color 'bold'  if !$windows;
			print "*\n* Exit requested.\n";
			print color 'reset'  if !$windows;

			$got_exit = 1;
		}
		else
		{
			print color 'bold'  if !$windows;
			print "*\n* WARNING: Unknown command found: '$cmd'\n";
			print color 'reset'  if !$windows;
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


sub update_history
{
	my $file = $play_file;
	my $dir = '';

	$file =~ /^(.+)(\\|\/).+?/;
	$dir = $1;

	if(! defined $main::dh{$dir})
	{
		print "ERROR: update_history: \$main::dh{$dir} not yet defined.\n";
		&rmp_exit;
	}

	# keep history file length to 100
	my $l = scalar(@history);
	if($l > 110)
	{
		my @slice = @history[($l-100) .. $l];	# dont trim to 100 else it updates every cycle
		@history = @slice;
		&file_save($history_file, \@history);
	}

	if(-f $play_file)
	{
		push @history, $play_file;
		push @{$dh{$dir}{'history'}}, $play_file;
		$dh{$dir}{'history_hash'}{$file} = 1;
		&file_append($history_file, $file);
	}
	if($play_file ne '' && defined $play_file && !-f $play_file )
	{
		print "WARNING: update_history play_file '$play_file' is defiend but does not exist.\n";
	}

	&trim_history($dir);
	store \%main::dh, $dh_file;	# trim does not always sync
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

		print color 'bold'  if !$windows;
		print "DEBUG: Trimming History for '$dir', removing $trim_n entrys.\n" if $DEBUG;
		print color 'reset'  if !$windows;

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
	@dirs = &readf($dir_file);
	my $n = 0;

	my @dirs2 = ();
	for my $d (@dirs)
	{
		$n++;
		next if $d =~ /^#/;
		$d =~ s/\#.*//;
		chomp $d;

		if($d =~ /(\\|\/)$/)
		{
			print "WARNING: unncessary trailing slash on $dir_file:$n\n'$d'\n";
			$d =~ s/(\\|\/)$//;
		}

		if ($d =~ /^(.*)(\\|\/)\*$/)
		{
			my $rd = $1;
			push @dirs2, $rd;
			print "* recursive dir '$rd' found\n";
			@get_sub_dirs_arr = ();

			push @dirs2, &get_sub_dirs($rd);
		}
		elsif(-d $d)
		{
			push @dirs2, $d;
		}
		else
		{
			print "WARNING: line $n in $dir_file is invalid:\n'$d'\n";
			next;
		}
	}
	&save_file_arr($tmp_dir_file, \@dirs2);

	my %in_dirs_file = ();

	$|=1;
	print "LOADING DIRS: ";
	for my $d (@dirs2)
	{
		print ".";
		$n++;
		chomp $d;
		$in_dirs_file{$d} = 1; # remember which directories are defined

		@{ $main::dh{$d}{'contents'} } = &dir_files($d);
		my @tmp = @{ $main::dh{$d}{'contents'} };

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

sub load_disabled_list
{
	return if (! -f $disable_file);

	my @dirs = &readf($disable_file);

	for my $d(@dirs)
	{
		if(defined $main::dh{$d})
		{
			$main::dh{$d}{'disabled'} = 1;
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

sub load_play_limit
{
	if (!-f $limit_file)
	{
		$main::play_count_limit = $main::play_count_limit_default;
		return 0;
	}
	my @tmp = &readf($limit_file);

	if(defined $tmp[0] && $tmp[0] =~ /(\d+)/)
	{
		$play_count_limit_tmp = 0;
		$main::play_count_limit = $1;
		&save_file($limit_file, '');
		print "* LIMITING PLAYBACK to $main::play_count_limit files.\n" if  $main::play_count_limit > 0;
	}
	else
	{
		$main::play_count_limit = $main::play_count_limit_default;
	}

}

sub reload
{
	print "* RELOADING PLAYLIST.\n" if $first_load != 1;

	print "* load_ignore_list\n" if $first_load && $DEBUG;
	&load_ignore_list;
	print "* load_playlist\n" if $first_load && $DEBUG;
	&load_playlist;
	print "* load_disabled_list\n" if $first_load && $DEBUG;
	&load_disabled_list;
	print "* load_wght_list\n" if $first_load && $DEBUG;
	&load_wght_list;	# load AFTER playlist so %dh is populated

	print "* load_dir_stack\n" if $first_load && $DEBUG;
	&load_dir_stack;

	print "* load_play_limit\n" if $first_load && $DEBUG;
	&load_play_limit;

	store \%main::dh, $dh_file;

	$first_load = 0;

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
