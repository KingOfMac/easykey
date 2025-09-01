#!/bin/bash

# EasyKey CLI Installer
# Builds and installs EasyKey from source code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 EasyKey CLI Installer${NC}"
echo -e "${BLUE}========================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "app/app.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Run this script from the EasyKey project root directory${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: Xcode is not installed or xcodebuild is not in PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Building EasyKey...${NC}"
cd app

# Build the app
xcodebuild -project app.xcodeproj -scheme app -configuration Release -derivedDataPath ./build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
else
    echo -e "${RED}❌ Build failed. Check your Xcode setup.${NC}"
    exit 1
fi

# Check if app was built
if [ ! -d "./build/Build/Products/Release/EasyKey.app" ]; then
    echo -e "${RED}❌ Error: EasyKey.app was not found in build output${NC}"
    exit 1
fi

echo -e "${YELLOW}📥 Installing EasyKey to Applications...${NC}"

# Remove existing installation if it exists
if [ -d "/Applications/EasyKey.app" ]; then
    echo -e "${YELLOW}🗑️  Removing existing EasyKey installation...${NC}"
    rm -rf "/Applications/EasyKey.app"
fi

# Copy the app to Applications
cp -r "./build/Build/Products/Release/EasyKey.app" "/Applications/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ EasyKey successfully installed to /Applications/EasyKey.app${NC}"
else
    echo -e "${RED}❌ Installation failed. Check permissions.${NC}"
    exit 1
fi

# Register with Launch Services
echo -e "${YELLOW}🔧 Registering with Launch Services...${NC}"
/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister -f -R "/Applications/EasyKey.app" > /dev/null 2>&1

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo -e "${BLUE}You can now find EasyKey in your Applications folder or launch it from Spotlight.${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  • Open from Applications folder"
echo -e "  • Press Cmd+Space and type 'EasyKey'"
echo -e "  • Use Touch ID/Face ID to unlock and manage your secrets"
echo ""
