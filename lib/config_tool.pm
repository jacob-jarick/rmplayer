package config_tool;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;
use Carp qw(cluck longmess shortmess);

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

my $mw;

my $book;
my $tab1;
my $tab2;

my $frame_main;
my $chart;
my $chart_frame;
my $entry_width = 40;
my $pad_size	= 2;

my $chart_type = 'pie';

sub show
{
	&config::load;
	&config::load_playlist;
	&config::load_dir_stack;

	$mw = new MainWindow; # Main Window
	$mw->title("rmplayer.pl config");

	$mw->bind('<KeyPress>' => sub
	{
		if($Tk::event->K eq 'F5')
		{
			$frame_main->destroy;
			&refresh;
		}
	}
	);

	$mw->protocol
	(
		'WM_DELETE_WINDOW',
		sub
		{
			$mw->destroy;
			exit;
		}
	);

	&display;
	&plot;
	$mw->raise;
	MainLoop;
}

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

	$frame_main = $mw->Frame()->pack
	(
		-side=>		'top',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	'n'
	);


	my $frame_top = $frame_main->Frame
	(
		-height => 10,
	)->pack
	(
		-side=>		'top',
		-expand=>	0,
		-fill=>		'both',
		-anchor=>	'n'
	);
        $book = $frame_top->NoteBook()
        ->pack
	(
		-side=>		'top',
		-expand=>	0,
		-fill=>		'both',
		-anchor=>	'n'
	);

	# ----------------------------------------------------------------------------------------------------------
	# Main prefences tab

	$tab1 = $book->add
	(
		'Sheet 1',
		-label=>'Main'
	);
	my $col = 0;
	$row = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Label(-text=>'Media Extensions to Play')
	-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$tab1->Entry
	(
		-textvariable=>	\$config::app{main}{media_extensions},
		-width=>	$entry_width,
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$col++;

	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub
		{
			$config::app{main}{media_extensions} = $config::media_extensions_default;
		}
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$tab1->Button
	(
		-text=>'Clear',
		-command => sub
		{
			$config::app{main}{media_extensions} = '';
		}
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$col = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Label(-text=>'Player Command')
	-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$tab1->Entry
	(
		-textvariable=>	\$config::app{main}{player_cmd},
		-width=>	$entry_width,
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);


	$col = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Label(-text=>'Kill Player Command')
	-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$tab1->Entry
	(
		-textvariable=>	\$config::app{main}{kill_cmd},
		-width=>	$entry_width,
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$col++;
	$tab1->Button
	(
		-text=>'Set to Default',
		-command => sub
		{
			$config::app{main}{kill_cmd} = 'killall mpv';
			$config::app{main}{kill_cmd} = 'taskkill /im vlc.exe > NUL 2>&1' if lc $^O eq 'mswin32';
		}
	)-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$col = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Label(-text=>'Sync Data Every N Plays')-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$col++;
	$tab1->Button
	(
		-text=>		'Set to Default',
		-command=>	sub { $config::app{main}{sync_every} = 3; }
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$col = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Label(-text=>'Play Count Limit')-> grid
	(
		-row=>		$row,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
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
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);
	$col++;
	$tab1->Button
	(
		-text=>		'Set to Default',
		-command=>	sub { $config::app{main}{play_count_limit} = 0; }
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col++,
		-sticky=>	'nw',
		-padx=>		$pad_size,
		-pady=>		$pad_size,
	);

	$col = 0;

	# ----------------------------------------------------------------------------------------------------------

	$tab1->Checkbutton
	(
		-text=>		'Debug',
		-variable=>	\$config::app{main}{debug},
	)-> grid
	(
		-row=>		$row++,
		-column=>	$col,
		-sticky=>	'nw',
		-padx=>		$pad_size,
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
		-padx=>		$pad_size,
	);
	$col = 0;

	# ----------------------------------------------------------------------------------------------------------
	# Directories Tab

	$row = 1;
	$col = 0;
	$tab2 = $book->add
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
				&refresh;
			}
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		$pad_size,
			-pady=>		$pad_size,
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
			-padx=>		$pad_size,
			-pady=>		$pad_size,
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
				&refresh;

			}
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		$pad_size,
			-pady=>		$pad_size,
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
			-padx=>		$pad_size,
			-pady=>		$pad_size,
		);
 		$dir_text->Contents($config::dirs{$name}{path});

		$tab2->Checkbutton
		(
			-text=>		'Recursive',
			-variable=>	\$config::dirs{$name}{recursive},
			-command=>	\&refresh,
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		$pad_size,
			-pady=>		$pad_size,
		);
		$tab2->Checkbutton
		(
			-text=>		'Random',
			-variable=>	\$config::dirs{$name}{random},
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		$pad_size,
			-pady=>		$pad_size,
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
			-padx=>		$pad_size,
			-pady=>		$pad_size,
		);
		$tab2->Label(-text=>'Weight')-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		$pad_size,
			-pady=>		$pad_size,
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
			-padx=>		$pad_size,
			-pady=>		$pad_size,
		);
		$row++;
	}

	# ----------------------------------------------------------------------------------------------------------
	# Buttons Frame

	my $frame_buttons = $frame_main->Frame
	(
 		-height => 2,
	)->pack
	(
		-side=>		'bottom',
		-expand=>	0,
		-fill=>		'x',
		-anchor=>	's'
	);

	$chart_frame = $frame_main->Frame()
	->pack
	(
		-side=>		'bottom',
		-expand=>	1,
		-fill=>		'both',
		-anchor=>	's',
	);

	$row = 0;
	$col = 0;

	$frame_buttons->Radiobutton
	(
		-text=>		'Pie Chart',
		-variable=>	\$chart_type,
		-value=>	'pie',
		-command=>	sub { &refresh; }
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=>$pad_size,  -pady=> $pad_size,);

	$frame_buttons->Radiobutton
	(
		-text=>		'Bar Chart',
		-variable=>	\$chart_type,
		-value=>	'bar',
		-command=>	sub { &refresh; }

	)-> grid(-row=>$row, -column=>$col++, -columnspan=>2, -sticky=> 'nw', -padx=>$pad_size, -pady=> $pad_size,);

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
				&refresh;
			}

		}
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=>$pad_size, -pady=> $pad_size,);

	$frame_buttons->Button
	(
		-text=>		'Save',
		-command=>	sub { &config::save; }
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=>$pad_size, -pady=> $pad_size,);

	$frame_buttons -> Button
	(
		-text=>		'Close',
		-command=>	sub { destroy $mw; }
	)-> grid(-row=>$row, -column=>$col++, -sticky=> 'nw', -padx=>$pad_size,  -pady=> $pad_size,);

	&draw_chart;
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
	return if !scalar keys %weight_hash;
	if($chart_type eq 'bar')
	{
		&plot_bar;
		return;
	}
	my @names	= ();
	my @values	= ();
	my $total	= 0;

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
			-side=>		'bottom',
			-expand=>	1,
			-fill=>		'both',
			-anchor=>	's'
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
			-padding=>	([15,20,20,120])

		)->pack
		(
			-side=>		'bottom',
			-expand=>	1,
			-fill=>		'both',
			-anchor=>	's'
		);
	}
}

sub quit
{
	my $string = shift;
	cluck $string;
	exit;
}

sub refresh
{
	$frame_main->destroy;
	&config::save;
	&config::load_playlist;
	&config::load_dir_stack;
	&display;
	&plot;

	$book->raise('Sheet 2');
}

1;
