#!/usr/bin/perl -w

use warnings;
use strict;

use FindBin qw/$Bin/;

use Archive::Zip;

print "\n\nChecking for Updates\n\n";

my $dir		= "$Bin/updates";
my $url		= 'http://raw.githubusercontent.com/jacob-jarick/rmplayer/master/builddate.txt';
my $file	= &get($url);
my $old_file	= "$Bin/builddate.txt";

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

	my $filename	= $url;
	$filename	=~ m/.*\/(.*)$/;
	$filename	= $1;
	my $save	= "$dir/$filename";

	unlink $save;

	# PP does not pack https nicely, so instead, use windows powershell to download the files

	if(lc $^O eq 'mswin32')
	{
		# thanks: https://superuser.com/questions/25538/how-to-download-files-from-command-line-in-windows-like-wget-is-doing

		$save =~ s/\//\\/g;

		my $cmd = "powershell -command \"Invoke-WebRequest -OutFile '$save' '$url'\"";
		print "$cmd\n";
		system($cmd);
		return $save;
	}
	my $cmd = "wget -c -O '$save' '$url'";
	print "$cmd\n";
	system($cmd);
	return $save;
	return $save;
}

sub check_for_update
{
	print "Comparing:\n\t$old_file\n\tTO\n\t$file\n";

	return if !-f $old_file;

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
