package style;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Carp;

use Tk;
use Config::IniHash;
use Tk::ROText;
use Data::Dumper::Concise;
use Tk::Spinbox;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use rmvars;
use misc;
use config;
use jhash;

our $main;
&config::load;
&display;
MainLoop;

exit;

sub list
{
	my @arr = sort {lc $a cmp lc $b} keys  %config::dirs;
	return @arr;
}

sub rm
{
	my $name = shift;
	delete $config::dir{$name} if defined $config::dir{$name};
}

sub display
{
	my $row = 1;

	$main = new MainWindow; # Main Window
	$main->title("rmplayer.pl config");

	$main->raise;

	$main->protocol
	(
		'WM_DELETE_WINDOW',
		sub
		{
			$main->destroy;
			exit;
		}
	);

	my $frame_top = $main->Frame
	(
		-height => 10,
	)->pack
	(
		-side => 'top',
		-expand=> 1,
		-fill => 'both',
		-anchor => 'n'
	);

	my $col = 0;
	for my $name(&list)
	{
		$col = 0;

		$frame_top->Button
		(
			-text=>"Delete",
			-command => sub
			{
				delete $config::dirs{$name};
				&config::save;
				&config::load;
				$main->destroy;
				&display;
			}
		)-> grid
		(
			-row=>$row,
			-column=>$col++,
			-sticky=>'nw',
			-padx =>2
		);

		my $text = $frame_top -> ROText
		(
			-height=>	1,
			-width=>	20,
		)
		-> grid
		(
			-row=>$row,
			-column=>$col++,
			-sticky=>'nw',
			-padx =>2
		);
		$text->Contents($name);
		my $dir_text;
		$frame_top->Button
		(
			-text=>"Select",
			-command => sub
			{
				my $dd_dir = $main->chooseDirectory
				(
					-initialdir=>$config::dirs{$name}{path},
					-title=>"Choose a directory"
				);

				if($dd_dir)
				{
					$config::dirs{$name}{path} = $dd_dir;
					$dir_text->Contents($config::dirs{$name}{path});
				}

			}
		)-> grid
		(
			-row=>$row,
			-column=>$col++,
			-sticky=>'nw',
			-padx =>2
		);
		$dir_text = $frame_top->ROText
		(
			-height=>	1,
			-width=>	20,
		)
		-> grid
		(
			-row=>$row,
			-column=>$col++,
			-sticky=>'nw',
			-padx =>2
		);
 		$dir_text->Contents($config::dirs{$name}{path});

		$frame_top->Checkbutton
		(
			-text=>"Recursive",
			-variable=>\$config::dirs{$name}{recursive},
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$frame_top->Checkbutton
		(
			-text=>"Enable",
			-variable=>\$config::dirs{$name}{enabled},
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$frame_top->Label(-text=>'Weight')-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);

		my $spinbox = $frame_top->Spinbox
		(
			-textvariable=>\$config::dirs{$name}{weight},
			-from=>1,
			-to=>100,
			-increment=>1,
			-width=>8
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);



		$row++;
	}

	my $frame_buttons = $frame_top->Frame
	(
 		-height => 1,
	)-> grid
	(
		-row=>		$row,
		-column=>	0,
		-columnspan=>	$col,
		-sticky=>	'nw',
		-padx=>		2
	);
	$col=0;

	$frame_buttons->Button
	(
		-text=>		'Add',
		-command=>	sub
		{
			my $dd_dir = $main->chooseDirectory
			(
				-title=>"Choose a directory"
			);

			if($dd_dir)
			{
				my $name = $dd_dir;
				$name =~ s/^.*(\\|\/)//;
				$config::dirs{$name}{path}	= $dd_dir;
				$config::dirs{$name}{enabled}	= 1;
				&config::save;
				$main->destroy;
				&config::load;
				&display;
			}

		}
	)-> grid(-row=>0, -column=>$col++, -sticky=> 'nw', -padx=> 2 );

	$frame_buttons->Button
	(
		-text=>		'Save',
		-command=>	sub { &config::save; }
	)-> grid(-row=>0, -column=>$col++, -sticky=> 'nw', -padx=> 2 );

	$frame_buttons -> Button
	(
		-text=>		'Close',
		-command=>	sub { destroy $main; }
	)-> grid(-row=>0, -column=>$col++, -sticky=> 'nw', -padx=> 2 );
}


1;
