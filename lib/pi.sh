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

pi_config() {
    echo "Starting Pi Coding Agent in interactive mode for configuration..."
    echo "Please set up your API keys and preferences if prompted."
    echo "Press Ctrl+C to exit when done."
    echo ""
    
    if command -v pi &> /dev/null; then
        pi
    else
        echo "✗ pi-coding-agent not found. Run 'milhouse pi setup' first."
    fi
}

pi_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"

    local exit_code=0
    local tmp_rc=$(mktemp)

    # Pi Coding Agent
    # The tool attempts to start a TUI if it detects a TTY.
    # We force non-interactive mode by piping "exit" which handles both TUI suppression
    # and ensuring the session terminates after the prompt is processed.
    (timeout "${timeout_mins}m" bash -c 'echo "exit" | pi "$1" 2>&1' _ "$prompt"; echo $? > "$tmp_rc") | tee "$output_file"
    exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    
    rm -f "$tmp_rc"
    return $exit_code
}

pi_help() {
    cat << EOF
Milhouse Pi-Mono Commands

Usage:
  milhouse pi setup       Install @mariozechner/pi-coding-agent
  milhouse pi config      Run pi interactively for configuration
  milhouse pi status      Check installation status
  milhouse pi help        Show this help

Description:
  Integrates the Pi Coding Agent (from badlogic/pi-mono) into Milhouse.
  Allows running: milhouse run --tool pi

EOF
}
