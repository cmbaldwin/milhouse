#!/usr/bin/env bash
# Pi-Mono setup for Milhouse
# Installs and configures proper usage of @mariozechner/pi-coding-agent

pi_setup() {
    echo "Setting up Pi Coding Agent for Milhouse..."
    echo ""

    # Check for Node.js/NPM
    if ! command -v npm &> /dev/null; then
        echo "⚠ Node.js/npm not found. Please install Node.js first."
        return 1
    fi

    echo "Installing @mariozechner/pi-coding-agent..."
    echo ""

    # Try global install, fall back to sudo if needed, or suggest npx
    if npm install -g @mariozechner/pi-coding-agent; then
        echo "  ✓ Installed globally"
    else
        echo "  ⚠ Global install failed (permission/other)."
        echo "  Attempting with sudo..."
        if sudo npm install -g @mariozechner/pi-coding-agent; then
             echo "  ✓ Installed globally with sudo"
        else
             echo "  ✗ Failed to install. You may need to install manually:"
             echo "    npm install -g @mariozechner/pi-coding-agent"
             return 1
        fi
    fi

    echo ""
    echo "✓ Pi Coding Agent setup complete!"
    echo ""
}

pi_status() {
    echo "Pi-Mono Milhouse Status"
    echo "======================="
    echo ""

    if command -v pi &> /dev/null; then
        local version=$(pi --version 2>/dev/null || echo "unknown")
        echo "  ✓ pi-coding-agent installed (as 'pi', version $version)"
    else
        echo "  ✗ pi-coding-agent (not installed)"
        echo ""
        echo "  Run 'milhouse pi setup' to install."
    fi
}

pi_help() {
    cat << EOF
Milhouse Pi-Mono Commands

Usage:
  milhouse pi setup       Install @mariozechner/pi-coding-agent
  milhouse pi status      Check installation status
  milhouse pi help        Show this help

Description:
  Integrates the Pi Coding Agent (from badlogic/pi-mono) into Milhouse.
  Allows running: milhouse run --tool pi

EOF
}
