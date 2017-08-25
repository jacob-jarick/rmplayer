@ECHO OFF
: Sets the proper date and time stamp with 24Hr Time for log file naming
: convention

REM date string borrowed from: https://stackoverflow.com/questions/1192476/format-date-and-time-in-a-windows-batch-script
SET HOUR=%time:~0,2%
SET dtStamp9=%date:~-4%%date:~4,2%%date:~7,2%_0%time:~1,1%%time:~3,2%%time:~6,2%
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

if "%HOUR:~0,1%" == " " (SET dtStamp=%dtStamp9%) else (SET dtStamp=%dtStamp24%)

echo SET Build Date
ECHO %dtStamp% > builddate.txt

echo Build rmplayer.exe
del rmplayer.exe
cmd /c pp -u -M File::Spec::Functions -M HTTP::Server::Simple::CGI -M CGI::Carp -M List::Util -M Term::ReadKey -M Config::IniHash -M Scalar::Util -M JSON -M File::stat -M threads -M threads::shared -M CGI -M List::MoreUtils -o rmplayer.exe rmplayer.pl

echo Build config.exe
del config.exe
cmd /c pp -u -M Tk -M Tk::ROText -M Tk::Spinbox -M File::Spec::Functions -M Config::IniHash -M JSON -M List::MoreUtils -M Tk::NoteBook -M Tk::Chart::Pie -M Tk::Graph -o config.exe config.pl

echo Build update.exe
del update.exe
cmd /c pp -u -M LWP::Simple -M LWP::UserAgent -M File::Fetch -M Archive::Zip -o update.exe update.pl

echo Done
