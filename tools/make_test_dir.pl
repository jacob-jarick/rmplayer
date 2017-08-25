#!/usr/bin/perl

# makes test directories

use strict;
use warnings;
use File::Touch;
use Data::Dumper::Concise;
use Data::Random qw(:all);

if(! -d $ARGV[0])
{
	die "error need to provide a target directory. $!\n";
}

my $dir = $ARGV[0];

my @vid_filetypes = ('mpg','mpeg','avi','mkv');
my @pic_filetypes = ('jpeg','jpg','gif','bmp','png');
my @music_filetypes = ('mp3', 'ogg', 'flac');

my @bands = ('acdc', 'Blur', 'ZZ Top', 'NIN', 'Queen');

my %mime = ();

$mime{mp3}	= 'audio/mpeg';
$mime{ogg}	= 'audio/ogg';
$mime{flac}	= 'audio/flac';
$mime{mpeg}	= 'video/mpeg';
$mime{mpg}	= 'video/mpeg';
$mime{avi}	= 'video/x-msvideo';
$mime{mkv}	= 'video/x-matroska';

$mime{jpeg}	= 'image/jpeg';
$mime{jpg}	= 'image/jpeg';
$mime{gif}	= 'image/gif';
$mime{bmp}	= 'image/bmp';
$mime{png}	= 'image/png';

for my $count (0 .. 5)
{
	my $movies = "$dir/Movies_$count";
	$movies =~ s/\\/\//g;
	mkdir $movies;

	for(0.. int(rand(50)+1))
	{
		my $year	= &get_year;
		my $r		= int (rand(3)+1);
		my $title	= join(" ", rand_words( size => $r ));
		my $ext		= $vid_filetypes[int(rand($#vid_filetypes))];
		my $filename	= "$movies/$title - $year.$ext";

		if(rand(1) > 0.2)
		{
			$filename = "$movies/$title - ($year).$ext";
		}
		if(rand(1) > 0.2)
		{
			$filename = "$movies/$title [$year].$ext";
		}

		if(rand(1) > 0.5)
		{
			$filename = uc $filename;
		}
		if(rand(1) > 0.3)
		{
			$filename =~ s/\s+/_/g;
		}
		if(rand(1) > 0.3)
		{
			$filename =~ s/\s+/./g;
		}

		print "$filename\n";
		touch $filename;
		&set_mime($filename, $ext);
	}
}

exit;

sub get_year
{
	my $year = int(rand(75) +  1949);
	return $year;
}

sub set_mime
{
	my $file = shift;
	my $ext = shift;

	if(defined $mime{$ext})
	{
		open(FILE, ">$file");
		print FILE $mime{$ext};
		close (FILE);
	}
}
