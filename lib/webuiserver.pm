package webuiserver;

use strict;
use warnings;

use threads ('yield', 'stack_size' => 64*4096, 'exit' => 'threads_only', 'stringify');
use Data::Dumper::Concise;
use HTTP::Server::Simple;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI;
use List::Util 'shuffle';

use FindBin qw/$Bin/;
use lib			$Bin;
use lib			"$Bin/lib";

use misc;
use rmvars;
use jhash;
use config;

my $script_out_file = "$Bin/script_out.txt";

my %dispatch =
(
	'/exit'		=> \&r_exit,
	'/stop'		=> \&r_stop,
	'/stopped'	=> \&r_stopped,
	'/play'		=> \&r_play,
	'/next'		=> \&r_next,
	'/ignore'	=> \&r_ignore,
	'/browse'	=> \&r_browse,
	'/browse2'	=> \&r_browse2,
	'/select'	=> \&r_select,
	'/limit'	=> \&r_limit,
	'/reload'	=> \&r_reload,
	'/select2'	=> \&r_select2,
	'/history'	=> \&r_history,
	'/que'		=> \&r_que,
	'/'		=> \&r_status,
	'/scripts'	=> \&r_scripts,
	'/disable'	=> \&r_disable,
	'/disable2'	=> \&r_disable2,
	'/enable'	=> \&r_enable,
	'/enable2'	=> \&r_enable2,

);

# setup dispatch to respond to any html request:

my $links = readjf($links_file);

sub handle_request
{
	my $self	= shift;
	my $cgi		= shift;

	my $path	= $cgi->path_info();
	my $handler = $dispatch{$path};

	if (ref($handler) eq 'CODE')
	{
		print "HTTP/1.0 200 OK\r\n";
		$handler->($cgi);
	}
	else
	{
		my $path_tmp = $path;
		$path_tmp =~ s/^\/(web|scripts)\///;
		if($path =~ /\/web\/.*(htm|html)/ && -f "$web_dir/$path_tmp")
		{
			print 	"HTTP/1.0 200 OK\r\n";
			print	$cgi->header,
					html_insert("$web_dir/$path_tmp", ''),
					$cgi->end_html;
		}
		elsif(($path =~ /\/scripts\/.*(sh|bat|exe)/i && -f "$Bin$path"))
		{
			my $cmd = "$Bin$path";
			print "HTTP/1.0 200 OK\r\n";
			print $cgi->header;
			&r_script_out($cmd);
		}
		else
		{
			print	"HTTP/1.0 404 Not found\r\n";
			print	$cgi->header,
					html_insert($index_html, "handle_request Path '$path' Not Found. file: $web_dir$path does not exist\n"),
					$cgi->end_html;
		}
	}
}

sub r_exit
{
	my $cgi  = shift;
	return if !ref $cgi;

	file_append( $cmd_file, 'EXIT');	# append to quefile for cmd

	&config::load;
	system($config::app{main}{kill_cmd} );

 	print	$cgi->header;
	print &html_insert($index_html, 'Exiting');
}

sub r_stop
{
	my $cgi  = shift;
	return if !ref $cgi;

	file_append( $cmd_file, 'STOP');	# append to quefile for cmd

	&config::load;
	system($config::app{main}{kill_cmd} );

 	print $cgi->header;
	print &html_insert($index_html, 'STOPPING', '/stopped');
}

sub r_reload
{
	my $cgi = shift;
	return if !ref $cgi;

	file_append( $cmd_file, 'RELOAD');	# append to quefile for cmd

 	print $cgi->header;
	print &html_insert($index_html, 'RELOADING PLAYLIST', '/');
}

sub r_stopped
{
	my $cgi  = shift;
	return if !ref $cgi;

 	print $cgi->header;
	print &html_insert($index_html, 'STOPPED');
}

sub r_play
{
	my $cgi = shift;
	return if !ref $cgi;

	file_append( $cmd_file, 'PLAY');	# append to quefile for cmd

 	print $cgi->header;
	print &html_insert($index_html, 'Resuming Playback', '/');
}

sub r_script_out
{
	my $cmd = shift;

	my $thr = threads->create(sub { system($cmd); exit; });
	$thr->detach();

	print "<!-- \$cmd = '$cmd' -->\n";
	print &html_insert($index_html, "<PRE>$cmd</PRE>", '/scripts', 2.5);
}

sub r_next
{
	my $cgi  = shift;
	return if !ref $cgi;

	file_append( $cmd_file, 'PLAY');	# append to quefile for cmd

	&config::load;
	system($config::app{main}{kill_cmd} );

 	print $cgi->header;
	print &html_insert($index_html, 'skipping to next file', '/');
}

sub r_limit
{
	my $cgi = shift;
	return if !ref $cgi;

	my $limit = $cgi->param('limit');

	if($limit =~ /(\d+)/)
	{
		$limit = $1;
	}
	else
	{
		print &html_insert($index_html, "'$limit' is not a number doofus.\n", '/');
		return;
	}

	&file_append($cmd_file, "LIMIT=$limit\n");

 	print $cgi->header;
	print &html_insert($index_html, "Limited playback to $limit files.\n");
}

sub r_ignore
{
	my $cgi  = shift;
	return if !ref $cgi;

	my @tmp = &readf($current_file);

	file_append( $cmd_file, "IGNORE\t" . $tmp[0]);

	&config::load;
	system($config::app{main}{kill_cmd});

 	print	$cgi->header;
	print &html_insert($index_html, "Added '$tmp[0]' to ignore list.", '/');
}

sub r_status
{
	my $cgi  = shift;
	return if !ref $cgi;

	my @tmp = readf( $current_file);
	my $file = $tmp[0];
	$file =~ s/^.*(\\|\/)//;

	my @tmp2 = ();
	@tmp2 = &readf($que_file) if -f $que_file;
	my @tmp3 = ();

	for (@tmp2)
	{
		s/^.*(\\|\/)//;
		s/^\s+//;
		s/\s+$//;
		s/\n+//g;
		push @tmp3, $_ if $_ ne '';
	}

	my $que_string = join("<BR>\n", @tmp3);
	$que_string = "<HR>QUEUED<BR>$que_string" if $que_string ne '' && $que_string =~ /\w/i;

 	print	$cgi->header;
	print &html_insert($index_html, "Currently Playing:<br>$file$que_string");

}

sub r_que
{
	my $cgi  = shift;
	return if !ref $cgi;

	my $file = $cgi->param('file');

	&file_append($que_file, $file);

 	print	$cgi->header;
	print &html_insert($index_html, "Queing $file", '/');
}

sub r_history
{
	my $cgi	= shift;
	my $msg	= '';
	my $c	= 0;
	my @tmp	= &readf($history_file);

	if(scalar(@tmp) > 30)
	{
		@tmp =  reverse @tmp[$#tmp-25 .. $#tmp];
	}
	else
	{
		@tmp =  reverse @tmp;
	}
	for my $file (@tmp)
	{
		$c++;
		next if ! defined $file || !$file;
		chomp $file;
		next if $file !~ /\S+/;

		my $fn		= $file;
		$fn			=~ s/^.*(\\|\/)(.*?)$/$2/;
		$fn			= &format_fn($2);

		my %h		= ();
		$h{c}		= $c;
		$h{fn}		= $fn;
		$h{file}	= $file;

		$msg .= join('', &html_insert_hash($queue_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub html_insert_hash
{
	my $file	= shift;
	my $r		= shift;
	my %h		= %$r;
	my @html	= readf($file);
	my @tmp		= ();

	for my $line (@html)
	{
		$line =~ s/\[version\]/$version/ig;

		for my $k (keys %h)
		{
			$line =~ s/\[$k\]/$h{$k}/ig;
		}
		push @tmp, $line;
	}
	return @tmp;
}

sub html_insert
{
	my $file	= shift;
	my $msg		= shift;
	my @html	= readf($file);

	my $redirect = shift;
	if(!defined $redirect)
	{
		$redirect = '';
	}
	else
	{
		my $timeout = shift;
		if(!defined $timeout)
		{
			$redirect = '<meta http-equiv="refresh" content="2; url='.$redirect.'" />';
		}
		else
		{
			$redirect = '<meta http-equiv="refresh" content="'.$timeout.'; url='.$redirect.'" />';
		}
	}

	my @tmp = ();
	for my $line (@html)
	{
		$line =~ s/\[msg\]/$msg/ig;
		$line =~ s/\[redirect\]/$redirect/ig;
		$line =~ s/\[version\]/$version/ig;
		push @tmp, $line;
	}
	return @tmp;
}

sub r_scripts
{
	my $cgi	= shift;
	my $msg	= '';

	opendir(DIR, $scripts_dir) or die "ERROR: r_scripts: couldn't opendir '$scripts_dir' to read.\n";
	my @dir_list = sort(readdir(DIR));
	closedir DIR;

	for my $s (@dir_list)
	{
		# windows only executeables
		next if(lc $^O eq "mswin32" && $s !~ /\.(bat|ps1|exe)$/i);
		# unix only scripts
		next if(lc $^O ne "mswin32" && $s !~ /\.(sh)$/i);

		$msg .="
			<a href=\"/scripts/$s\">
			<div><h2 class='button'>$s</h2></div>
			</a>
			";
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}


sub r_select2
{
	my $cgi = shift;

	return if !ref $cgi;

	my $dir		= $cgi->param('dir');
	my $msg		= '';
	my $c		= 1;
	my %dh		= ();		# load dir hash from file


	&config::load;
	&config::load_info;

	my @tmp	= sort {lc $a cmp lc $b} @{$info{$dir}{contents}};
	@tmp	= shuffle(@tmp) if $config::dirs{$dir}{random};
	@tmp	= @tmp[0 .. 24] if(scalar @tmp > 25);

	for my $file (@tmp)
	{
		my $name	= $file;
		$name		=~ m/^.*(\\|\/)(.*?)$/;
		$name		= &format_fn($2);

		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $name;
		$h{file}	= $file;

		$msg .= join('', &html_insert_hash($queue_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}


sub r_select
{
	my $cgi	= shift;
	my $msg	= '';
	my $c	= 1;

	my $ref	= &jhash::load($config::info_file);
	%info	= %$ref if defined $ref;

	for my $key (sort {lc $a cmp lc $b} keys %info)
	{
		$c++;
		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $key;
		$h{file}	= $key;

		$msg .= join('', &html_insert_hash($select_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub r_browse
{
	my $cgi	= shift;
	my $msg	= '';
	my $c	= 1;
	my $ref	= &jhash::load($config::info_file);
	%info	= %$ref if defined $ref;

	for my $key (sort {lc $a cmp lc $b} keys %info)
	{
		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $key;
		$h{file}	= $key;

		$msg .= join('', &html_insert_hash($browse_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub r_browse2
{
	my $cgi = shift;
	return if !ref $cgi;

	my $dir	= $cgi->param('dir');
	my $msg	= '';
	my $c	= 1;

	my $ref	= &jhash::load($config::info_file);
	%info	= %$ref if defined $ref;

	my %hash = ();
	for my $file ( (@{$info{$dir}{'contents'}}) )
	{
		my $fn	= $file;
		$fn		=~ m/^.*(\\|\/)(.*?)$/;
		$fn		= &format_fn($2);
		$hash{$fn}	= $file;
	}

	for my $name (sort {lc $a cmp lc $b} keys %hash)
	{
		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $name;
		$h{file}	= $hash{$name};

		$msg .= join('', &html_insert_hash($queue_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub r_disable2
{
	my $cgi = shift;
	return if !ref $cgi;

	my $dir = $cgi->param('dir');

	&misc::file_append($cmd_file, "DISABLE\t$dir");

 	print $cgi->header;
	print &html_insert($index_html, "Disabling '$dir'");
}

sub r_disable
{
	my $cgi	= shift;
	my $msg	= '';
	my $c	= 1;

	&config::load;

	for my $key (keys %config::dirs)
	{
		next if !$config::dirs{$key}{enabled};

		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $key;
		$h{file}	= $key;

		$msg .= join('', &html_insert_hash($disable_form, \%h));

	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub r_enable2
{
	my $cgi = shift;
	return if !ref $cgi;

	my $dir = $cgi->param('dir');
	my $msg = "Enabling '$dir'";

	&quit("r_enable2: \$config::dirs{$dir} is undef") if ! defined $config::dirs{$dir};

	&misc::file_append($cmd_file, "ENABLE\t$dir");

 	print	$cgi->header;
	print &html_insert($index_html, $msg);
}

sub r_enable
{
	my $cgi = shift;
	my $msg = 're-Enable Directory';
	&config::load;

	my $c = 1;
	for my $key (keys %config::dirs)
	{
		next if $config::dirs{$key}{enabled};

		my %h		= ();
		$h{c}		= $c++;
		$h{fn}		= $key;
		$h{file}	= $key;

		$msg .= join('', &html_insert_hash($enable_form, \%h));
	}
 	print $cgi->header;
	print &html_insert($index_html, $msg);
}

sub format_fn
{
	my $f		= shift;
	$f			=~ /^(.+)\.(.+?)$/;
	my $name	= $1;
	my $ext		= $2;
	$name		=~ s/(\.|_)/ /g;
	$ext		= lc($ext);

	return "$name.$ext";
}


1;
