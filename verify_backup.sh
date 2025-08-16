#!/bin/bash

# Verify Backup Script
# This script checks that all configurations were properly backed up

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

print_status "Verifying backup configurations..."
print_status "Config directory: $CONFIG_DIR"
echo

# Check if config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    print_error "Config directory not found! Please run ./backup_configs.sh first."
    exit 1
fi

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Function to check file/directory
check_item() {
    local item_path="$1"
    local item_name="$2"
    local is_required="$3"  # true/false

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ -e "$item_path" ]; then
        if [ -d "$item_path" ]; then
            local file_count=$(find "$item_path" -type f | wc -l)
            print_success "$item_name: ✓ (directory with $file_count files)"
        else
            local file_size=$(du -h "$item_path" | cut -f1)
            print_success "$item_name: ✓ (file, $file_size)"
        fi
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        if [ "$is_required" = "true" ]; then
            print_error "$item_name: ✗ (missing - this is important!)"
        else
            print_warning "$item_name: ✗ (missing - optional)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))  # Don't penalize for optional items
        fi
    fi
}

# Check core configurations
print_status "Checking core configurations..."
check_item "$CONFIG_DIR/nvim" "Neovim config" true
check_item "$CONFIG_DIR/tmux" "Tmux config" true
check_item "$CONFIG_DIR/omp" "Oh My Posh config" true
check_item "$CONFIG_DIR/zshrc" ".zshrc" true

echo

# Check optional configurations
print_status "Checking optional configurations..."
check_item "$CONFIG_DIR/gitconfig" "Git config" false
check_item "$CONFIG_DIR/ssh_config" "SSH config" false
check_item "$CONFIG_DIR/tmux.conf" "Tmux root config" false

# Check for iTerm2 color schemes and profiles
if [ -d "$CONFIG_DIR/iterm2" ]; then
    iterm_colors_count=$(find "$CONFIG_DIR/iterm2" -name "*.itermcolors" 2>/dev/null | wc -l)
    iterm_profiles_count=$(find "$CONFIG_DIR/iterm2" -name "*.json" 2>/dev/null | wc -l)

    if [ "$iterm_colors_count" -gt 0 ] || [ "$iterm_profiles_count" -gt 0 ]; then
        print_success "iTerm2 configurations: ✓ ($iterm_colors_count color schemes, $iterm_profiles_count profiles)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_warning "iTerm2 configurations: ✗ (no .itermcolors or .json files found)"
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

echo

# Detailed verification of key configs
print_status "Performing detailed verification..."

# Check if Neovim config has essential files
if [ -d "$CONFIG_DIR/nvim" ]; then
    if [ -f "$CONFIG_DIR/nvim/init.lua" ] || [ -f "$CONFIG_DIR/nvim/init.vim" ]; then
        print_success "Neovim init file found"
    else
        print_warning "No init.lua or init.vim found in Neovim config"
    fi
fi

# Check if Tmux config has configuration files
if [ -d "$CONFIG_DIR/tmux" ]; then
    tmux_conf_count=$(find "$CONFIG_DIR/tmux" -name "*.conf" -o -name "*.tmux" | wc -l)
    if [ "$tmux_conf_count" -gt 0 ]; then
        print_success "Tmux configuration files found ($tmux_conf_count files)"
    else
        print_warning "No .conf or .tmux files found in Tmux config"
    fi
fi

# Check if Oh My Posh has theme files
if [ -d "$CONFIG_DIR/omp" ]; then
    omp_theme_count=$(find "$CONFIG_DIR/omp" -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" | wc -l)
    if [ "$omp_theme_count" -gt 0 ]; then
        print_success "Oh My Posh theme files found ($omp_theme_count files)"
    else
        print_warning "No theme files found in Oh My Posh config"
    fi
fi

# Check .zshrc content
if [ -f "$CONFIG_DIR/zshrc" ]; then
    zshrc_lines=$(wc -l < "$CONFIG_DIR/zshrc")
    if [ "$zshrc_lines" -gt 5 ]; then
        print_success ".zshrc appears to have content ($zshrc_lines lines)"
    else
        print_warning ".zshrc seems quite short ($zshrc_lines lines)"
    fi
fi

# Check iTerm2 color schemes and profiles details
if [ -d "$CONFIG_DIR/iterm2" ]; then
    color_schemes=$(find "$CONFIG_DIR/iterm2" -name "*.itermcolors" 2>/dev/null)
    json_profiles=$(find "$CONFIG_DIR/iterm2" -name "*.json" 2>/dev/null)

    if [ -n "$color_schemes" ]; then
        print_success "Found iTerm2 color schemes:"
        for scheme in $color_schemes; do
            scheme_name=$(basename "$scheme")
            scheme_size=$(du -h "$scheme" | cut -f1)
            echo "    - $scheme_name ($scheme_size)"
        done
    fi

    if [ -n "$json_profiles" ]; then
        print_success "Found iTerm2 profiles:"
        for profile in $json_profiles; do
            profile_name=$(basename "$profile")
            profile_size=$(du -h "$profile" | cut -f1)
            echo "    - $profile_name ($profile_size)"
        done
    fi
fi

echo

# Summary
print_status "Verification Summary:"
echo "  Checks passed: $PASSED_CHECKS/$TOTAL_CHECKS"

if [ "$PASSED_CHECKS" -eq "$TOTAL_CHECKS" ]; then
    print_success "All verifications passed! Your backup looks complete."
    echo
    print_status "You can now use ./setup.sh on a fresh macOS install."
elif [ "$PASSED_CHECKS" -ge $((TOTAL_CHECKS * 3 / 4)) ]; then
    print_warning "Most verifications passed. Some optional items are missing."
    echo
    print_status "Your backup should work, but you may want to check the missing items."
else
    print_error "Several verifications failed. Your backup may be incomplete."
    echo
    print_status "Consider running ./backup_configs.sh again or manually checking your configurations."
fi

echo
print_status "Backup verification complete!"

# Show a summary of what's backed up
echo
print_status "Backed up files and directories:"
find "$CONFIG_DIR" -type f -o -type d | grep -v "^$CONFIG_DIR$" | sed 's|^'"$CONFIG_DIR"'/|  |' | sort
