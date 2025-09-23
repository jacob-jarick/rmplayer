# 🎬 rmplayer

A cross-platform random media player with web-based remote control interface.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Perl](https://img.shields.io/badge/Perl-5.x-blue.svg)](https://www.perl.org/)

## ✨ Features

- **Smart Random Playback** - True randomness with intelligent history tracking to avoid recent repeats
- **Web-Based Remote Control** - Control playback from any device on your network
- **Cross-Platform** - Works on Windows, Linux, and macOS
- **Weighted Directory Selection** - Configure how often different folders are selected
- **Queue System** - Queue specific files for immediate playback
- **Auto-Update** - Built-in updater pulls latest version from GitHub
- **Flexible Configuration** - Supports recursive directory scanning, file filters, and more

## 🚀 Quick Start

### Windows
1. **Download** the latest version from [GitHub master branch](https://github.com/jacob-jarick/rmplayer/archive/refs/heads/master.zip)

2. **Extract** the files to a folder of your choice

3. **Run rmplayer**:
   ```cmd
   rmplayer.exe
   ```

4. **First-time setup**: rmplayer will automatically open the configuration tool to set up your media directories and player command

**Note**: No Perl installation required! The `.exe` files are self-contained.

### Linux/macOS

**Option 1: Use PAR files (Recommended)**
1. **Download** the latest version from [GitHub master branch](https://github.com/jacob-jarick/rmplayer/archive/refs/heads/master.zip)

2. **Extract** and ensure you have Perl installed:
   ```bash
   # Most systems have Perl pre-installed, check with:
   perl --version
   ```

3. **Run rmplayer using PAR files**:
   ```bash
   perl rmplayer.par
   ```
   **Note**: PAR files contain all dependencies - only base Perl required!

**Option 2: Run from source**
1. Install dependencies:
   ```bash
   # Install required Perl modules
   cpanm Time::HiRes Scalar::Util Data::Dumper::Concise Config::IniHash Term::ReadKey JSON threads HTTP::Server::Simple::CGI CGI List::MoreUtils List::Util File::Spec::Functions File::stat Cwd Tk Archive::Zip
   ```

2. Run rmplayer:
   ```bash
   perl rmplayer.pl
   ```

## 🎮 Usage

1. **First Run**: rmplayer will launch a configuration tool to set up your media directories and player command
2. **Web Interface**: Access the control panel at `http://localhost:8080`
3. **Keyboard Controls**: Press `q` in the terminal to quit

### Web Interface Features
- **Play/Stop/Next** - Basic playback controls
- **Browse & Queue** - Browse directories and queue specific files
- **History** - View recently played files
- **Settings** - Enable/disable directories, set play limits
- **Scripts** - Execute custom scripts (volume control, etc.)

## 🔄 Updates

rmplayer includes a built-in auto-updater that keeps you current with the latest version:

### Windows
```cmd
update.exe
```

### Linux/macOS
```bash
# Using PAR file (recommended)
perl update.par

# Or using source
perl update.pl
```

The updater will:
1. **Check** GitHub for newer versions by comparing build timestamps
2. **Download** the latest master branch automatically
3. **Extract** and replace files in your rmplayer directory
4. **Preserve** your configuration files (`config.ini`, `dirs.ini`, user data)

**No manual downloads needed!** The updater handles everything automatically.

## ⚙️ Configuration

rmplayer uses two main configuration files:

- **`config.ini`** - Application settings (player command, web server, etc.)
- **`dirs.ini`** - Media directory configuration

### Supported Media Formats
Anything your mediaplayer supports.

## 🔧 Advanced Features

### Smart Randomization
Unlike truly random players that can repeat files frequently, rmplayer:
- Tracks playback history per directory
- Ensures variety by avoiding recent plays
- Trims history when 80% of files have been played
- Provides weighted directory selection

### Custom Scripts
Place executable scripts in the `scripts/` directory:
- **Windows**: `.bat` or `.exe` files
- **Linux/macOS**: `.sh` files

Access via web interface at `/scripts`

### Auto-Updates
The built-in updater (`update.exe` / `update.pl`):
- Checks GitHub for newer versions
- Downloads and extracts updates automatically
- Compares build timestamps to determine update availability

## 🏗️ Building from Source

### Prerequisites
- Perl 5.x with required modules
- PAR::Packer (for executable generation)

### Build Process
```cmd
# Install all dependencies
install.cpan.modules.bat

# Build Windows executables
build_win_exe.bat
```

## 📝 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the Perl community for excellent modules
- HTTP::Server::Simple for the lightweight web server
- PAR::Packer for executable generation

---

**rmplayer** - Because sometimes you want random, but not *that* random.
