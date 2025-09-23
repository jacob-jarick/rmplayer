#!/bin/bash
echo "==========================================="
echo "rmplayer Linux PAR Builder"
echo "==========================================="

# Check if PAR::Packer is installed
echo "Checking for PAR::Packer..."
if ! perl -MPAR::Packer -e "print qq(PAR::Packer found\n)" 2>/dev/null; then
    echo "ERROR: PAR::Packer not found. Please install with: cpanm PAR::Packer"
    exit 1
fi

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Build timestamp: $TIMESTAMP"
echo "$TIMESTAMP" > builddate.txt

echo
echo "Cleaning previous builds..."
rm -f rmplayer.par update.par

echo
echo "Building rmplayer.par..."
pp -p \
    -M File::Spec::Functions \
    -M HTTP::Server::Simple::CGI \
    -M List::Util \
    -M List::MoreUtils \
    -M Term::ReadKey \
    -M Config::IniHash \
    -M Scalar::Util \
    -M JSON \
    -M JSON::backportPP \
    -M JSON::PP \
    -M JSON::XS \
    -M File::stat \
    -M threads \
    -M threads::shared \
    -M CGI \
    -M Time::HiRes \
    -M Data::Dumper::Concise \
    -M Cwd \
    -M Tk \
    -M Tk::ROText \
    -M Tk::Spinbox \
    -M Tk::NoteBook \
    -M Tk::Chart::Pie \
    -M Tk::Graph \
    -o rmplayer.par rmplayer.pl

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build rmplayer.par"
    exit 1
fi
echo "✓ rmplayer.par built successfully"

echo
echo "Building update.par..."
pp -p \
    -M Archive::Zip \
    -M FindBin \
    -o update.par update.pl

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build update.par"
    exit 1
fi
echo "✓ update.par built successfully"

echo
echo "==========================================="
echo "Build completed successfully!"
echo "Build timestamp: $TIMESTAMP"
echo "==========================================="
echo
ls -la *.par
echo
echo "To run PAR files:"
echo "  perl rmplayer.par"
echo "  perl update.par"
