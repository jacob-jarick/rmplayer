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
use Tk::NoteBook;

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
		-side=>		'top',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	'n'
	);
        my $book = $frame_top->NoteBook()
        ->pack
	(
		-side=>		'top',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	'n'
	);

	# ----------------------------------------------------------------------------------------------------------
	# Main prefences tab

	my $tab1 = $book->add
	(
		'Sheet 1',
		-label=>'Main'
	);
	my $col = 0;
	$row = 0;

	$tab1->Label(-text=>'Player Command')
	-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);
	$tab1->Entry
	(
		-textvariable=>	\$config::app{main}{player_cmd},
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);

	$tab1->Button
	(
		-text=>'Select Player',
		-command => sub
		{
			&select_player;
		}
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx =>	2
	);
	$tab1->Button
	(
		-text=>'Clear',
		-command => sub
		{
			$config::app{main}{player_cmd} = '';
		}
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx =>	2
	);


	$col = 0;

	$tab1->Label(-text=>'Kill Player Command')
	-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);
	$tab1->Entry
	(
		-textvariable=>	\$config::app{main}{kill_cmd},
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub
		{
			if(lc $^O eq 'mswin32')
			{
				$config::app{main}{kill_cmd} = 'taskkill /im vlc.exe';
			}
			else
			{
				$config::app{main}{kill_cmd} = 'killall mpv';
			}
		}
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx =>	2
	);
	$tab1->Button
	(
		-text=>'Clear',
		-command => sub
		{
			$config::app{main}{kill_cmd} = '';
		}
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx =>	2
	);

	$col = 0;

	$tab1->Label(-text=>'Sync Data Every N Plays')-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		2
	);

	$tab1->Spinbox
	(
		-textvariable=>	\$config::app{main}{sync_every},
		-from=>		1,
		-to=>		10,
		-increment=>	1,
		-width=>	8
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col,
		-sticky=>	'nw',
	);
	$col = 0;
	$tab1->Label(-text=>'Play Count Limit')-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		2
	);

	$tab1->Spinbox
	(
		-textvariable=>	\$config::app{main}{play_count_limit},
		-from=>		1,
		-to=>		10,
		-increment=>	1,
		-width=>	8
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col,
		-sticky=>	'nw',
	);

	$col = 0;
	$tab1->Checkbutton
	(
		-text=>		'Debug',
		-variable=>	\$config::app{main}{debug},
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col,
		-sticky=>	'nw',
	);
	$tab1->Checkbutton
	(
		-text=>		'Web Server',
		-variable=>	\$config::app{main}{debug},
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col,
		-sticky=>	'nw',
	);
	$col = 0;


	# ----------------------------------------------------------------------------------------------------------
	# Directories Tab

	$row = 1;
	$col = 0;
	my $tab2 = $book->add
	(
		'Sheet 2',
		-label=>'Directories'
	);


	for my $name(&list)
	{
		$col = 0;

		$tab2->Button
		(
			-text=>'Delete',
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
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx =>	2
		);

		my $text = $tab2 -> ROText
		(
			-height=>	1,
			-width=>	20,
		)
		-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$text->Contents($name);
		my $dir_text;
		$tab2->Button
		(
			-text=>'Select',
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
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$dir_text = $tab2->ROText
		(
			-height=>	1,
			-width=>	20,
		)
		-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
 		$dir_text->Contents($config::dirs{$name}{path});

		$tab2->Checkbutton
		(
			-text=>		'Recursive',
			-variable=>	\$config::dirs{$name}{recursive},
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$tab2->Checkbutton
		(
			-text=>		'Enable',
			-variable=>	\$config::dirs{$name}{enabled},
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$tab2->Label(-text=>'Weight')-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);

		my $spinbox = $tab2->Spinbox
		(
			-textvariable=>	\$config::dirs{$name}{weight},
			-from=>		1,
			-to=>		100,
			-increment=>	1,
			-width=>	8
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$row++;
	}

	my $frame_buttons = $main->Frame
	(
 		-height => 1,
	)->pack
	(
		-side=>		'bottom',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	's'
	);
	$col=0;

	$frame_buttons->Button
	(
		-text=>		'Add Directory',
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

sub select_player
{
	my $filename;
	if(lc $^O eq 'mswin32')
	{
		my $types =
		[
			['Applications',	['.exe']	],
			['All Files',		'*',		],
		];
		$filename = $main->getOpenFile(-filetypes => $types);
	}
	else
	{
		$filename = $main->getOpenFile();
	}
	if(defined $filename)
	{
		$filename =~ s/\\/\//g;
		$filename = "\"$filename\"" if $filename =~ m/\s+/;
		$config::app{main}{player_cmd} = $filename;
	}
}

1;
