@echo off
echo Installing all required CPAN modules for rmplayer...

REM Build tool (required for creating executables)
cmd /c cpanm -v PAR::Packer

REM Core functionality modules
cmd /c cpanm -v Time::HiRes
cmd /c cpanm -v Scalar::Util
cmd /c cpanm -v Data::Dumper::Concise
cmd /c cpanm -v Config::IniHash
cmd /c cpanm -v Term::ReadKey
cmd /c cpanm -v JSON
cmd /c cpanm -v FindBin
cmd /c cpanm -v Carp

REM Threading modules
cmd /c cpanm -v threads
cmd /c cpanm -v threads::shared

REM Web server modules
cmd /c cpanm -v HTTP::Server::Simple
cmd /c cpanm -v HTTP::Server::Simple::CGI
cmd /c cpanm -v CGI

REM List utilities
cmd /c cpanm -v List::MoreUtils
cmd /c cpanm -v List::Util

REM File handling modules
cmd /c cpanm -v File::Spec::Functions
cmd /c cpanm -v File::stat
cmd /c cpanm -v Cwd

REM GUI modules (for config tool)
cmd /c cpanm -v Tk
cmd /c cpanm -v Tk::ROText
cmd /c cpanm -v Tk::Spinbox
cmd /c cpanm -v Tk::NoteBook
cmd /c cpanm -v Tk::Chart::Pie
cmd /c cpanm -v Tk::Graph

REM Archive modules (for update.pl)
cmd /c cpanm -v Archive::Zip

REM Testing/utility modules
cmd /c cpanm -v File::Touch

echo.
echo Installation complete!
pause
