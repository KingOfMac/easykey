#!/bin/bash

# EasyKey CLI Tool Installer
# Builds and installs only the EasyKey command-line tool

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 EasyKey CLI Tool Installer${NC}"
echo -e "${BLUE}=============================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "cli/easykey.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Run this script from the EasyKey project root directory${NC}"
    exit 1
fi

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install Xcode or Swift toolchain first.${NC}"
    exit 1
fi

echo -e "${YELLOW}🖥️  Building EasyKey CLI tool...${NC}"
cd cli

# Build the CLI tool
swift build -c release > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed. Check your Swift/Xcode setup.${NC}"
    exit 1
fi

# Check if binary was built
if [ ! -f ".build/release/easykey" ]; then
    echo -e "${RED}❌ Error: easykey binary was not found in build output${NC}"
    exit 1
fi

echo -e "${YELLOW}📥 Installing CLI tool to /usr/local/bin...${NC}"

# Create /usr/local/bin if it doesn't exist
if [ ! -d "/usr/local/bin" ]; then
    echo -e "${YELLOW}📁 Creating /usr/local/bin directory...${NC}"
    sudo mkdir -p /usr/local/bin
fi

# Install the CLI tool
sudo cp .build/release/easykey /usr/local/bin/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CLI tool successfully installed to /usr/local/bin/easykey${NC}"
else
    echo -e "${RED}❌ Installation failed. Check permissions.${NC}"
    exit 1
fi

# Make sure it's executable
sudo chmod +x /usr/local/bin/easykey

echo ""
echo -e "${GREEN}🎉 EasyKey CLI tool installation complete!${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  easykey --help                    # Show help"
echo -e "  easykey set KEY \"value\"           # Store a secret"
echo -e "  easykey get KEY                   # Retrieve a secret"
echo -e "  easykey list                      # List all secrets"
echo -e "  easykey status                    # Show vault status"
echo ""
echo -e "${BLUE}Note: This only installs the CLI tool. For other components, use:${NC}"
echo -e "  • macOS app only: ./app.sh"
echo -e "  • Python package: pip install easykey"
echo -e "  • Complete installation: ./install.sh"
echo ""
