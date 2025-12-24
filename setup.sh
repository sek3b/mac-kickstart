#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is intended for macOS only."
    exit 1
fi

print_header "Mac Kickstart Script"
echo "This script will set up your Mac with common development tools and applications."
echo ""

# Ask for sudo password upfront
sudo -v

# Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ============================================================================
# Xcode Command Line Tools
# ============================================================================
print_header "Installing Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    print_success "Xcode Command Line Tools already installed"
else
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press any key once the installation is complete..."
    read -n 1 -s
fi

# ============================================================================
# Homebrew
# ============================================================================
print_header "Installing Homebrew"

if command -v brew &>/dev/null; then
    print_success "Homebrew already installed"
    echo "Updating Homebrew..."
    brew update
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    print_success "Homebrew installed"
fi

# ============================================================================
# CLI Tools
# ============================================================================
print_header "Installing CLI Tools"

CLI_TOOLS=(
    git             # Version control system
    wget            # Download files from the web
    curl            # Transfer data with URLs, API requests
    htop            # Interactive process viewer
    vim             # Terminal text editor
)

for tool in "${CLI_TOOLS[@]}"; do
    if brew list "$tool" &>/dev/null; then
        print_success "$tool already installed"
    else
        echo "Installing $tool..."
        brew install "$tool"
        print_success "$tool installed"
    fi
done

# ============================================================================
# Applications (Casks)
# ============================================================================
print_header "Installing Applications"

CASKS=(
    # Browsers
    brave-browser         # Privacy-focused Chromium browser with ad blocking

    # Development
    visual-studio-code    # Code editor with extensions ecosystem
    iterm2                # Feature-rich terminal replacement
    wireshark-chmodbpf    # Network protocol analyzer

    # Productivity
    obsidian              # Markdown-based knowledge base

    # Communication
    slack                 # Team messaging and collaboration

    # Utilities
    appcleaner            # Completely uninstall apps and leftovers
    stats                 # System monitor in menu bar
    rectangle             # Window management with keyboard shortcuts
)

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        print_success "$cask already installed"
    else
        echo "Installing $cask..."
        brew install --cask "$cask" || print_warning "Failed to install $cask"
    fi
done

# Third-party casks (require tap)
if brew list --cask claude-usage-tracker &>/dev/null; then
    print_success "claude-usage-tracker already installed"
else
    echo "Installing claude-usage-tracker..."
    brew tap hamed-elfayome/claude-usage 2>/dev/null || true
    brew install --cask --no-quarantine hamed-elfayome/claude-usage/claude-usage-tracker && \
        print_success "claude-usage-tracker installed" || \
        print_warning "Failed to install claude-usage-tracker"
fi

# ============================================================================
# VS Code Extensions & Settings
# ============================================================================
print_header "Configuring VS Code"

# Wait for VS Code to be available
if command -v code &>/dev/null; then
    # Install Catppuccin theme
    if code --list-extensions | grep -q "Catppuccin.catppuccin-vsc"; then
        print_success "Catppuccin theme already installed"
    else
        echo "Installing Catppuccin theme..."
        code --install-extension Catppuccin.catppuccin-vsc && \
            print_success "Catppuccin theme installed" || \
            print_warning "Failed to install Catppuccin theme"
    fi

    # Apply Catppuccin Macchiato theme in settings
    VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

    mkdir -p "$VSCODE_SETTINGS_DIR"

    if [[ -f "$VSCODE_SETTINGS_FILE" ]]; then
        # Check if theme is already set
        if grep -q '"workbench.colorTheme"' "$VSCODE_SETTINGS_FILE"; then
            # Update existing theme setting
            sed -i '' 's/"workbench.colorTheme":[^,}]*/"workbench.colorTheme": "Catppuccin Macchiato"/' "$VSCODE_SETTINGS_FILE"
        else
            # Add theme setting to existing file (before closing brace)
            sed -i '' 's/}$/,\n  "workbench.colorTheme": "Catppuccin Macchiato"\n}/' "$VSCODE_SETTINGS_FILE"
        fi
    else
        # Create new settings file
        cat > "$VSCODE_SETTINGS_FILE" << 'EOF'
{
  "workbench.colorTheme": "Catppuccin Macchiato"
}
EOF
    fi
    print_success "VS Code theme set to Catppuccin Macchiato"
else
    print_warning "VS Code CLI not found. Open VS Code once to install 'code' command, then re-run."
fi

# ============================================================================
# macOS System Preferences
# ============================================================================
print_header "Configuring macOS System Preferences"

# Finder: Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true
print_success "Finder: Show hidden files"

# Finder: Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
print_success "Finder: Show all filename extensions"

# Finder: Show path bar
defaults write com.apple.finder ShowPathbar -bool true
print_success "Finder: Show path bar"

# Finder: Show status bar
defaults write com.apple.finder ShowStatusBar -bool true
print_success "Finder: Show status bar"

# Finder: Set default view to list
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
print_success "Finder: Set default view to list"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
print_success "Finder: Disable extension change warning"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
print_success "Disable .DS_Store on network/USB volumes"

# Dock: Automatically hide and show
defaults write com.apple.dock autohide -bool true
print_success "Dock: Enable auto-hide"

# Dock: Set icon size
defaults write com.apple.dock tilesize -int 48
print_success "Dock: Set icon size to 48"

# Dock: Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true
print_success "Dock: Minimize to application icon"

# Trackpad: Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
print_success "Trackpad: Enable tap to click"

# Keyboard: Enable key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
print_success "Keyboard: Enable key repeat"

# Keyboard: Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
print_success "Keyboard: Set fast key repeat"

# Screenshots: Save to Desktop/Screenshots folder
mkdir -p "${HOME}/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Desktop/Screenshots"
print_success "Screenshots: Save to ~/Desktop/Screenshots"

# Screenshots: Save as PNG
defaults write com.apple.screencapture type -string "png"
print_success "Screenshots: Save as PNG"

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
print_success "Disable auto-correct"

# Enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
print_success "Enable full keyboard access"

# Restart affected applications
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

# ============================================================================
# Shell Configuration (Oh My Zsh)
# ============================================================================
print_header "Configuring Shell"

# Install Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_success "Oh My Zsh already installed"
else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed"
fi

# Set theme (robbyrussell is default, change to your preference)
if [[ -f "$HOME/.zshrc" ]]; then
    # Popular themes: robbyrussell, agnoster, avit, bira, dst, gentoo
    sed -i '' 's/ZSH_THEME=".*"/ZSH_THEME="robbyrussell"/' "$HOME/.zshrc"
    print_success "Oh My Zsh theme set to robbyrussell"
fi

# Enable useful plugins
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '' 's/plugins=(git)/plugins=(git z history sudo)/' "$HOME/.zshrc"
    print_success "Oh My Zsh plugins configured"
fi

# ============================================================================
# Git Configuration
# ============================================================================
print_header "Configuring Git"

# Set default branch name
git config --global init.defaultBranch main
print_success "Set default branch to 'main'"

# Set up some useful git aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
print_success "Added git aliases"

# Enable color
git config --global color.ui auto
print_success "Enabled git colors"

# Check if git user is configured
if [[ -z "$(git config --global user.name)" ]]; then
    print_warning "Git user.name not set. Configure with: git config --global user.name 'Your Name'"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    print_warning "Git user.email not set. Configure with: git config --global user.email 'your@email.com'"
fi

# ============================================================================
# Brave Browser Extensions (via policy)
# ============================================================================
print_header "Configuring Brave Extensions"

BRAVE_POLICY_DIR="/Library/Application Support/BraveSoftware/Brave-Browser/policies/managed"

# Extension IDs to auto-install
BRAVE_EXTENSIONS=(
    "hdokiejnpimakedhajhdlcegeplioahd"  # LastPass - Password Manager
)

# Build the extension list for the policy
EXT_LIST=""
for ext in "${BRAVE_EXTENSIONS[@]}"; do
    if [[ -n "$EXT_LIST" ]]; then
        EXT_LIST="$EXT_LIST,"
    fi
    EXT_LIST="$EXT_LIST\"$ext\""
done

# Create policy directory and file
sudo mkdir -p "$BRAVE_POLICY_DIR"
sudo tee "$BRAVE_POLICY_DIR/extensions.json" > /dev/null << EOF
{
  "ExtensionInstallForcelist": [$EXT_LIST]
}
EOF

print_success "Brave extensions policy configured"
echo "Extensions will auto-install when Brave launches"

# ============================================================================
# Cleanup
# ============================================================================
print_header "Cleaning Up"

brew cleanup
print_success "Homebrew cache cleaned"

# ============================================================================
# Summary
# ============================================================================
print_header "Setup Complete!"

echo "Your Mac has been configured with development tools and optimized settings."
echo ""
echo "Next steps:"
echo "  1. Restart your terminal to apply shell changes"
echo "  2. Configure Git user: git config --global user.name 'Your Name'"
echo "  3. Configure Git email: git config --global user.email 'your@email.com'"
echo "  4. Set up SSH keys: ssh-keygen -t ed25519 -C 'your@email.com'"
echo "  5. Log into your applications"
echo ""
echo "Installed CLI tools: ${CLI_TOOLS[*]}"
echo ""
print_success "Happy coding!"
