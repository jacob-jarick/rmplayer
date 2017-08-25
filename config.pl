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
use Tk::Chart::Pie;
use Tk::Graph;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use rmvars;
use misc;
use jhash;
use config;

our $mw;
my $chart;
my $chart_frame;

my $chart_type = 'pie';

&config::load;
&config::load_playlist;
&config::load_dir_stack;
&display;
&plot;
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

	$mw = new MainWindow; # Main Window
	$mw->title("rmplayer.pl config");

	$mw->raise;

	$mw->protocol
	(
		'WM_DELETE_WINDOW',
		sub
		{
			$mw->destroy;
			exit;
		}
	);

	my $frame_top = $mw->Frame
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
	);
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub
		{
			if(lc $^O eq 'mswin32')
			{
				$config::app{main}{player_cmd} = '"C:/Program Files (x86)/VideoLAN/VLC/vlc.exe"';
			}
			else
			{
				$config::app{main}{player_cmd} = '/usr/bin/mpv';
			}
		}
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
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
	$col++;
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub
		{
			if(lc $^O eq 'mswin32')
			{
				$config::app{main}{kill_cmd} = 'taskkill /im vlc.exe > NUL 2>&1';
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
	);

	$col = 0;

	$tab1->Label(-text=>'Sync Data Every N Plays')-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
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
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);
	$col++;
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub { $config::app{main}{sync_every} = 3; }
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
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
		-from=>		0,
		-to=>		50,
		-increment=>	1,
		-width=>	8
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
	);
	$col++;
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub { $config::app{main}{play_count_limit} = 0; }
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
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
				$mw->destroy;
				&display;
				&plot;
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
				my $dd_dir = $mw->chooseDirectory
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
			-width=>	8,
			-command=>	sub
			{
				&config::load_dir_stack;
				&plot;
			}
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$row++;
	}

	$chart_frame = $mw->Frame()
	->pack
	(
		-side=>		'bottom',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	's'
	);

	&draw_chart;

	my $frame_buttons = $mw->Frame
	(
 		-height => 2,
	)->pack
	(
		-side=>		'bottom',
		-expand=>	1,
		-fill=>		'x',
		-anchor=>	's'
	);

	$row = 0;
	$col = 0;

	$frame_buttons->Radiobutton
	(
		-text=>		'Pie Chart',
		-variable=>	\$chart_type,
		-value=>	'pie',
		-command=>	sub
		{
			$chart->destroy;
			&draw_chart;
			&plot;
		}
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=> 2 );

	$frame_buttons->Radiobutton
	(
		-text=>		'Bar Chart',
		-variable=>	\$chart_type,
		-value=>	'bar',
		-command=>	sub
		{
			$chart->destroy;
			&draw_chart;
			&plot;
		}

	)-> grid(-row=>$row, -column=>$col++, -columnspan=>2, -sticky=> 'nw', -padx=> 2 );

	$row++;
	$col=0;

	$frame_buttons->Button
	(
		-text=>		'Add Directory',
		-command=>	sub
		{
			my $dd_dir = $mw->chooseDirectory
			(
				-title=>"Choose a directory"
			);

			if($dd_dir)
			{
				my $name = lc $dd_dir;
				$name =~ s/^.*(\\|\/)//;
				$config::dirs{$name}{path}	= $dd_dir;
				$config::dirs{$name}{enabled}	= 1;
				&config::save;
				$mw->destroy;
				&config::load;
				&display;
				&plot;
			}

		}
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=> 2 );

	$frame_buttons->Button
	(
		-text=>		'Save',
		-command=>	sub { &config::save; }
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=> 2 );

	$frame_buttons -> Button
	(
		-text=>		'Close',
		-command=>	sub { destroy $mw; }
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=> 2 );
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
		$filename = $mw->getOpenFile(-filetypes => $types);
	}
	else
	{
		$filename = $mw->getOpenFile();
	}
	if(defined $filename)
	{
		$filename =~ s/\\/\//g;
		$filename = "\"$filename\"" if $filename =~ m/\s+/;
		$config::app{main}{player_cmd} = $filename;
	}
}

sub plot
{
	if($chart_type eq 'bar')
	{
		&plot_bar;
		return;
	}
	my @names = ();
	my @values = ();

	my $total = 0;
	for my $key(keys %weight_hash)
	{
		$total += $weight_hash{$key};
	}

	for my $key(sort {lc $a cmp lc $b} keys %weight_hash)
	{
		my $p = int(100 * ($weight_hash{$key} / $total) );
		push @names, "$key - $p%";
		push @values, $weight_hash{$key};
	}

	my @data = ([@names], [@values]);

	$chart->plot( \@data );
}

sub plot_bar
{
	$chart->set(\%weight_hash);
}

sub draw_chart
{
	if($chart_type eq 'pie')
	{
		$chart = $chart_frame->Pie
		(
			-title=>	'Weighted Playlist' . "\n",
			-linewidth=>	3,
			-background=>	'#bababa',
			-titlefont=>	'{Arial} 16 {bold}',
			-legendfont=>	'{Arial} 12 {bold}',
		)->pack
		(
			-expand=>	1,
			-fill=>		'both',
		);
	}
	elsif($chart_type eq 'bar')
	{
		$chart = $chart_frame->Graph
		(
			-type=>		'HBars',
			-sortnames=>	'alpha',
			-font=>		'{Arial} 12 {bold}',
			-fill=>		'both',
			-legend=>	0,
			-padding=>	([15,20,20,100])

		)->pack
		(
			-expand=>	1,
			-fill=>		'both',
		);
	}
}

1;
