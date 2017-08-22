#!/usr/bin/perl -w

$| = 1;

use warnings;
use strict;

use Carp qw(cluck longmess shortmess);
use FindBin qw/$Bin/;
use Data::Dumper::Concise;
use Config::IniHash;
use JSON;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use rmvars;
use webuiserver;
use misc;
use config;
use jhash;

our $server_pid;
$server_pid = 0;
$server_pid = webuiserver->new(8080)->run();

