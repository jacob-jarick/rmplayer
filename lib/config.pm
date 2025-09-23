package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;
use List::MoreUtils qw(uniq);

use FindBin qw/$Bin/;
use lib		"$Bin";
use lib		"$Bin/lib";

use rmvars;
use misc;

use Config::IniHash;

our %app	= ();
our %dirs	= ();

our $media_extensions_default	= '3gp,avi,flv,m2v,m4v,mkv,mov,mp4,mpeg,mpg,mts,ogv,ts,webm,wmv';

# set application defaults
$app{main}{play_count_limit}	= 0;
$app{main}{sync_every}			= 1;
$app{main}{debug}				= 0;
$app{main}{webserver}			= 1;
$app{main}{kill_cmd}			= '';
$app{main}{player_cmd}			= '';
$app{main}{media_extensions}	= $media_extensions_default;

our %dir_defaults				= ();

$dir_defaults{recursive}		= 0;
$dir_defaults{enabled}			= 1;
$dir_defaults{random}			= 1;
$dir_defaults{weight}			= 100;
$dir_defaults{filter}			= '';
$dir_defaults{ignore_filter}	= '';
$dir_defaults{path}				= '';

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
	$app{main}{webserver}			= 0	if $app{main}{webserver} !~ /^(0|1)$/;
	$app{main}{sync_every}			= 3	if $app{main}{sync_every} !~ /^\d+$/;
	$app{main}{play_count_limit}	= 0	if $app{main}{play_count_limit} !~ /^\d+$/;
	$app{main}{debug}				= 0	if $app{main}{debug} !~ /^(0|1)$/;

	my @tmp		= split(',', $app{main}{media_extensions});
	my @tmp2	= ();
	$media_ext	= '';

	for my $ext(@tmp)
	{
		$ext =~ s/\s+//g;
		push @tmp2, lc $ext;
	}
	$app{main}{media_extensions}	= join(',', sort {lc $a cmp lc $b} uniq @tmp2);
	$media_ext						= join('|', sort {lc $a cmp lc $b} uniq @tmp2);


	if (! -f $dirs_file)
	{
		print "WARNING: no dirs.ini file\n";
		%dirs = ();
		return;
# 		die "dirs file '$dirs_file' not found\n";
	}
	my $ini		= ReadINI $dirs_file;
	my %hash	= %{$ini};

	for my $k(keys %hash)
	{
		for my $k2(keys %dir_defaults)
		{
			$dirs{$k}{$k2} 		= $dir_defaults{$k2} 	if !defined $dirs{$k}{$k2};
			$dirs{$k}{$k2} 		= $hash{$k}{$k2} 		if defined $hash{$k}{$k2};
		}
		$dirs{$k}{weight}		= 100					if $dirs{$k}{weight} !~ /^\d+$/;
		$dirs{$k}{weight}		= 100					if $dirs{$k}{weight} > 100;
		$dirs{$k}{weight}		= 1						if $dirs{$k}{weight} < 1;

		$dirs{$k}{recursive}	= 0						if $dirs{$k}{recursive} !~ /^(0|1)$/;
		$dirs{$k}{random}		= 1						if $dirs{$k}{random} !~ /^(0|1)$/;

		$dirs{$k}{path}			=~ s/\\/\//g;
	}
}

sub load_info
{
	my $ref = &jhash::load($info_file);
	%info = %$ref if defined $ref;
	&config::load_playlist;
	&config::load_dir_stack;
}

sub load_playlist
{
	print "LOADING DIRS: ";
	%parent_hash = ();
	for my $k (keys %dirs)
	{
		&main::quit("load_playlist: \$dirs{$k}{path} is undef") if ! defined $dirs{$k}{path};

		if (!-d $dirs{$k}{path})
		{
			print "WARNING: dirs.ini invalid path for '$k' - '$dirs{$k}{path}'\n";
			delete $dirs{$k};
			next;
		}
		print '.';

		my @tmp = ();

		# setup history hash
		for my $file(@{ $info{$k}{history} })
		{
			if(!-f $file)
			{
				print "\n* WARNING: $file has been moved or deleted\n";
				next;
			}
			push @tmp, $file;
			$history_hash{$file} = 1;
		}
		@{ $info{$k}{history} } = @tmp;

		# load dir contents
		if($dirs{$k}{recursive})
		{
			@tmp = @{ $info{$k}{contents} } = &dir_files_recursive($dirs{$k}{path});
		}
		else
		{
			@tmp = @{ $info{$k}{contents} } = &dir_files($dirs{$k}{path});
		}

		# remove ignored files and record parents
		for my $file(@tmp)
		{
			$parent_hash{$file} = $k;
			@{ $info{$k}{contents} } = grep { $_ ne $file } @{ $info{$k}{contents} } if defined $ignore_hash{$file};
		}

		$info{$k}{count} = scalar(@{ $info{$k}{contents} } );

		print "[$k = $info{$k}{count}]" if $app{main}{debug};

		foreach my $key (keys %history_hash)
		{
			if (! -f $key)
			{
				print "\n* WARNING: $key has been moved or deleted\n";
				delete $history_hash{$key};
			}
		}

		@tmp = ();
		for my $key (@{$info{$k}{history}})
		{
			if(!defined $history_hash{$key})
			{
				print "\n* WARNING: $key is in history array but not in history hash. Deleting from history array\n";
				next;
			}
			push @tmp, $key;
		}
		@{$info{$k}{history}} = @tmp;
 		&trim_history($k); # trim history on playlist load
	}

	print " done.\n";

	# now cleanup the info hash
	for my $key (keys %info)
	{
		# check %info keys against %dirs keys
		my $found = 0;
		for my $k2(keys %dirs)
		{
			if ($key eq $k2)
			{
				$found++;
				last;
			}
		}
		if (!$found)
		{
			delete $info{$key};
			next;
		}

		# ensure %info only has known subkeys
		my @fields = ('history', 'contents', 'count');
		for my $key2 (keys %{$info{$key}})
		{
			delete $info{$key}{$key2} if !&is_in_array($key2, \@fields);
		}
	}
}

sub load_dir_stack
{
	my $index	= 0;
	%dir_stack	= ();
	%weight_hash	= ();

	for my $k(keys %dirs)
	{
		if (!$dirs{$k}{enabled})
		{
			print "DEBUG: ignoring disabled dir '$k'\n";
			next;
		}

		if (! defined $dirs{$k}{weight})
		{
			print "WARNING: load_dir_stack: \$dirs{$k}{weight} is undef\n";
			$dirs{$k}{weight} = 100;
		}

		if (! defined $info{$k}{count})
		{
			print "WARNING: load_dir_stack: \$info{$k}{count} is undef" . Dumper(\%info) . "\n";
			next;
		}

		next if !$info{$k}{count};

		my $w = int( ($dirs{$k}{weight}/100) * $info{$k}{count});
		$weight_hash{$k} = $w;

		$index += $w;
		$dir_stack{$k} = $index;
	}
	$rand_range = $index;
}

# ---------------------------------------------------
# check to see if we need to trim dirs history

sub trim_history
{
	my $dir = shift;
	return if !$info{$dir}{count};

	my $history_length = 0;
	   $history_length = scalar @{$info{$dir}{history}} if defined $info{$dir}{history};

	if(!$dirs{$dir}{random})
	{
		if ($history_length >= $info{$dir}{count})
		{
			for my $file(@{$info{$dir}{history}})
			{
				delete $history_hash{$file};
			}
			@{$info{$dir}{history}} = ();
		}
		&save;
		return;
	}

	my $percent_played = $history_length / $info{$dir}{count};

	if
	(
		$percent_played > $percent ||
		$history_length >= ($info{$dir}{count} - 2)		# sometimes a dir has a tiny amount of files (eg 6) resulting in history not being trimmed with 5 out of 6 being played as % played is only ~83%
	)
	{
		# Trim to 75% of total file count (when we hit 80% threshold)
		# This creates a buffer to prevent trimming every file
		my $target_size = int($info{$dir}{count} * 0.75);
		my $trim_count = $history_length - $target_size;

		# If only 1 file would be trimmed, trim 2 instead for better randomness
		$trim_count = 2 if $trim_count <= 1;			# always trim at least 2 files

		print "DEBUG: Trimming History for '$dir', removing $trim_count entrys (target: 75% = $target_size files).\n" if $app{main}{debug};

		for my $c (0 .. $trim_count-1)
		{
			my $f = shift(@{$info{$dir}{history}});	# remove an entry from the front of array
			delete $history_hash{$f} if defined $history_hash{$f};
		}
	}
}


1;
