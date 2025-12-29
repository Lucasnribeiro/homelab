#!/bin/bash
# Switch Docker context to Windows desktop

CONTEXT_NAME="windows-desktop"

if docker context ls | grep -q "$CONTEXT_NAME"; then
    docker context use "$CONTEXT_NAME"
    echo "✓ Switched to Windows desktop context"
    echo ""
    echo "All docker commands will now run on Windows desktop."
    echo "To switch back: ./use-local.sh"
else
    echo "ERROR: Context '$CONTEXT_NAME' not found!"
    echo "Run ./setup.sh first to create the context."
    exit 1
fi



