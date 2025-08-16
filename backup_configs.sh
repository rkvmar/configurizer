#!/bin/bash

# Backup Current Configurations Script
# This script backs up your current configurations to the config directory

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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

print_status "Starting configuration backup..."
print_status "Script location: $SCRIPT_DIR"
print_status "Config directory: $CONFIG_DIR"

# Create config directories if they don't exist
mkdir -p "$CONFIG_DIR/nvim"
mkdir -p "$CONFIG_DIR/tmux"
mkdir -p "$CONFIG_DIR/omp"
mkdir -p "$CONFIG_DIR/iterm2"

# Backup Neovim config
if [ -d ~/.config/nvim ]; then
    print_status "Backing up Neovim configuration..."
    rm -rf "$CONFIG_DIR/nvim"/*
    cp -r ~/.config/nvim/* "$CONFIG_DIR/nvim/" 2>/dev/null || print_warning "Some nvim files couldn't be copied"
    print_success "Neovim configuration backed up"
else
    print_warning "Neovim config directory not found at ~/.config/nvim"
fi

# Backup Tmux config
if [ -d ~/.config/tmux ]; then
    print_status "Backing up Tmux configuration..."
    rm -rf "$CONFIG_DIR/tmux"/*
    cp -r ~/.config/tmux/* "$CONFIG_DIR/tmux/" 2>/dev/null || print_warning "Some tmux files couldn't be copied"
    print_success "Tmux configuration backed up"
else
    print_warning "Tmux config directory not found at ~/.config/tmux"
fi

# Backup Oh My Posh config
if [ -d ~/.config/omp ]; then
    print_status "Backing up Oh My Posh configuration..."
    rm -rf "$CONFIG_DIR/omp"/*
    cp -r ~/.config/omp/* "$CONFIG_DIR/omp/" 2>/dev/null || print_warning "Some omp files couldn't be copied"
    print_success "Oh My Posh configuration backed up"
else
    print_warning "Oh My Posh config directory not found at ~/.config/omp"
fi

# Backup .zshrc
if [ -f ~/.zshrc ]; then
    print_status "Backing up .zshrc..."
    cp ~/.zshrc "$CONFIG_DIR/zshrc"
    print_success ".zshrc backed up"
else
    print_warning ".zshrc not found at ~/.zshrc"
fi

# Backup iTerm2 color schemes and profiles
print_status "Looking for iTerm2 color schemes and profiles..."
color_schemes_found=false
profiles_found=false

# Check common locations for .itermcolors and .json files
for location in \
    ~/Library/Application\ Support/iTerm2/ \
    ~/Library/Application\ Support/iTerm2/DynamicProfiles/ \
    ~/Downloads/ \
    ~/Desktop/ \
    ~/.config/iterm2/ \
    ~/Documents/
do
    if [ -d "$location" ]; then
        # Backup .itermcolors files
        schemes=$(find "$location" -maxdepth 1 -name "*.itermcolors" 2>/dev/null)
        if [ -n "$schemes" ]; then
            for scheme in $schemes; do
                scheme_name=$(basename "$scheme")
                print_status "Found color scheme: $scheme_name"
                cp "$scheme" "$CONFIG_DIR/iterm2/"
                print_success "Backed up color scheme: $scheme_name"
                color_schemes_found=true
            done
        fi

        # Backup .json profile files
        profiles=$(find "$location" -maxdepth 1 -name "*.json" 2>/dev/null)
        if [ -n "$profiles" ]; then
            for profile in $profiles; do
                profile_name=$(basename "$profile")
                print_status "Found profile: $profile_name"
                cp "$profile" "$CONFIG_DIR/iterm2/"
                print_success "Backed up profile: $profile_name"
                profiles_found=true
            done
        fi
    fi
done

if [ "$color_schemes_found" = false ] && [ "$profiles_found" = false ]; then
    print_warning "No iTerm2 color schemes (.itermcolors) or profiles (.json) found in common locations"
    print_warning "If you have these files, manually copy them to $CONFIG_DIR/iterm2/"
elif [ "$color_schemes_found" = false ]; then
    print_warning "No iTerm2 color schemes (.itermcolors) found in common locations"
elif [ "$profiles_found" = false ]; then
    print_warning "No iTerm2 profiles (.json) found in common locations"
fi

# Optional: Backup additional common config files
print_status "Checking for additional common configuration files..."

# Git config
if [ -f ~/.gitconfig ]; then
    print_status "Backing up Git configuration..."
    cp ~/.gitconfig "$CONFIG_DIR/gitconfig"
    print_success "Git configuration backed up"
fi

# SSH config
if [ -f ~/.ssh/config ]; then
    print_status "Backing up SSH configuration..."
    cp ~/.ssh/config "$CONFIG_DIR/ssh_config"
    print_success "SSH configuration backed up"
    print_warning "Note: SSH keys are NOT backed up for security reasons"
fi

# Tmux plugin manager config (if exists)
if [ -f ~/.tmux.conf ]; then
    print_status "Backing up .tmux.conf..."
    cp ~/.tmux.conf "$CONFIG_DIR/tmux.conf"
    print_success ".tmux.conf backed up"
fi

print_success "Configuration backup completed!"
echo
print_status "Backed up configurations are located in: $CONFIG_DIR"
print_status "You can now run ./setup.sh on a fresh macOS install to restore these configurations"
echo
print_status "Files backed up:"
find "$CONFIG_DIR" -type f | sed 's|^'"$CONFIG_DIR"'/|  - |'
