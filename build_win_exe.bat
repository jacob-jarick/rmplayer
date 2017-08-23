echo CLI
del rmplayer.exe
cmd /c pp -u -M File::Spec::Functions -M HTTP::Server::Simple::CGI -M CGI::Carp -M List::Util -M Term::ReadKey -M Config::IniHash -M Scalar::Util -M JSON -M File::stat -M threads -M threads::shared -M CGI -M List::MoreUtils -o rmplayer.exe rmplayer.pl


cmd /c pp -u -M Tk -M Tk::ROText -M Tk::Spinbox -M File::Spec::Functions -M Config::IniHash -M JSON -M List::MoreUtils -M Tk::NoteBook -M Tk::Chart::Pie -o config.exe config.pl
