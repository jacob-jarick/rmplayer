#!/bin/bash
echo "Installing all required CPAN modules for rmplayer..."

# Build tool (required for creating PAR files)
cpanm -v PAR::Packer

# Core functionality modules
cpanm -v Time::HiRes
cpanm -v Scalar::Util
cpanm -v Data::Dumper::Concise
cpanm -v Config::IniHash
cpanm -v Term::ReadKey
cpanm -v JSON
cpanm -v FindBin
cpanm -v Carp

# Threading modules
cpanm -v threads
cpanm -v threads::shared

# Web server modules
cpanm -v HTTP::Server::Simple
cpanm -v HTTP::Server::Simple::CGI
cpanm -v CGI

# List utilities
cpanm -v List::MoreUtils
cpanm -v List::Util

# File handling modules
cpanm -v File::Spec::Functions
cpanm -v File::stat
cpanm -v Cwd

# GUI modules (for config tool)
cpanm -v Tk
cpanm -v Tk::ROText
cpanm -v Tk::Spinbox
cpanm -v Tk::NoteBook
cpanm -v Tk::Chart::Pie
cpanm -v Tk::Graph

# Archive modules (for update.pl)
cpanm -v Archive::Zip

# Testing/utility modules
cpanm -v File::Touch

echo
echo "Installation complete!"
