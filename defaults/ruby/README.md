# Ruby/Rails Defaults for Milhouse

Milhouse is an opinionated Ruby AI automation tool. This directory documents the default Ruby/Rails skills and MCP servers that are installed with `milhouse ruby setup`.

## Quick Start

```bash
milhouse ruby setup
```

This installs all recommended skills and MCP servers for Ruby/Rails development.

## Included Skills

### 1. Rails System Test Analyzer

**Repo:** https://github.com/robzolkos/skill-rails-system-test-analyzer

**Command:** `/rails-system-test-analyzer`

Evaluates Rails system tests and identifies candidates for conversion to faster controller tests. The tool analyzes code paths and JavaScript dependencies to determine which tests don't require a real browser.

**Features:**
- JavaScript detection (Turbo/Hotwire, Stimulus, event handlers)
- Code path tracing (controllers, views, partials, helpers)
- Conversion recommendations with confidence ratings
- Sample controller test templates

**Usage:**
```
/rails-system-test-analyzer
/rails-system-test-analyzer test/system/users_test.rb
```

### 2. Rails Upgrade Assistant

**Repo:** https://github.com/maquina-app/rails-upgrade-skill

**Command:** `/rails-upgrade-assistant`

Comprehensive Rails upgrade guidance from versions 7.0 through 8.1.1. Integrates with Rails MCP Server for automatic project analysis.

**Features:**
- Automatic project version detection
- Breaking change identification specific to your codebase
- Multi-hop upgrade planning (7.0→7.1→7.2→8.0→8.1)
- Custom code detection and warnings

**Supported Upgrade Paths:**
| From | To | Difficulty |
|------|-----|-----------|
| 7.0.x | 7.1.x | Medium |
| 7.1.x | 7.2.x | Medium |
| 7.2.x | 8.0.x | Hard |
| 8.0.x | 8.1.1 | Easy |

**Usage:**
```
/rails-upgrade-assistant
"Upgrade my Rails app to 8.0"
"What ActiveRecord changes are in Rails 8.0?"
```

### 3. RubyCritic Skill

**Repo:** https://github.com/esparkman/claude-rubycritic-skill

**Type:** Model-invoked (Claude automatically uses it when appropriate)

Analyzes Ruby/Rails code quality using the RubyCritic gem. Provides metrics on complexity, duplication, and code smells.

**Features:**
- Full project analysis
- Targeted path analysis
- Branch comparison
- Priority-based refactoring recommendations
- Letter grades (A-F) scoring system

**Usage (natural language):**
```
"Analyze the code quality of this project"
"Check the code quality of app/models"
"Show me the 5 worst files that need refactoring"
"Compare the code quality between this branch and main"
```

**Requires:** `gem install rubycritic`

## Included MCP Server

### Rails MCP Server

**Repo:** https://github.com/maquina-app/rails-mcp-server

**Install:** `gem install rails-mcp-server`

A Model Context Protocol server that enables Claude to interact with Rails applications through standardized tools.

**Features:**
- Multi-project management
- File and project structure browsing
- Rails route inspection with filtering
- Model information analysis (via Prism static analysis)
- Database schema exploration
- Controller-view relationship mapping
- Sandboxed Ruby code execution
- Access to Rails, Turbo, Stimulus, and Kamal documentation

**Key Tools:**
- `switch_project` - Switch between Rails projects
- `search_tools` - Discover available tools
- `execute_tool` - Run a specific tool
- `execute_ruby` - Run sandboxed Ruby code
- `project_info` - Get project information
- `list_files` - Browse project files
- `get_routes` - View Rails routes
- `analyze_models` - Analyze model relationships
- `get_schema` - View database schema

**Configuration:**
```bash
# Interactive setup
rails-mcp-config

# Or manually edit ~/.config/rails-mcp/projects.yml
```

## Installation Details

### Skills Location

Skills are installed to `~/.claude/skills/`:
- `~/.claude/skills/rails-system-test-analyzer/`
- `~/.claude/skills/rails-upgrade-assistant/`
- `~/.claude/skills/rubycritic-skill/`

### MCP Server Configuration

The rails-mcp-server is added to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "rails-mcp-server": {
      "command": "rails-mcp-server",
      "args": []
    }
  }
}
```

## Check Installation Status

```bash
milhouse ruby status
```

## Manual Installation

If you prefer to install components individually:

```bash
# Skills only
milhouse ruby skills

# MCP servers only
milhouse ruby mcp
```

Or install each tool directly:

```bash
# RubyCritic
gem install rubycritic

# Rails MCP Server
gem install rails-mcp-server
rails-mcp-config

# Skills (clone and copy to ~/.claude/skills/)
git clone https://github.com/robzolkos/skill-rails-system-test-analyzer.git
git clone https://github.com/maquina-app/rails-upgrade-skill.git
git clone https://github.com/esparkman/claude-rubycritic-skill.git
```
