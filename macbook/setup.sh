#!/bin/bash
# Homelab MacBook Setup Script
# This script configures MacBook to connect to Windows desktop Docker

set -e

echo "========================================"
echo "Homelab MacBook Setup"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Docker Desktop
echo -e "${YELLOW}[1/6] Checking Docker Desktop...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker Desktop not found!${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${YELLOW}WARNING: Docker Desktop may not be running. Please start it and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker Desktop is installed and running${NC}"

# Step 2: Get Windows connection info
echo ""
echo -e "${YELLOW}[2/6] Windows Desktop Connection${NC}"
read -p "Enter Windows desktop IP address or hostname: " WINDOWS_HOST
read -p "Enter Windows username (default: $(whoami)): " WINDOWS_USER
WINDOWS_USER=${WINDOWS_USER:-$(whoami)}

echo ""
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$WINDOWS_USER@$WINDOWS_HOST" exit 2>/dev/null; then
    echo -e "${YELLOW}SSH connection test failed. This is normal if you haven't set up SSH keys yet.${NC}"
    echo "We'll set that up next."
else
    echo -e "${GREEN}✓ SSH connection successful${NC}"
fi

# Step 3: Generate or use existing SSH key
echo ""
echo -e "${YELLOW}[3/6] Setting up SSH keys...${NC}"

SSH_KEY_PATH="$HOME/.ssh/id_rsa"
SSH_PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Generating new SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "homelab-macbook"
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${GREEN}✓ Using existing SSH key${NC}"
fi

# Step 4: Copy public key to Windows
echo ""
echo -e "${YELLOW}[4/6] Copying SSH public key to Windows...${NC}"
echo "You may be prompted for your Windows password (this is the last time)."

# Try ssh-copy-id, fallback to manual method
if command -v ssh-copy-id &> /dev/null; then
    ssh-copy-id "$WINDOWS_USER@$WINDOWS_HOST" 2>/dev/null || {
        echo "ssh-copy-id failed, trying manual method..."
        cat "$SSH_PUB_KEY_PATH" | ssh "$WINDOWS_USER@$WINDOWS_HOST" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
    }
else
    # Manual method
    cat "$SSH_PUB_KEY_PATH" | ssh "$WINDOWS_USER@$WINDOWS_HOST" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
fi

echo -e "${GREEN}✓ SSH key copied to Windows${NC}"

# Test passwordless SSH
echo "Testing passwordless SSH connection..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes "$WINDOWS_USER@$WINDOWS_HOST" exit 2>/dev/null; then
    echo -e "${GREEN}✓ Passwordless SSH working!${NC}"
else
    echo -e "${RED}WARNING: Passwordless SSH test failed. You may need to manually copy the key.${NC}"
    echo "Public key location: $SSH_PUB_KEY_PATH"
fi

# Step 5: Create Docker context
echo ""
echo -e "${YELLOW}[5/6] Creating Docker context...${NC}"

CONTEXT_NAME="windows-desktop"
DOCKER_HOST="ssh://$WINDOWS_USER@$WINDOWS_HOST"

# Check if context already exists
if docker context ls | grep -q "$CONTEXT_NAME"; then
    echo "Context '$CONTEXT_NAME' already exists. Removing old context..."
    docker context rm "$CONTEXT_NAME" 2>/dev/null || true
fi

# Create new context
docker context create "$CONTEXT_NAME" --docker "host=$DOCKER_HOST"
echo -e "${GREEN}✓ Docker context '$CONTEXT_NAME' created${NC}"

# Test context connection
echo "Testing Docker connection to Windows..."
if docker --context "$CONTEXT_NAME" info &> /dev/null; then
    echo -e "${GREEN}✓ Docker connection successful!${NC}"
else
    echo -e "${RED}WARNING: Docker connection test failed.${NC}"
    echo "You may need to ensure Docker Desktop is running on Windows."
fi

# Step 6: SMB Sharing Instructions
echo ""
echo -e "${YELLOW}[6/6] SMB File Sharing Setup${NC}"
echo ""
echo "To mount your MacBook code in Windows containers, you need to enable file sharing:"
echo ""
echo "1. Open System Settings > General > Sharing"
echo "2. Enable 'File Sharing'"
echo "3. Click 'Options' and enable 'Share files and folders using SMB'"
echo "4. Select your user account"
echo ""
echo "Then share your projects directory:"
echo "  - Click the '+' button under Shared Folders"
echo "  - Add your projects directory (e.g., ~/projects or ~/code)"
echo "  - Set permissions as needed"
echo ""
read -p "Press Enter when you've completed SMB setup (or skip for now)..."

# Get MacBook IP for reference
MACBOOK_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"

# Summary
echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Connection Information:"
echo "  Context Name: $CONTEXT_NAME"
echo "  Windows Host: $WINDOWS_HOST"
echo "  Windows User: $WINDOWS_USER"
echo "  MacBook IP: $MACBOOK_IP"
echo ""
echo "Usage:"
echo "  Switch to Windows context:"
echo "    docker context use $CONTEXT_NAME"
echo ""
echo "  Or use with commands:"
echo "    docker --context $CONTEXT_NAME ps"
echo ""
echo "  Switch back to local:"
echo "    docker context use default"
echo ""
echo "Helper scripts available in macbook/ directory:"
echo "  - use-windows.sh    : Switch to Windows context"
echo "  - use-local.sh      : Switch back to local context"
echo "  - check-connection.sh : Test connection"
echo ""



