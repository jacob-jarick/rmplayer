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
		die "load: warning '$file' does not exist\n";
		return ();
	}
	my $json_string = &readjf($file);
	return () if $json_string =~ /^(\n|\s)*$/;
	my $perl_hash_or_arrayref  = decode_json $json_string;

	return $perl_hash_or_arrayref;
}

sub save
{
	my $file	= shift;
	my $perl_scalar	= shift;

	my $json_text   = $json->encode( $perl_scalar );
	&file_save($file, $json_text);
}
















1;
