# home to all my small misc functions.
package misc;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ci_sort get_home null_file save_file_arr save_file file_append readf readf_clean readsf readsjf is_in_array get_file_info get_file_path get_file_parent_dir get_file_name get_file_ext dir_files);

use strict;
use warnings;
use File::Spec::Functions;
use Cwd qw(realpath);
use File::stat;

sub ci_sort
{
	return sort { lc($a) cmp lc($b) } @_;
}

sub clean_arr
{
	my @arr = @_;

	my @tmp2 = ();
	for(@arr)
	{
		s/^\s+//;
		s/\s+$//;
		push @tmp2, $_ if $_ ne '';
	}
	return @tmp2;
}


#--------------------------------------------------------------------------------------------------------------
# save_file
#--------------------------------------------------------------------------------------------------------------



sub null_file
{
        my $file = shift;

        open(FILE, ">$file") or &main::quit("ERROR: sub null_file, Couldnt open $file to write to. $!");
        close(FILE);
}

sub save_file_arr
{
        my $file	= shift;
        my $ref		= shift;
        my @arr		= @$ref;

	&save_file($file, join("\n", @arr));
}

sub save_file
{
        my $file	= shift;
        my $string	= shift;

        &main::quit("save_file \$file is undef")	if ! defined $file;
        &main::quit("save_file \$string is undef")	if ! defined $string;

        $string =~ s/^\n//g;		# no blank line @ start of file
        $string =~ s/\n\n+/\n/g;	# no blank lines in file

        open(FILE, ">$file") or &main::quit("ERROR: sub save_file, Couldnt open $file to write to. $!");
        print FILE $string;
        close(FILE);
}

sub file_append
{
	my $file	= shift;
	my $string	= shift;

	open(FILE, ">>$file") or &main::quit("ERROR: Couldnt open $file to append to. $!");
        print FILE $string;
        close(FILE);
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf
{
        my $file = shift;

        if(!-f $file)
        {
		print "misc::readf WARNING: file '$file' not found\n";
		return ();
        }

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf_clean
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

	my @tmp;
        for my $l(@file)
        {
		# clean file of empty lines
		$l =~ s/\n+//g;
		$l =~ s/\s*#.*?$//g;

		next if $l eq '';

		push @tmp, $l;
	}
        return sort {lc $a cmp lc $b} @tmp;
}

#--------------------------------------------------------------------------------------------------------------
# read and sort file
#--------------------------------------------------------------------------------------------------------------

sub readsf
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        # clean file of empty lines
        $file = join('', sort @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;
        @file = split(/\n+/, $file);

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read, sort and join file
#--------------------------------------------------------------------------------------------------------------

sub readsjf
{
	my $file = shift;
        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);
        $file = join('', sort @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;

        return $file;
}

#--------------------------------------------------------------------------------------------------------------
# read and join file
#--------------------------------------------------------------------------------------------------------------

sub readjf
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);
        return join('', @file);
}


sub is_in_array
{
	my $string	= shift;
	my $array_ref	= shift;

	return 1 if grep { $_ eq $string} @$array_ref;

	return 0;
}

# my ($d, $f, $p) = get_file_info($file);
sub get_file_info
{
	my $file	= shift;

	&main::quit("get_file_info: \$file is undef") if ! defined $file;
	&main::quit("get_file_info: \$file '$file' is not a dir or file") if !-f $file && !-d $file;

	my $file_path	= &get_file_path($file);
	my $file_name	= &get_file_name($file_path);
	my $file_dir	= &get_file_parent_dir($file_path);

	return ($file_dir, $file_name, $file_path);
}

sub get_file_path
{
	my $file	= shift;

	&main::quit("get_file_path: \$file is undef") if ! defined $file;
	&main::quit("get_file_path: \$file '$file' is not a dir or file") if !-f $file && !-d $file;

	my $file_path	= File::Spec->rel2abs($file);
	$file_path	=~ s/\\/\//g;

	return $file_path;
}

sub get_file_parent_dir
{
	my $file_path	= shift;
	$file_path	= &get_file_path($file_path);
	my @tmp		= split(/\//, $file_path);
	my $file_name	= splice @tmp , $#tmp, 1;
	my $file_dir	= join('/', @tmp);

	return $file_dir;
}

sub get_file_name
{
	my $file_path	= shift;
	$file_path	= &get_file_path($file_path);
	my @tmp		= split(/\//, $file_path);

	return $tmp[$#tmp];
}

sub get_file_ext
{
	my $file_path	= shift;

	return undef if !-f $file_path;

	$file_path	= &get_file_path($file_path);
	my @tmp		= split(/\//, $file_path);
	my $file_name	= splice @tmp , $#tmp, 1;

	if ( $file_name =~ /^(.+)\.(.+?)$/)
	{
		return ($1, $2);
	}
	return undef;
}

# lists files ONLY
sub dir_files
{
	my $dir			= shift;
	my @dir_list		= ();
	my @dirlist_clean	= ();

	&main::quit("ERROR: fn_readdir: dir '$dir' does not exist as a directory.\n") if ! -d $dir;

	opendir(DIR, $dir) or return;
	@dir_list = CORE::readdir(DIR);
	closedir DIR;

	# -- make sure we dont have . and .. in array --
	for my $item(@dir_list)
	{
		next if $item eq "." || $item eq "..";

		next if -d "$dir/$item";
		push @dirlist_clean, "$dir/$item";
	}
	return @dirlist_clean;
}

1;
