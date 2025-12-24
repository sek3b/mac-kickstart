# mac-kickstart

A macOS bootstrap script that automates setting up a new Mac with development tools, applications, and optimized system preferences.

## What It Does

- Installs Xcode Command Line Tools
- Installs and configures Homebrew (with Apple Silicon support)
- Installs CLI tools: git, wget, curl, htop, vim
- Installs applications via Homebrew Cask:
  - **Browser:** Brave
  - **Development:** VS Code, iTerm2, Wireshark
  - **Productivity:** Obsidian
  - **Communication:** Slack
  - **Utilities:** AppCleaner, Stats, Rectangle
  - **Other:** Claude Usage Tracker (via third-party tap)
- Configures VS Code with Catppuccin Macchiato theme
- Sets up Oh My Zsh with useful plugins
- Configures Git with aliases and sensible defaults
- Applies macOS preferences:
  - Finder: show hidden files, extensions, path bar, list view
  - Dock: auto-hide, minimize to app icon
  - Keyboard: fast key repeat, full keyboard access
  - Trackpad: tap to click
  - Screenshots: save to ~/Desktop/Screenshots as PNG

## Usage

```bash
git clone https://github.com/yourusername/mac-kickstart.git
cd mac-kickstart
chmod +x setup.sh
./setup.sh
```

The script will prompt for your sudo password. It's safe to re-run as it skips already-installed items.

## After Running

1. Restart your terminal to apply shell changes
2. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```
3. Set up SSH keys:
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ```
4. Log into your applications

## Customization

Edit `setup.sh` to modify:
- `CLI_TOOLS` array - add/remove brew packages
- `CASKS` array - add/remove applications
- `BRAVE_EXTENSIONS` array - add extension IDs for auto-install
- macOS defaults section - adjust system preferences

## Requirements

- macOS (script checks and exits on other platforms)
- Internet connection
- Admin privileges (sudo)
