#!/bin/bash

# EasyKey Complete Installer
# Builds and installs all EasyKey components: Python package, CLI tool, and macOS app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 EasyKey Complete Installer${NC}"
echo -e "${BLUE}=============================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "app/app.xcodeproj/project.pbxproj" ] || [ ! -f "cli/easykey.xcodeproj/project.pbxproj" ] || [ ! -f "python/setup.py" ] || [ ! -f "nodejs/package.json" ]; then
    echo -e "${RED}❌ Error: Run this script from the EasyKey project root directory${NC}"
    exit 1
fi

# Function to install Python package
install_python_package() {
    echo -e "${YELLOW}🐍 Installing Python package...${NC}"
    cd python
    
    if command -v pip3 &> /dev/null; then
        pip3 install easykey
    elif command -v pip &> /dev/null; then
        pip install easykey
    else
        echo -e "${RED}❌ Error: pip not found. Please install Python and pip first.${NC}"
        cd ..
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Python package installed successfully!${NC}"
    else
        echo -e "${RED}❌ Python package installation failed.${NC}"
        cd ..
        return 1
    fi
    cd ..
}

# Function to install Node.js package
install_nodejs_package() {
    echo -e "${YELLOW}📦 Installing Node.js package...${NC}"
    cd nodejs
    
    if command -v npm &> /dev/null; then
        npm install -g @kingofmac/easykey
    else
        echo -e "${RED}❌ Error: npm not found. Please install Node.js and npm first.${NC}"
        cd ..
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Node.js package installed successfully!${NC}"
    else
        echo -e "${RED}❌ Node.js package installation failed.${NC}"
        cd ..
        return 1
    fi
    cd ..
}

# Function to install CLI tool
install_cli_tool() {
    echo -e "${YELLOW}🖥️  Building CLI tool...${NC}"
    cd cli
    
    if ! command -v swift &> /dev/null; then
        echo -e "${RED}❌ Error: Swift is not installed or not in PATH${NC}"
        cd ..
        return 1
    fi
    
    swift build -c release > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ CLI build successful!${NC}"
    else
        echo -e "${RED}❌ CLI build failed.${NC}"
        cd ..
        return 1
    fi
    
    # Install to /usr/local/bin
    echo -e "${YELLOW}📥 Installing CLI tool to /usr/local/bin...${NC}"
    sudo cp .build/release/easykey /usr/local/bin/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ CLI tool installed successfully!${NC}"
    else
        echo -e "${RED}❌ CLI tool installation failed. Check permissions.${NC}"
        cd ..
        return 1
    fi
    cd ..
}

# Function to install macOS app
install_macos_app() {
    echo -e "${YELLOW}📱 Building macOS app...${NC}"
    cd app
    
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ Error: Xcode is not installed or xcodebuild is not in PATH${NC}"
        cd ..
        return 1
    fi
    
    # Build the app
    xcodebuild -project app.xcodeproj -scheme app -configuration Release -derivedDataPath ./build > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ App build successful!${NC}"
    else
        echo -e "${RED}❌ App build failed. Check your Xcode setup.${NC}"
        cd ..
        return 1
    fi
    
    # Check if app was built
    if [ ! -d "./build/Build/Products/Release/EasyKey.app" ]; then
        echo -e "${RED}❌ Error: EasyKey.app was not found in build output${NC}"
        cd ..
        return 1
    fi
    
    echo -e "${YELLOW}📥 Installing EasyKey app to Applications...${NC}"
    
    # Remove existing installation if it exists
    if [ -d "/Applications/EasyKey.app" ]; then
        echo -e "${YELLOW}🗑️  Removing existing EasyKey installation...${NC}"
        rm -rf "/Applications/EasyKey.app"
    fi
    
    # Copy the app to Applications
    cp -r "./build/Build/Products/Release/EasyKey.app" "/Applications/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ EasyKey app successfully installed to /Applications/EasyKey.app${NC}"
    else
        echo -e "${RED}❌ App installation failed. Check permissions.${NC}"
        cd ..
        return 1
    fi
    
    # Register with Launch Services
    echo -e "${YELLOW}🔧 Registering with Launch Services...${NC}"
    /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R "/Applications/EasyKey.app" > /dev/null 2>&1
    cd ..
}

# Install all components
echo -e "${BLUE}Installing all EasyKey components...${NC}"
echo ""

# Install Python package
install_python_package

# Install Node.js package
install_nodejs_package

# Install CLI tool
install_cli_tool

# Install macOS app
install_macos_app

echo ""
echo -e "${GREEN}🎉 Complete installation finished!${NC}"
echo ""
echo -e "${YELLOW}What was installed:${NC}"
echo -e "  📱 macOS App: /Applications/EasyKey.app"
echo -e "  🖥️  CLI Tool: /usr/local/bin/easykey"
echo -e "  🐍 Python Package: Available via 'import easykey'"
echo -e "  📦 Node.js Package: Available via 'require(\"@kingofmac/easykey\")'"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  • App: Open from Applications folder or Spotlight"
echo -e "  • CLI: Run 'easykey --help' in terminal"
echo -e "  • Python: import easykey; easykey.secret('KEY_NAME')"
echo -e "  • Node.js: const easykey = require('@kingofmac/easykey'); easykey.secret('KEY_NAME')"
echo ""
