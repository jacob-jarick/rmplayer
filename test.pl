#!/usr/bin/perl
use strict;
use warnings;

use Tk;
use Tk::Chart::Pie;
my $mw = MainWindow->new( -title => 'Tk::Chart::Pie example', );

my $chart = $mw->Pie
(
	-title=> 'Weighted Playlist' . "\n",

	-linewidth => 3,
	-background=> '#bababa',
	-titlefont=> '{Arial} 16 {bold}',
	-legendfont=> '{Arial} 12 {bold}',
)->pack(-fill=>"both", -expand=>1);

my @data = (
[ 'Africa', 'Asia', 'Central America', 'Europe', 'North America', 'Oceania', 'South America' ],
[ 2,        16,     1,                 32,       3,               3,         4 ],
);

$chart->plot( \@data );

MainLoop();
