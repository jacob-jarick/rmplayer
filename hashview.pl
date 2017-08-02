#!/usr/bin/perl -w

use strict;
use warnings;

use Storable;
use Data::Dumper;

my $home = $ENV{"HOME"};
$home = $ENV{"USERPROFILE"} if $^O eq "MSWin32";

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

my $dh_file		= "$profile/dont_touch_me.hash";
my %dh = ();

if( -f $dh_file)
{
	my $ref = retrieve($dh_file);
	%dh = %$ref;
}
else
{
	print "ERROR: $dh_file does not exist.\n";
	exit;
}

if (defined $ARGV[0])
{
	my $dir = $ARGV[0];

	if(defined $dh{$dir})
	{
		print Dumper(\$dh{$dir});
	}
	else
	{
		print "ERROR: '$dir' not found in dir hash\n";
	}
	exit;
}

print Dumper(\%dh);

exit;

