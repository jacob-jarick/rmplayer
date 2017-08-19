package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Config::IniHash;

my %app		= ();
my %dirs	= ();

# set application defaults
$app{main}{play_count_limit}	= 0;
$app{main}{sync_every}		= 1;
$app{main}{debug}		= 0;

my %dir_defaults = ();

$dir_defaults{recursive}	= 0;
$dir_defaults{enabled}		= 1;
$dir_defaults{weight}		= 100;
$dir_defaults{filter}		= '';
$dir_defaults{ignore_filter}	= '';


my $config_file		= "$main::home/config.ini";
my $dirs_file		= "$main::home/dirs.ini";

sub save
{
	WriteINI ($config_file, \%app);
	WriteINI ($dirs_file, \%dirs);
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

	die "dirs file not found" if ! -f $dirs_file;
	my $ini	= ReadINI $dirs_file;
	my %hash	= %{$ini};

	for my $k(keys %hash)
	{
		for my $k2(keys $dir_defaults)
		{
			$dirs{$k}{$k2}	= $dir_defaults{$k2};
			$dirs{$k}{$k2} = $hash{$k}{$k2} if defined $hash{$k}{$k2};
		}
	}

}



1;
