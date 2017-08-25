#!/usr/bin/perl -w

use warnings;
use strict;

use FindBin qw/$Bin/;

use LWP::Simple qw(getstore);
use LWP::UserAgent;
use Digest::MD5    qw( md5_hex );
use Digest::MD5::File qw( file_md5_hex );
use File::Fetch;
use Archive::Zip;

my $dir		= "$Bin/updates";
my $url		= 'https://raw.githubusercontent.com/jacob-jarick/rmplayer/master/lib/rmvars.pm';
my $file	= &get($url);
my $old_file	= "$Bin/lib/rmvars.pm";

print "\n\nChecking for Updates\n\n";

if(!-d $dir)
{
	print "creating $dir\n";
	mkdir $dir;
}

&check_for_update;

print "\n\nUpdating\n\n";

$url = 'https://github.com/jacob-jarick/rmplayer/archive/master.zip';

my $zip_file = &get($url);

print "\n\nUpacking Update\n\n";

my $zip = Archive::Zip->new($zip_file);

foreach my $member ($zip->members)
{
	next if $member->isDirectory;
	my $filename = $member->fileName;
	$filename =~ s/.*?\///;
	print "extracting $filename\n";
	$member->extractToFileNamed("$Bin/$filename");
}

print "\n\nUpdate Complete\n\n";

exit;

sub get
{
	my $filename = $url;
	$filename =~ m/.*\/(.*)$/;
	$filename = $1;

	my $save = "$dir/$filename";


	my $ua = LWP::UserAgent->new();
	$ua->show_progress(1);

	my $response = $ua->get($url);
	die $response->status_line if !$response->is_success;
	my $file = $response->decoded_content( charset => 'none' );

	unlink $save;
	getstore($url,$save);

	return $save;

}

sub check_for_update
{
	print "Comparing:\n\t$old_file\n\tTO\n\t$file\n";

	return 1 if !-f $old_file;

	open(FILE, $file) or die "$!";
	my @tmp = <FILE>;
	close(FILE);

	open(FILE, $old_file) or die "cant read '$old_file' $!";
	my @tmp2 = <FILE>;
	close(FILE);

	my $different = 0;

	for my $i(0 .. $#tmp2)
	{
	# 	print "checking line $i\n";
		$tmp[$i]	=~ s/\n|\r//g;
		$tmp2[$i]	=~ s/\n|\r//g;

		if($tmp[$i] ne $tmp2[$i])
		{
			$different++;
			last;
		}
	}

	if (!$different)
	{
		print "No update needed\n";
		exit;
	}

}
