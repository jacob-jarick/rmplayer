echo CLI
del rmplayer.exe
cmd /c pp -u -M Proc::Background -M File::Spec::Functions -M HTTP::Server::Simple::CGI -o rmplayer.exe rmplayer.pl
