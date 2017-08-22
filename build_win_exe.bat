echo CLI
del rmplayer.exe
cmd /c pp -u -M Proc::Background -M Proc::Background::Win32 -M File::Spec::Functions -M HTTP::Server::Simple::CGI -M CGI::Carp -M List::Util -M Term::ReadKey -M Config::IniHash -M Scalar::Util -M JSON -M File::stat -o rmplayer.exe rmplayer.pl
