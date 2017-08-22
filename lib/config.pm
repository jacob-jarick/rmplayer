package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib			$Bin;
use lib			"$Bin/lib";

use rmvars;

use Config::IniHash;

our %app			= ();
our %dirs			= ();

# set application defaults
$app{main}{play_count_limit}	= 0;
$app{main}{sync_every}		= 1;
$app{main}{debug}		= 0;
$app{main}{kill_cmd}		= '';
$app{main}{player_cmd}		= '';

our %dir_defaults		= ();

$dir_defaults{path}		= '';
$dir_defaults{recursive}	= 0;
$dir_defaults{enabled}		= 1;
$dir_defaults{weight}		= 100;
$dir_defaults{filter}		= '';
$dir_defaults{ignore_filter}	= '';



sub save
{
	WriteINI ($config_file,	\%app);
	WriteINI ($dirs_file,	\%dirs);
}

sub load
{
	# load config.ini
	if(-f $config_file)
	{
		my $ini	= ReadINI $config_file;
		my %hash	= %{$ini};

		for my $k(keys %app)
		{
			for my $k2(keys %{$app{$k}})
			{
				$app{$k}{$k2} = $hash{$k}{$k2} if defined $hash{$k}{$k2};
			}
		}
	}
	else
	{
		print "creating '$config_file'\n";
		WriteINI ($config_file, \%app);
	}

	if (! -f $dirs_file)
	{
		print "ERROR: no dirs.ini file, please create before proceeding\n";
		die "dirs file '$dirs_file' not found\n";
	}
	my $ini	= ReadINI $dirs_file;
	my %hash	= %{$ini};

	for my $k(keys %hash)
	{
		for my $k2(keys %dir_defaults)
		{
			$dirs{$k}{$k2} = $dir_defaults{$k2};
			$dirs{$k}{$k2} = $hash{$k}{$k2} if defined $hash{$k}{$k2};
		}
		$dirs{$k}{weight} = 100	if $dirs{$k}{weight} !~ /^\d+$/;
		$dirs{$k}{weight} = 100	if $dirs{$k}{weight} > 100;
		$dirs{$k}{weight} = 1	if $dirs{$k}{weight} < 1;
	}
}



1;
