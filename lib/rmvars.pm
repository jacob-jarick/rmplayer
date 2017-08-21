package rmvars;

use FindBin qw/$Bin/;
use lib	$Bin;
use lib			"$Bin/lib";

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
$stop_count
$windows
$home
$cmd_file
$version
$media_ext
$web_dir
$scripts_dir
$links_file
$index_html
$queue_form
$select_form
$browse_form
$disable_form
$enable_form

$current_file
$que_file
$lock_file
$ignore_file
$history_file
$info_file
);

our $windows		= 0;
our $home 		= &get_home;
our $stop_count		= 0;

our $media_ext		= "mp3|mp4|mpc|mpg|mpeg|avi|asf|wmf|wmv|ogg|ogm|rm|rmvb|mkv|mov";
our $version		= '5 WIP';

our $web_dir		= $Bin.'/web';
our $scripts_dir	= $Bin.'/scripts';
our $links_file		= $Bin.'/web/links.html';
our $index_html		= $Bin.'/web/index.html';
our $queue_form		= $Bin.'/web/queue_form.html';
our $select_form	= $Bin.'/web/select_form.html';
our $browse_form	= $Bin.'/web/browse_form.html';
our $disable_form	= $Bin.'/web/disable_form.html';
our $enable_form	= $Bin.'/web/enable_form.html';

our $lock_file		= "$home/LOCKFILE.txt";
our $current_file	= "$home/playing.txt";;
our $que_file		= "$home/queue.txt";;
our $cmd_file		= "$home/commands.txt";;
our $ignore_file	= "$home/ignore_list.txt";
our $history_file	= "$home/history.txt";
our $info_file		= "$home/data.json";

sub get_home
{
	my $home = undef;
	$home = $ENV{HOME}		if defined $ENV{HOME} && lc $^O ne lc 'MSWin32';
	$home = $ENV{USERPROFILE}	if lc $^O eq lc 'MSWin32';


	$home = $ENV{TMP}		if ! defined $home; # surely the os has a tmp if nothing else
	$home =~ s/\\/\//g;

	$home .= "/.rmplayer";

	if(!-d $home)
	{
		mkdir($home, 0755) or &main::quit("Cannot mkdir :$home $!\n");
	}
	return $home;
}

1;
