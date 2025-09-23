@ECHO OFF
echo =========================================
echo rmplayer Windows Executable Builder
echo =========================================

REM Check if PAR::Packer is installed
echo Checking for PAR::Packer...
cmd /c perl -MPAR::Packer -e "print qq(PAR::Packer found\n)" 2>nul
if %ERRORLEVEL% neq 0 (
    echo ERROR: PAR::Packer not found. Please install with: cpanm PAR::Packer
    pause
    exit /b 1
)

REM Sets the proper date and time stamp with 24Hr Time for log file naming
REM date string borrowed from: https://stackoverflow.com/questions/1192476/format-date-and-time-in-a-windows-batch-script
SET HOUR=%time:~0,2%
SET dtStamp9=%date:~-4%%date:~4,2%%date:~7,2%_0%time:~1,1%%time:~3,2%%time:~6,2%
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

if "%HOUR:~0,1%" == " " (SET dtStamp=%dtStamp9%) else (SET dtStamp=%dtStamp24%)

echo SET Build Date: %dtStamp%
ECHO %dtStamp% > builddate.txt

echo.
echo Cleaning previous builds...
del rmplayer.exe 2>nul
del update.exe 2>nul
del rmplayer.par 2>nul
del update.par 2>nul

echo.
echo Building rmplayer.exe...
cmd /c pp -z 9 -u ^
    -M File::Spec::Functions ^
    -M HTTP::Server::Simple::CGI ^
    -M List::Util ^
    -M List::MoreUtils ^
    -M Term::ReadKey ^
    -M Config::IniHash ^
    -M Scalar::Util ^
    -M JSON ^
    -M JSON::backportPP ^
    -M JSON::PP ^
    -M JSON::XS ^
    -M File::stat ^
    -M threads ^
    -M threads::shared ^
    -M CGI ^
    -M Time::HiRes ^
    -M Data::Dumper::Concise ^
    -M Cwd ^
    -M Tk ^
    -M Tk::ROText ^
    -M Tk::Spinbox ^
    -M Tk::NoteBook ^
    -M Tk::Chart::Pie ^
    -M Tk::Graph ^
    -o rmplayer.exe rmplayer.pl

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build rmplayer.exe
    pause
    exit /b 1
)
echo ✓ rmplayer.exe built successfully

echo.
echo Building update.exe...
cmd /c pp -n -z 9 ^
    -M Archive::Zip ^
    -M FindBin ^
    -o update.exe update.pl

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build update.exe
    pause
    exit /b 1
)
echo ✓ update.exe built successfully

echo.
echo Building rmplayer.par...
cmd /c pp -p ^
    -M File::Spec::Functions ^
    -M HTTP::Server::Simple::CGI ^
    -M List::Util ^
    -M List::MoreUtils ^
    -M Term::ReadKey ^
    -M Config::IniHash ^
    -M Scalar::Util ^
    -M JSON ^
    -M JSON::backportPP ^
    -M JSON::PP ^
    -M JSON::XS ^
    -M File::stat ^
    -M threads ^
    -M threads::shared ^
    -M CGI ^
    -M Time::HiRes ^
    -M Data::Dumper::Concise ^
    -M Cwd ^
    -M Tk ^
    -M Tk::ROText ^
    -M Tk::Spinbox ^
    -M Tk::NoteBook ^
    -M Tk::Chart::Pie ^
    -M Tk::Graph ^
    -o rmplayer.par rmplayer.pl

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build rmplayer.par
    pause
    exit /b 1
)
echo ✓ rmplayer.par built successfully

echo.
echo Building update.par...
cmd /c pp -p ^
    -M Archive::Zip ^
    -M FindBin ^
    -o update.par update.pl

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build update.par
    pause
    exit /b 1
)
echo ✓ update.par built successfully

echo.
echo =========================================
echo Build completed successfully!
echo Build timestamp: %dtStamp%
echo =========================================
echo.
echo Windows Executables:
dir *.exe
echo.
echo Cross-platform PAR files:
dir *.par
echo.
echo To run PAR files: perl rmplayer.par
echo.
pause
