#!/usr/bin/perl -w

use warnings;
use strict;

use FindBin qw/$Bin/;

use LWP::Simple qw(getstore);
use LWP::UserAgent;
use Digest::MD5    qw( md5_hex );
use Digest::MD5::File qw( file_md5_hex );
use File::Fetch;

my $dir = "$Bin/updates";

my $url = 'https://raw.githubusercontent.com/jacob-jarick/rmplayer/master/lib/rmvars.pm';

my $file = &get($url);

my $old_file = "$Bin/libs/rmvars.pm";

print "Comparing:\n\t$old_file\n\tTO\n\t$file\n";

open(FILE, $file) or die "$!";
my @tmp = <FILE>;
close(FILE);
s/\r/\n/ for(@tmp);

open(FILE, $file) or die "$!";
my @tmp2 = <FILE>;
close(FILE);
s/\r/\n/ for(@tmp);

my $different = 0;

if(scalar @tmp == scalar @tmp2)
{
	for my $i(0 .. $#tmp)
	{
		$tmp[$i] =~ s/\n|\r//g;
		$tmp2[$i] =~ s/\n|\r//g;

		if($tmp[$i] ne $tmp2[$i])
		{
			print "line $i does not match, update needed:\n\t$tmp[$i]\n\t$tmp2[$i]\n\n";

			$different++;
			last;
		}
	}
}
else
{
	$different++;
}

if ($different == 0)
{
	print "No update needed\n";
	exit;
}

$url = 'https://github.com/jacob-jarick/rmplayer/archive/master.zip';

&get($url);

exit;

sub get
{
	my $filename = $url;
	$filename =~ m/.*\/(.*)$/;
	$filename = $1;

	print "$filename\n";

	my $ua = LWP::UserAgent->new();
	$ua->show_progress(1);

	my $response = $ua->get($url);
	die $response->status_line if !$response->is_success;
	my $file = $response->decoded_content( charset => 'none' );
	my $md5_hex = md5_hex($file);
	print "$md5_hex\n";
	my $save = "$dir/$filename";
	getstore($url,$save);

	return $save;

}


