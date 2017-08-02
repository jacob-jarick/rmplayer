package rmvars;

use FindBin qw/$Bin/;
use lib	$Bin;
use lib			"$Bin/lib";

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
$version
$home
$media_ext
$web_dir
$scripts_dir
$links_file
$index_html
$limit_file

$config_file

$random_selection_file
$current_file
$que_file
$ignore_file
$cmd_file
$history_file

$play_file
$history_update_file
$wght_file
$player_cmd_file
$dir_file
$play_lock_file
$kill_player_cmd_file

$disable_file

$dh_file
$tmp_dir_file

$windows

$queue_form
$select_form
$browse_form
$disable_form
$enable_form

);

our $windows = 0;

our $home = $ENV{"HOME"};
if($^O eq "MSWin32")
{
	$home = $ENV{"USERPROFILE"};
	$windows = 1;
}

our $version		= '4.0 alpha 27';
our $media_ext		= "mp3|mp4|mpc|mpg|mpeg|avi|asf|wmf|wmv|ogg|ogm|rm|rmvb|mkv|mov";
our $web_dir		= $Bin.'/web';
our $scripts_dir	= $Bin.'/scripts';
our $links_file		= $Bin.'/web/links.html';
our $index_html		= $Bin.'/web/index.html';
our $queue_form		= $Bin.'/web/queue_form.html';
our $select_form	= $Bin.'/web/select_form.html';
our $browse_form	= $Bin.'/web/browse_form.html';
our $disable_form	= $Bin.'/web/disable_form.html';
our $enable_form	= $Bin.'/web/enable_form.html';

our $random_selection_file	= '';
our $current_file		= '';
our $que_file			= '';
our $ignore_file		= '';
our $cmd_file			= '';
our $history_file		= '';
our $disable_file		= '';

our $play_file			= '';
our $history_update_file	= '';
our $wght_file			= '';
our $player_cmd_file		= '';
our $dir_file			= '';
our $play_lock_file		= '';
our $kill_player_cmd_file	= '';

# -----------------------------
# Setup files & directorys

my $profile		= "$home/.rmplayer";

if(defined $ARGV[0] && $ARGV[0] =~ /^--profile=(.*)/)
{
	$profile = $1;
	if (!-d $profile)
	{
		print "* ERROR: '$profile' is not a directory.\n";
		exit;
	}
	$profile =~ s/(\\|\/)$//;
	print "* CONFIG: Using profile directory '$profile'\n";
}

$play_lock_file		= "$profile/lockfile";
$que_file		= "$profile/que.txt";
$limit_file		= "$profile/play_limit.txt";
$cmd_file		= "$profile/cmd.txt";
$history_file		= "$profile/history.txt";
$ignore_file		= "$profile/ignore.txt";
$player_cmd_file	= "$profile/player_cmd.txt";
$kill_player_cmd_file	= "$profile/kill_player_cmd.txt";
$dir_file		= "$profile/dirs.txt";
our $tmp_dir_file	= "$profile/tmp_dirs.txt";
$random_selection_file	= "$profile/random_selection.txt";
$wght_file 		= "$profile/wght.txt";
$current_file		= "$profile/current_file.txt";
$disable_file		= "$profile/disable.txt";

our $config_file	= "$profile/config.txt";

our $dh_file		= "$profile/dont_touch_me.hash";

1;