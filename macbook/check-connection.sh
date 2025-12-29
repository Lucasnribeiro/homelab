#!/bin/bash
# Test connection to Windows desktop Docker

CONTEXT_NAME="windows-desktop"

echo "Testing connection to Windows desktop..."
echo ""

if ! docker context ls | grep -q "$CONTEXT_NAME"; then
    echo "ERROR: Context '$CONTEXT_NAME' not found!"
    echo "Run ./setup.sh first to create the context."
    exit 1
fi

echo "1. Testing SSH connection..."
WINDOWS_HOST=$(docker context inspect "$CONTEXT_NAME" --format '{{.Endpoints.docker.Host}}' | sed 's|ssh://.*@||' | sed 's|:.*||')
WINDOWS_USER=$(docker context inspect "$CONTEXT_NAME" --format '{{.Endpoints.docker.Host}}' | sed 's|ssh://||' | sed 's|@.*||')

if ssh -o ConnectTimeout=5 -o BatchMode=yes "$WINDOWS_USER@$WINDOWS_HOST" exit 2>/dev/null; then
    echo "   ✓ SSH connection successful"
else
    echo "   ✗ SSH connection failed"
    exit 1
fi

echo ""
echo "2. Testing Docker connection..."
if docker --context "$CONTEXT_NAME" info &> /dev/null; then
    echo "   ✓ Docker connection successful"
    echo ""
    echo "Docker info:"
    docker --context "$CONTEXT_NAME" info --format '{{.Name}}' | head -1
    echo ""
    echo "Running containers:"
    docker --context "$CONTEXT_NAME" ps
else
    echo "   ✗ Docker connection failed"
    echo "   Make sure Docker Desktop is running on Windows"
    exit 1
fi



