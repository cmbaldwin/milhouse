#!/usr/bin/env bash
# Ruby/Rails setup for Milhouse
# Installs recommended skills and MCP servers for Ruby/Rails development

# Default Ruby/Rails skills (GitHub repos)
RUBY_SKILLS=(
    "robzolkos/skill-rails-system-test-analyzer"
    "maquina-app/rails-upgrade-skill"
    "esparkman/claude-rubycritic-skill"
)

# Default Ruby/Rails MCP servers
RUBY_MCP_SERVERS=(
    "rails-mcp-server"
)

ruby_setup() {
    echo "Setting up Ruby/Rails defaults for Milhouse..."
    echo ""

    # Check for required tools
    if ! command -v gem &> /dev/null; then
        echo "⚠ Ruby/gem not found. Please install Ruby first."
        return 1
    fi

    if ! command -v claude &> /dev/null; then
        echo "⚠ Claude CLI not found. Please install claude-cli first."
        return 1
    fi

    echo "Installing Ruby/Rails skills and MCP servers..."
    echo ""

    # Install skills
    ruby_install_skills

    # Install MCP servers
    ruby_install_mcp_servers

    echo ""
    echo "✓ Ruby/Rails setup complete!"
    echo ""
    echo "Available skills:"
    echo "  /rails-system-test-analyzer  - Analyze system tests for controller conversion"
    echo "  /rails-upgrade-assistant     - Upgrade Rails versions with guidance"
    echo "  (RubyCritic is model-invoked - ask Claude to analyze code quality)"
    echo ""
    echo "MCP Server tools:"
    echo "  rails-mcp-server provides: project_info, list_files, get_routes, analyze_models, get_schema, etc."
    echo ""
    echo "Run 'rails-mcp-config' to configure Rails projects for the MCP server."
}

ruby_install_skills() {
    local skills_dir="$HOME/.claude/skills"
    mkdir -p "$skills_dir"

    echo "Installing Claude Code skills..."

    # RubyCritic skill
    if [[ -d "$skills_dir/rubycritic-skill" ]]; then
        echo "  ✓ RubyCritic skill already installed"
    else
        echo "  → Installing RubyCritic skill..."
        local temp_dir=$(mktemp -d)
        if git clone --quiet https://github.com/esparkman/claude-rubycritic-skill.git "$temp_dir" 2>/dev/null; then
            # Check skills/ directory first (actual structure)
            if [[ -d "$temp_dir/skills/rubycritic-skill" ]]; then
                cp -r "$temp_dir/skills/rubycritic-skill" "$skills_dir/"
                echo "  ✓ Installed rubycritic-skill"
            elif [[ -d "$temp_dir/.claude/skills/rubycritic-skill" ]]; then
                cp -r "$temp_dir/.claude/skills/rubycritic-skill" "$skills_dir/"
                echo "  ✓ Installed rubycritic-skill"
            else
                echo "  ⚠ Could not find rubycritic-skill folder in repo"
            fi
        else
            echo "  ⚠ Failed to clone rubycritic-skill repo"
        fi
        rm -rf "$temp_dir"
    fi

    # Ensure rubycritic gem is installed
    if ! gem list rubycritic -i &> /dev/null; then
        echo "  → Installing rubycritic gem..."
        gem install rubycritic --quiet
        echo "  ✓ Installed rubycritic gem"
    else
        echo "  ✓ rubycritic gem already installed"
    fi

    # Rails System Test Analyzer
    if [[ -d "$skills_dir/rails-system-test-analyzer" ]]; then
        echo "  ✓ Rails System Test Analyzer already installed"
    else
        echo "  → Installing Rails System Test Analyzer skill..."
        local temp_dir=$(mktemp -d)
        if git clone --quiet https://github.com/robzolkos/skill-rails-system-test-analyzer.git "$temp_dir" 2>/dev/null; then
            if [[ -d "$temp_dir/.claude/skills/rails-system-test-analyzer" ]]; then
                cp -r "$temp_dir/.claude/skills/rails-system-test-analyzer" "$skills_dir/"
                echo "  ✓ Installed rails-system-test-analyzer"
            else
                echo "  ⚠ Could not find rails-system-test-analyzer folder in repo"
            fi
        else
            echo "  ⚠ Failed to clone rails-system-test-analyzer repo"
        fi
        rm -rf "$temp_dir"
    fi

    # Rails Upgrade Assistant (SKILL.md at repo root)
    if [[ -d "$skills_dir/rails-upgrade-assistant" ]]; then
        echo "  ✓ Rails Upgrade Assistant already installed"
    else
        echo "  → Installing Rails Upgrade Assistant skill..."
        local temp_dir=$(mktemp -d)
        if git clone --quiet https://github.com/maquina-app/rails-upgrade-skill.git "$temp_dir" 2>/dev/null; then
            # This skill has SKILL.md at repo root - copy entire repo as skill folder
            mkdir -p "$skills_dir/rails-upgrade-assistant"
            # Copy all files except .git
            cp -r "$temp_dir/SKILL.md" "$skills_dir/rails-upgrade-assistant/"
            cp -r "$temp_dir/bin" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/docs" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/detection-scripts" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/examples" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/reference" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/templates" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/version-guides" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            cp -r "$temp_dir/workflows" "$skills_dir/rails-upgrade-assistant/" 2>/dev/null || true
            echo "  ✓ Installed rails-upgrade-assistant"
        else
            echo "  ⚠ Failed to clone rails-upgrade-skill repo"
        fi
        rm -rf "$temp_dir"
    fi
}

ruby_install_mcp_servers() {
    echo ""
    echo "Installing MCP servers..."

    # Rails MCP Server
    echo "  → Installing rails-mcp-server gem..."
    if gem list rails-mcp-server -i &> /dev/null; then
        echo "  ✓ rails-mcp-server already installed"
    else
        gem install rails-mcp-server --quiet
        echo "  ✓ Installed rails-mcp-server"
    fi

    # Configure MCP server for Claude
    ruby_configure_mcp_server
}

ruby_configure_mcp_server() {
    local claude_settings="$HOME/.claude/settings.json"

    echo ""
    echo "Configuring rails-mcp-server for Claude..."

    # Check if settings file exists
    if [[ ! -f "$claude_settings" ]]; then
        echo "  Creating $claude_settings..."
        mkdir -p "$(dirname "$claude_settings")"
        echo '{}' > "$claude_settings"
    fi

    # Check if rails-mcp-server is already configured
    if grep -q "rails-mcp-server" "$claude_settings" 2>/dev/null; then
        echo "  ✓ rails-mcp-server already configured in Claude settings"
        return 0
    fi

    # Add rails-mcp-server to MCP servers
    # This uses jq to safely modify JSON
    if command -v jq &> /dev/null; then
        local rails_mcp_path=$(which rails-mcp-server 2>/dev/null || echo "rails-mcp-server")

        local mcp_config='{
            "rails-mcp-server": {
                "command": "rails-mcp-server",
                "args": []
            }
        }'

        # Merge with existing settings (with backup)
        cp "$claude_settings" "$claude_settings.bak"
        if jq --argjson mcp "$mcp_config" '.mcpServers = (.mcpServers // {}) + $mcp' "$claude_settings" > "$claude_settings.tmp" 2>/dev/null; then
            mv "$claude_settings.tmp" "$claude_settings"
            rm -f "$claude_settings.bak"
        else
            echo "  ⚠ Failed to update settings, restoring backup"
            mv "$claude_settings.bak" "$claude_settings"
            rm -f "$claude_settings.tmp"
            return 1
        fi

        echo "  ✓ Added rails-mcp-server to Claude MCP settings"
        echo ""
        echo "  Note: Run 'rails-mcp-config' to add your Rails projects"
    else
        echo "  ⚠ jq not found. Please manually add rails-mcp-server to $claude_settings"
        echo ""
        echo "  Add this to your settings.json mcpServers section:"
        echo '    "rails-mcp-server": {'
        echo '        "command": "rails-mcp-server",'
        echo '        "args": []'
        echo '    }'
    fi
}

ruby_status() {
    echo "Ruby/Rails Milhouse Status"
    echo "=========================="
    echo ""

    # Check skills
    echo "Skills:"
    local skills_dir="$HOME/.claude/skills"

    if [[ -d "$skills_dir/rails-system-test-analyzer" ]]; then
        echo "  ✓ rails-system-test-analyzer"
    else
        echo "  ✗ rails-system-test-analyzer (not installed)"
    fi

    if [[ -d "$skills_dir/rails-upgrade-assistant" ]]; then
        echo "  ✓ rails-upgrade-assistant"
    else
        echo "  ✗ rails-upgrade-assistant (not installed)"
    fi

    if [[ -d "$skills_dir/rubycritic-skill" ]]; then
        echo "  ✓ rubycritic-skill"
    else
        echo "  ✗ rubycritic-skill (not installed)"
    fi

    # Check MCP servers
    echo ""
    echo "MCP Servers:"
    if gem list rails-mcp-server -i &> /dev/null; then
        local version=$(gem list rails-mcp-server | grep rails-mcp-server | sed 's/.*(\(.*\))/\1/')
        echo "  ✓ rails-mcp-server ($version)"
    else
        echo "  ✗ rails-mcp-server (not installed)"
    fi

    # Check gems
    echo ""
    echo "Required Gems:"
    if gem list rubycritic -i &> /dev/null; then
        echo "  ✓ rubycritic"
    else
        echo "  ✗ rubycritic (not installed)"
    fi

    # Check Claude settings
    echo ""
    echo "Claude Configuration:"
    local claude_settings="$HOME/.claude/settings.json"
    if [[ -f "$claude_settings" ]] && grep -q "rails-mcp-server" "$claude_settings" 2>/dev/null; then
        echo "  ✓ rails-mcp-server configured in Claude"
    else
        echo "  ✗ rails-mcp-server not configured in Claude"
    fi
}

ruby_help() {
    cat << EOF
Milhouse Ruby/Rails Commands

Usage:
  milhouse ruby setup     Install all Ruby/Rails skills and MCP servers
  milhouse ruby status    Check installation status
  milhouse ruby skills    Install only skills
  milhouse ruby mcp       Install only MCP servers
  milhouse ruby help      Show this help

Included Skills:
  /rails-system-test-analyzer
    Analyze Rails system tests and identify candidates for conversion
    to faster controller tests. Traces code paths and detects JavaScript
    dependencies.

  /rails-upgrade-assistant
    Comprehensive Rails upgrade guidance from 7.0 through 8.1.1.
    Automatic project analysis, breaking change identification, and
    multi-hop upgrade planning.

  rubycritic (model-invoked)
    Analyze Ruby/Rails code quality. Just ask Claude to "analyze code
    quality" and it will use RubyCritic automatically.

Included MCP Servers:
  rails-mcp-server
    Provides Rails-specific tools: project_info, list_files, get_file,
    get_routes, analyze_models, get_schema, execute_ruby, and access
    to Rails/Turbo/Stimulus documentation.

    Configure with: rails-mcp-config

EOF
}
