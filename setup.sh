#!/bin/bash

# macOS Fresh Install Setup Script
# This script sets up a fresh macOS installation with all the essential tools and configurations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status "Starting macOS fresh install setup..."
print_status "Script location: $SCRIPT_DIR"

# Function to download configs if not present locally
download_configs() {
    if [ ! -d "$SCRIPT_DIR/config" ]; then
        print_status "Config directory not found locally. Downloading from GitHub..."

        # Create temporary directory
        TEMP_DIR=$(mktemp -d)

        # Download and extract the repository
        curl -L https://github.com/rkvmar/configurizer/archive/main.tar.gz | tar -xz -C "$TEMP_DIR"

        # Move config directory to script location
        if [ -d "$TEMP_DIR/configurizer-main/config" ]; then
            mv "$TEMP_DIR/configurizer-main/config" "$SCRIPT_DIR/"
            print_success "Configuration files downloaded successfully"
        else
            print_error "Failed to download configuration files"
            exit 1
        fi

        # Clean up
        rm -rf "$TEMP_DIR"
    else
        print_success "Using local configuration files"
    fi
}

# Download configs if needed
download_configs

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only!"
    exit 1
fi

# Install Xcode Command Line Tools (required for Homebrew)
print_status "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    xcode-select --install
    print_warning "Please complete the Xcode Command Line Tools installation and run this script again."
    exit 1
else
    print_success "Xcode Command Line Tools already installed"
fi

# Install Homebrew
print_status "Checking for Homebrew..."
if ! command_exists brew; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_success "Homebrew installed successfully"
else
    print_success "Homebrew already installed"
    print_status "Updating Homebrew..."
    brew update
fi

# Install Git
print_status "Installing Git..."
if ! command_exists git; then
    brew install git
    print_success "Git installed successfully"
else
    print_success "Git already installed"
fi

# Install essential CLI tools
print_status "Installing CLI tools (neovim, tmux, fzf, ripgrep, fd, zoxide)..."
brew install neovim tmux fzf ripgrep fd zoxide

# Install Oh My Posh
print_status "Installing Oh My Posh..."
if ! command_exists oh-my-posh; then
    brew install jandedobbeleer/oh-my-posh/oh-my-posh
    print_success "Oh My Posh installed successfully"
else
    print_success "Oh My Posh already installed"
fi

# Install JetBrainsMono Nerd Font
print_status "Installing JetBrainsMono Nerd Font..."
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
print_success "JetBrainsMono Nerd Font installed successfully"

# Install iTerm2
print_status "Installing iTerm2..."
brew install --cask iterm2
print_success "iTerm2 installed successfully"

# Create config directories
print_status "Creating configuration directories..."
mkdir -p ~/.config/nvim
mkdir -p ~/.config/tmux
mkdir -p ~/.config/omp
mkdir -p ~/.config/iterm2

# Copy configurations if they exist in the script directory
print_status "Setting up configurations..."

# Neovim config
if [ -d "$SCRIPT_DIR/config/nvim" ]; then
    print_status "Copying Neovim configuration..."
    cp -r "$SCRIPT_DIR/config/nvim/"* ~/.config/nvim/
    print_success "Neovim configuration copied"
else
    print_warning "Neovim config not found in $SCRIPT_DIR/config/nvim - you'll need to set it up manually"
fi

# Tmux config
if [ -d "$SCRIPT_DIR/config/tmux" ]; then
    print_status "Copying Tmux configuration..."
    cp -r "$SCRIPT_DIR/config/tmux/"* ~/.config/tmux/
    print_success "Tmux configuration copied"

    # Install TPM if not already present
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        print_status "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        print_success "TPM installed"
    fi
else
    print_warning "Tmux config not found in $SCRIPT_DIR/config/tmux - you'll need to set it up manually"
fi


# Oh My Posh config
if [ -d "$SCRIPT_DIR/config/omp" ]; then
    print_status "Copying Oh My Posh configuration..."
    cp -r "$SCRIPT_DIR/config/omp/"* ~/.config/omp/
    print_success "Oh My Posh configuration copied"
else
    print_warning "Oh My Posh config not found in $SCRIPT_DIR/config/omp - you'll need to set it up manually"
fi

# .zshrc
if [ -f "$SCRIPT_DIR/config/zshrc" ]; then
    print_status "Setting up .zshrc..."
    cp "$SCRIPT_DIR/config/zshrc" ~/.zshrc
    print_success ".zshrc copied"
else
    print_warning ".zshrc not found in $SCRIPT_DIR/config/ - you'll need to set it up manually"
fi


# iTerm2 color schemes and profiles
if [ -d "$SCRIPT_DIR/config/iterm2" ]; then
    # Handle .itermcolors files
    color_schemes=$(find "$SCRIPT_DIR/config/iterm2" -name "*.itermcolors" 2>/dev/null)
    if [ -n "$color_schemes" ]; then
        print_status "Setting up iTerm2 color schemes..."
        mkdir -p ~/Library/Application\ Support/iTerm2/

        for scheme in $color_schemes; do
            scheme_name=$(basename "$scheme")
            cp "$scheme" ~/Library/Application\ Support/iTerm2/
            print_success "Copied color scheme: $scheme_name"
        done

        print_warning "To apply color schemes: iTerm2 → Preferences → Profiles → Colors → Color Presets"
    fi

    # Handle JSON profile files
    json_profiles=$(find "$SCRIPT_DIR/config/iterm2" -name "*.json" 2>/dev/null)
    if [ -n "$json_profiles" ]; then
        print_status "Setting up iTerm2 profile configurations..."
        mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles/

        for profile in $json_profiles; do
            profile_name=$(basename "$profile")
            cp "$profile" ~/Library/Application\ Support/iTerm2/DynamicProfiles/
            print_success "Copied profile: $profile_name"
        done

        print_warning "iTerm2 profiles will be available after restarting iTerm2"
    fi

    if [ -n "$color_schemes" ] || [ -n "$json_profiles" ]; then
        print_warning "Please restart iTerm2 to see all new configurations"
    fi
fi

# Setup fzf key bindings and completion
print_status "Setting up fzf key bindings and completion..."
$(brew --prefix)/opt/fzf/install --all

source ~/.zshrc
# exec ~/.zshrc
# Final setup messages
print_success "Setup completed successfully!"

# Optional: Ask if user wants to restart terminal
read -p "Would you like to restart your shell now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec zsh
fi
