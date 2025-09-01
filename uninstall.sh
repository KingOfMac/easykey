#!/bin/bash

# EasyKey Uninstaller
# Removes EasyKey from the system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 EasyKey Uninstaller${NC}"
echo -e "${BLUE}=====================${NC}"
echo ""

# Check if EasyKey is installed
if [ ! -d "/Applications/EasyKey.app" ]; then
    echo -e "${YELLOW}⚠️  EasyKey is not installed in /Applications${NC}"
    exit 0
fi

echo -e "${YELLOW}🗑️  Removing EasyKey from Applications...${NC}"

# Remove the app
rm -rf "/Applications/EasyKey.app"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ EasyKey successfully removed from /Applications${NC}"
else
    echo -e "${RED}❌ Failed to remove EasyKey. Check permissions.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}💡 Note: Your secrets remain safely stored in the macOS keychain.${NC}"
echo -e "${BLUE}   Use the CLI tool or reinstall the app to access them again.${NC}"
echo ""
echo -e "${GREEN}🎉 Uninstallation complete!${NC}"
echo ""
