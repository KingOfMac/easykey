#!/bin/bash

# EasyKey CLI Uninstaller
# Removes EasyKey CLI tools and packages from the system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 EasyKey CLI Uninstaller${NC}"
echo -e "${BLUE}==========================${NC}"
echo ""

REMOVED_SOMETHING=false

# Remove CLI tool
if [ -f "/usr/local/bin/easykey" ]; then
    echo -e "${YELLOW}🗑️  Removing CLI tool from /usr/local/bin...${NC}"
    sudo rm -f "/usr/local/bin/easykey"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ CLI tool successfully removed${NC}"
        REMOVED_SOMETHING=true
    else
        echo -e "${RED}❌ Failed to remove CLI tool. Check permissions.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}ℹ️  CLI tool not found in /usr/local/bin${NC}"
fi

# Remove Python package
if command -v pip3 &> /dev/null && pip3 show easykey &> /dev/null; then
    echo -e "${YELLOW}🐍 Removing Python package...${NC}"
    pip3 uninstall -y easykey
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Python package successfully removed${NC}"
        REMOVED_SOMETHING=true
    else
        echo -e "${RED}❌ Failed to remove Python package${NC}"
    fi
elif command -v pip &> /dev/null && pip show easykey &> /dev/null; then
    echo -e "${YELLOW}🐍 Removing Python package...${NC}"
    pip uninstall -y easykey
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Python package successfully removed${NC}"
        REMOVED_SOMETHING=true
    else
        echo -e "${RED}❌ Failed to remove Python package${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Python package not found${NC}"
fi

# Remove Node.js package
if command -v npm &> /dev/null && npm list -g @kingofmac/easykey &> /dev/null; then
    echo -e "${YELLOW}📦 Removing Node.js package...${NC}"
    npm uninstall -g @kingofmac/easykey
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Node.js package successfully removed${NC}"
        REMOVED_SOMETHING=true
    else
        echo -e "${RED}❌ Failed to remove Node.js package${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Node.js package not found${NC}"
fi

echo ""

if [ "$REMOVED_SOMETHING" = true ]; then
    echo -e "${GREEN}🎉 CLI uninstallation complete!${NC}"
    echo ""
    echo -e "${BLUE}💡 Note: Your secrets remain safely stored in the macOS keychain.${NC}"
    echo -e "${BLUE}   The EasyKey app (if installed) is still available to access them.${NC}"
else
    echo -e "${YELLOW}ℹ️  No EasyKey CLI components were found to remove.${NC}"
fi

echo ""
