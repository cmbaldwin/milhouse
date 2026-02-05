#!/usr/bin/env bash
set -euo pipefail

echo "Installing Milhouse..."

# Create bin directory if needed
mkdir -p ~/.local/bin

# Copy milhouse to bin
cp milhouse ~/.local/bin/milhouse
chmod +x ~/.local/bin/milhouse

# Copy lib directory
mkdir -p ~/.local/lib/milhouse
cp -r lib/* ~/.local/lib/milhouse/

# Update milhouse to use global lib path
sed -i.bak 's|SCRIPT_DIR=.*|SCRIPT_DIR="$HOME/.local/lib/milhouse"|' ~/.local/bin/milhouse
rm ~/.local/bin/milhouse.bak

echo "✓ Installed to ~/.local/bin/milhouse"

# Check if in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "⚠ Add to your PATH:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Add this to your ~/.bashrc or ~/.zshrc"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Try: milhouse help"
