package memsubs;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(file_ow file_ows file_append fn_readdir readf readjf is_in_array);  # symbols to export on request

sub file_ow
{
	my $file = shift;
	my $r = shift;
	my $no_blanks = shift;
	my @tmp = @{$r};

	#print "file_ow array:\n" . Dumper( @tmp );

	my @tmp2 = ();
	if(defined $no_blanks)
	{
		for(@tmp)
		{
			s/^\s+//;
			s/\s+$//;
			push @tmp2, $_ if $_ ne '';
		}
	}
	
	open(FILE, ">$file") or die "ERROR: Couldnt open $file to overwrite. $!";
	for(@tmp)
	{
		next if !$_;	# avoid nulls
        	print FILE "$_\n";
	}
        close(FILE);
}

sub file_ows
{
	my $file = shift;
	my $s = shift;

	open(FILE, ">$file") or die "ERROR: Couldnt open $file to overwrite. $!";
       	print FILE "$s\n";
        close(FILE);
}

sub file_append
{
	my $file = shift;
	my $string = shift;

# 	if (! defined $string)
# 	{
# 		print "* WARNING: file_append: tried to write undef string to '$file'.\n";
# 		return;
# 	}

	chomp $string;

	open(FILE, ">>$file") or die "ERROR: Couldnt open $file to append to. $!";
        print FILE "$string\n";
        close(FILE);
}

sub fn_readdir
{
	my $dir = shift;
	my @dir_list = ();
	my @dirlist_clean = ();
	my @d = ();

	chomp $dir;

	if(! -d $dir)
	{
		print "ERROR: fn_readdir: dir '$dir' does not exist as a directory.\n";
		&rmp_exit;
	}

	opendir(DIR, "$dir") or return;
	@dir_list = CORE::readdir(DIR);
	closedir DIR;

	# -- make sure we dont have . and .. in array --
	for my $item(@dir_list)
	{
		if($item eq "." || $item eq "..")
		{
			next;
		}
		if(-d "$dir/$item")
		{
			next;
		}
		if($item !~ /\.($main::media_ext)$/i)
		{
			next;
		}
		if($dir =~ m/(\\|\/)$/ )
		{
			push @dirlist_clean, "$dir$item";
		}
		else
		{
			push @dirlist_clean, "$dir/$item";
		}
	}
	return @dirlist_clean;
}

sub readf
{
        my $file = shift;

        if (! defined $file)
        {
        	print "ERROR: readf: \$fileis undef\n";
        	return ();
        }


        if (!-f $file)
        {
        	print "ERROR: readf: '$file' does not exist\n";
        	return ();
        }

        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
        my @tmp = <FILE>;
        close(FILE);

        return @tmp;
}

sub readjf
{
        my $file = shift;

        if(!-f $file)
        {
        	print "ERROR: readjf: file not found '$file'\n";
        	return;
        }

        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
        my @tmp = <FILE>;
        close(FILE);

        return join('', @tmp);
}

sub is_in_array
{
	my $string = shift;
	my $r = shift;
	#my @tmp = @$r;

	#print "string = '$string' \n";

	return 1 if grep { $_ eq $string} @$r;

	return 0;
}

1;