# Milhouse - Autonomous AI Agent System

Milhouse is an autonomous AI agent system that executes product development tasks defined in PRD (Product Requirements Document) files. It supports multiple AI backends (Claude CLI, GitHub Copilot CLI, or AMP) and can run both manually and automatically via scheduled tasks.

## Overview

Milhouse works by:

1. Reading `prd.json` files to find incomplete user stories
2. Implementing one story at a time completely
3. Running quality checks (linting + tests)
4. Committing changes and updating progress
5. Continuing until all stories are complete

## Installation

### Quick Install

```bash
git clone https://github.com/cmbaldwin/milhouse.git
cd milhouse
./install.sh
```

### Verify Installation

```bash
milhouse version
milhouse help
```

### Setup a Project

```bash
cd your-project
milhouse install
```

This creates:

- `.milhouse/` directory
- `CLAUDE.md` template
- `prd.json` template
- qmd collection for your project

### Enable Auto-Runner

```bash
milhouse autorun start
```

The auto-runner will check for incomplete PRDs every hour during configured hours (default: 9 PM - 7 AM).

## Quick Start

### Running Milhouse

```bash
cd your-project
milhouse run
```

## Core Files

### Scripts

- **milhouse.sh** - Main Milhouse agent script (supports Claude CLI and AMP backends)
- **milhouse-copilot.sh** - GitHub Copilot CLI variant
- **milhouse-autorun.sh** - System-wide auto-runner that finds and executes incomplete PRDs
- **milhouse-autorun** - Management command for the auto-runner service

### Project Files (in your project's `.milhouse/` directory)

- **CLAUDE.md** - Agent instructions, conventions, and quality check commands
- **prd.json** - Product requirements with user stories and completion status
- **progress.txt** - Append-only learning journal documenting completed work
- **.last-branch** - Tracks current branch for auto-archiving completed PRDs

### Examples

- **CLAUDE.md.example** - Template for agent instructions
- **prd.json.example** - Template PRD structure
- **prompt.md** - Legacy prompt format (for reference)
- **prompt.example-rails.md** - Rails-specific example

## Usage

### Manual Execution

**Run with Claude CLI (recommended for Playwright MCP support):**

```bash
cd your-project/.milhouse
./milhouse.sh --tool claude 25
```

**Run with GitHub Copilot CLI:**

```bash
cd your-project/.milhouse
./milhouse-copilot.sh 25
```

**Run with AMP:**

```bash
cd your-project/.milhouse
./milhouse.sh --tool amp 15
```

### Automatic Execution (Milhouse Auto-Runner)

The auto-runner scans `~/dev/` for incomplete PRDs and runs Milhouse automatically every hour.

**Install the auto-runner system-wide:**

```bash
# 1. Copy scripts to your bin directory
mkdir -p ~/.local/bin
cp milhouse-autorun.sh ~/.local/bin/
cp milhouse-autorun ~/.local/bin/
chmod +x ~/.local/bin/milhouse-autorun.sh ~/.local/bin/milhouse-autorun

# 2. Create LaunchAgent for macOS
cat > ~/Library/LaunchAgents/com.user.milhouse-autorun.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.milhouse-autorun</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/.local/bin/milhouse-autorun.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>1</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.milhouse-autorun.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.milhouse-autorun.err.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
    <key>WorkingDirectory</key>
    <string>/Users/YOUR_USERNAME/dev</string>
</dict>
</plist>
EOF

# 3. Replace YOUR_USERNAME with your actual username
# 4. Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.milhouse-autorun.plist
```

**Management commands:**

```bash
milhouse-autorun status    # Check if running
milhouse-autorun start     # Start hourly scheduler
milhouse-autorun stop      # Stop scheduler
milhouse-autorun restart   # Restart scheduler
milhouse-autorun test      # Run manually once
milhouse-autorun logs      # Show recent logs
milhouse-autorun watch     # Watch logs in real-time
```

### Monitor Progress

```bash
# View completion status
cat prd.json | jq '.userStories[] | select(.passes == true) | .title'

# View remaining tasks
cat prd.json | jq '.userStories[] | select(.passes == false) | {id, title, priority}'

# Recent learnings
tail -n 50 progress.txt

# Watch PRD updates
watch -n 5 'jq ".userStories[] | {id, title, passes}" prd.json'
```

## PRD Structure (prd.json)

```json
{
  "project": "project-name",
  "branchName": "feature/branch-name",
  "description": "Project description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "What needs to be done",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Key Fields:**

- `passes: false` - Story incomplete, Milhouse should work on it
- `passes: true` - Story complete, Milhouse skips it
- `priority` - Lower numbers = higher priority (1 is highest)

## CLAUDE.md Structure

Your `CLAUDE.md` file must include:

- Project context and tech stack
- Task execution instructions
- Quality check commands
- Progress report format
- Codebase patterns and conventions
- Stop condition (`<promise>COMPLETE</promise>`)

See [CLAUDE.md.example](CLAUDE.md.example) for a complete template.

## Milhouse's Workflow

1. **Context Gathering**
   - Reads `prd.json` for tasks
   - Reads `progress.txt` for learnings
   - Reviews git history
   - Checks `AGENTS.md` files for patterns

2. **Task Selection**
   - Finds highest-priority story where `passes: false`
   - Works on ONE story at a time

3. **Implementation**
   - Searches codebase for existing patterns
   - Follows project conventions
   - Implements feature completely

4. **Quality Gates**
   - Runs project-specific linting
   - Runs project-specific tests
   - Must pass before committing

5. **Documentation**
   - Commits changes with proper format
   - Updates story to `passes: true` in prd.json
   - Appends learnings to progress.txt

6. **Complete**
   - When all stories have `passes: true`, Milhouse reports completion

## Ruby/Rails Defaults

Milhouse is an opinionated Ruby AI automation tool. It includes curated skills and MCP servers for Ruby/Rails development.

### Quick Setup

```bash
milhouse ruby setup
```

### Included Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [Rails System Test Analyzer](https://github.com/robzolkos/skill-rails-system-test-analyzer) | `/rails-system-test-analyzer` | Analyze system tests for conversion to faster controller tests |
| [Rails Upgrade Assistant](https://github.com/maquina-app/rails-upgrade-skill) | `/rails-upgrade-assistant` | Upgrade Rails 7.0→8.1.1 with guided analysis |
| [RubyCritic](https://github.com/esparkman/claude-rubycritic-skill) | (model-invoked) | Analyze code quality, complexity, and smells |

### Included MCP Server

| Server | Description |
|--------|-------------|
| [rails-mcp-server](https://github.com/maquina-app/rails-mcp-server) | Rails project tools: routes, models, schema, code execution |

### Usage Examples

**Analyze system tests:**

```text
/rails-system-test-analyzer test/system/users_test.rb
```

**Upgrade Rails:**

```text
/rails-upgrade-assistant
"Upgrade my Rails app to 8.0"
```

**Analyze code quality:**

```text
"Analyze the code quality of app/models"
"Show me the 5 worst files that need refactoring"
```

**Rails MCP tools (available automatically):**

- `get_routes` - View Rails routes
- `analyze_models` - Analyze model relationships
- `get_schema` - View database schema
- `execute_ruby` - Run sandboxed Ruby code

### Check Status

```bash
milhouse ruby status
```

See [defaults/ruby/README.md](defaults/ruby/README.md) for full documentation.

## AI Backend Support

### Claude CLI (`milhouse.sh --tool claude`)

- ✅ **Playwright MCP**: Full browser automation support
- ✅ **Plugin**: `playwright@claude-plugins-official`
- ✅ **Config**: `~/.claude/settings.json`

### GitHub Copilot CLI (`milhouse-copilot.sh`)

- ❌ **Playwright MCP**: Not available natively
- ⚠️ **Alternative**: Can run Playwright tests via bash commands

### VS Code GitHub Copilot

- ✅ **Playwright MCP**: Built-in support
- ✅ **All browser tools**: Navigate, snapshot, console, click, etc.

### AMP (`milhouse.sh --tool amp`)

- Uses `prompt.md` format
- Configure based on AMP documentation

**Recommendation:** Use `milhouse.sh --tool claude` for PRDs requiring browser testing.

## Dependencies

### Required CLI Tools

```bash
# For all scripts
brew install jq              # JSON parsing

# For milhouse.sh --tool claude
brew install claude-cli      # Claude AI CLI

# For milhouse-copilot.sh
gh extension install github/gh-copilot  # GitHub Copilot CLI

# Verify installations
which jq && echo "✓ jq installed"
which claude && echo "✓ claude installed"
which gh && gh copilot --version && echo "✓ gh copilot installed"
```

## Flowchart Visualization

The `flowchart/` directory contains an interactive React Flow visualization explaining how Milhouse works.

**Run locally:**

```bash
cd flowchart
npm install
npm run dev
```

**Build for production:**

```bash
cd flowchart
npm run build
```

## Project Structure

### This Repository

```
milhouse/
├── milhouse.sh                    # Main agent script (multi-backend)
├── milhouse-copilot.sh           # GitHub Copilot variant
├── milhouse-autorun.sh           # System-wide auto-runner
├── milhouse-autorun              # Management command
├── CLAUDE.md.example          # Agent instructions template
├── prd.json.example           # PRD template
├── prompt.md                  # Legacy prompt (for AMP)
├── prompt.example-rails.md    # Rails-specific example
├── AGENTS.md                  # Agent patterns and learnings
├── README.md                  # This file
├── Milhouse-System-Complete-Documentation.md  # Full documentation
├── Milhouse-AutoRunner-README.md # Auto-runner docs
└── flowchart/                 # Interactive visualization
```

### Your Project Structure

```
your-project/
├── .milhouse/
│   ├── milhouse.sh
│   ├── milhouse-copilot.sh
│   ├── CLAUDE.md
│   ├── prd.json
│   ├── progress.txt
│   ├── .last-branch
│   └── archive/
│       └── YYYY-MM-DD-branch-name/
│           ├── prd.json
│           └── progress.txt
└── [your project files]
```

## Best Practices

1. **PRD Structure**
   - Keep user stories atomic and testable
   - Include clear acceptance criteria
   - Add browser testing instructions if needed
   - Document learnings in progress.txt

2. **Branch Management**
   - Use descriptive branch names (feature/_, bugfix/_)
   - Milhouse auto-archives when branch changes
   - Keep old PRDs in archive/ for reference

3. **Progress Tracking**
   - Update Codebase Patterns section in progress.txt
   - Document gotchas and learnings for future iterations
   - Milhouse reads patterns before starting new stories

4. **Monitoring**
   - Check auto-runner logs weekly: `milhouse-autorun logs`
   - Review progress.txt after each run
   - Monitor git commits for Milhouse's work

5. **Manual Overrides**
   - Safe to run milhouse.sh manually while auto-runner active
   - Auto-runner detects and skips if Milhouse already running
   - Stop auto-runner during active development: `milhouse-autorun stop`

## Troubleshooting

### Milhouse Won't Start

```bash
# Check if script is executable
chmod +x .milhouse/milhouse.sh

# Verify dependencies
which claude jq

# Test with explicit path
/bin/bash .milhouse/milhouse.sh --tool claude 1
```

### Auto-Runner Not Running

```bash
# Check if loaded
launchctl list | grep milhouse-autorun

# Restart service
milhouse-autorun restart

# Test manually
milhouse-autorun test

# Check logs
milhouse-autorun logs
```

### PRD Not Found by Auto-Runner

```bash
# Verify PRD location
find ~/dev -name "prd.json" ! -path "*/archive/*"

# Check PRD has incomplete stories
jq '[.userStories[] | select(.passes == false)] | length' .milhouse/prd.json
```

## Integration with GitHub

### Recommended .gitignore

```gitignore
# Milhouse working files
.milhouse/.last-branch
.milhouse/archive/*/

# Keep these tracked:
# .milhouse/milhouse.sh
# .milhouse/milhouse-copilot.sh
# .milhouse/CLAUDE.md
# .milhouse/prd.json
# .milhouse/progress.txt
```

### Commit Messages

Milhouse automatically creates commits with format:

```
feat: US-XXX - User story title

- Bullet points of changes
- Files modified
- Test results
```

## Resources

- **Full Documentation**: [Milhouse-System-Complete-Documentation.md](Milhouse-System-Complete-Documentation.md)
- **Auto-Runner Guide**: [Milhouse-AutoRunner-README.md](Milhouse-AutoRunner-README.md)
- **Flowchart**: [flowchart/](flowchart/)
- **Skills**: [skills/](skills/) - PRD and Milhouse skill documentation

## License

MIT

## Version

**Milhouse Version**: 2.0.0  
**Last Updated**: February 3, 2026  
**Tested On**: macOS (Darwin)  
**Required macOS**: 10.15+ (for LaunchAgent support)
