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
		my %h = ();
		"load: WARNING '$file' does not exist: $!\n";
		return \%h;
	}

	open(FILE, $file)  or die "save: load error reading '$file' $!\n";
	my @tmp = <FILE>;
	close(FILE);

	my $json_string = join('', @tmp);

	return undef if $json_string =~ /^(\n|\s)*$/;

	my $json = JSON->new->allow_nonref;
	my $perl_hash_or_arrayref  = $json->decode($json_string);

	return $perl_hash_or_arrayref;
}

sub save
{
	my $file	= shift;
	my $perl_scalar	= shift;


	my $json = JSON->new->allow_nonref;
	my $json_text = $json->pretty->encode( $perl_scalar );

	open(FILE, ">$file") or die "save: error saving '$file' $!\n";
	print FILE $json_text;
	close(FILE);
}
















1;
