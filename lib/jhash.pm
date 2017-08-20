package jhash;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use JSON;

sub load
{
	my $file = shift;
	if (!-f $file)
	{
		print "load: WARNING '$file' does not exist: $!\n";
		return undef;
	}
	open(FILE, $file)  or die "save: load error reading '$file' $!\n";
	my @tmp = <FILE>;
	close(FILE);

	my $json_string = join('', @tmp);
	return undef if $json_string =~ /^(\n|\s)*$/;
	my $perl_hash_or_arrayref  = decode_json $json_string;

	return $perl_hash_or_arrayref;
}

sub save
{
	my $file	= shift;
	my $perl_scalar	= shift;

	my $json_text   = encode_json $perl_scalar;

	open(FILE, ">$file") or die "save: error saving '$file' $!\n";
	print FILE $json_text;
	close(FILE);
}
















1;
