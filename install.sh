#!/bin/bash

# Configurizer Bootstrap Script
# One-line installer for macOS fresh install setup

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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only!"
    exit 1
fi

print_status "Downloading and setting up development environment..."
echo

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download the repository
print_status "Downloading configurizer from GitHub..."
if ! curl -L https://github.com/rkvmar/configurizer/archive/main.tar.gz | tar -xz; then
    print_error "Failed to download configurizer repository"
    exit 1
fi

# Navigate to the extracted directory
cd configurizer-main

# Make scripts executable
chmod +x *.sh

print_success "Repository downloaded successfully!"
echo

# Run the main setup script
print_status "Starting setup process..."
./setup.sh

# Clean up
cd ~
rm -rf "$TEMP_DIR"
print_success "Install complete"
