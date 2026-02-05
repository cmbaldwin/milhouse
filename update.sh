#!/usr/bin/env bash
set -euo pipefail

echo "Updating Milhouse from repository..."

# Get the source directory (where this script is)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in a git repo
if [[ ! -d "$SOURCE_DIR/.git" ]]; then
    echo "Error: Not in a git repository. Clone from:"
    echo "  git clone https://github.com/YOUR_USERNAME/milhouse.git"
    exit 1
fi

# Pull latest changes
echo "Pulling latest changes..."
cd "$SOURCE_DIR"
git pull origin main || git pull origin master || {
    echo "Error: Failed to pull from repository"
    exit 1
}

# Reinstall
echo "Reinstalling..."
bash "$SOURCE_DIR/install.sh"

echo ""
echo "✓ Milhouse updated successfully!"
echo ""
milhouse version
