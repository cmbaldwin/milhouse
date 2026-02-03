# Ralph - Autonomous AI Agent System

Ralph is an autonomous AI agent system that executes product development tasks defined in PRD (Product Requirements Document) files. It supports multiple AI backends (Claude CLI, GitHub Copilot CLI, or AMP) and can run both manually and automatically via scheduled tasks.

## Overview

Ralph works by:
1. Reading `prd.json` files to find incomplete user stories
2. Implementing one story at a time completely
3. Running quality checks (linting + tests)
4. Committing changes and updating progress
5. Continuing until all stories are complete

## Quick Start

### For a New Project

```bash
# 1. Copy the Ralph scripts to your project
mkdir -p your-project/.ralph
cd your-project/.ralph

# 2. Copy core files from this repo
cp /path/to/ralph/ralph.sh .
cp /path/to/ralph/ralph-copilot.sh .
cp /path/to/ralph/CLAUDE.md.example CLAUDE.md
cp /path/to/ralph/prd.json.example prd.json

# 3. Make scripts executable
chmod +x ralph.sh ralph-copilot.sh

# 4. Edit CLAUDE.md and prd.json for your project

# 5. Initialize progress file
echo "# Ralph Progress Log" > progress.txt
echo "Started: $(date)" >> progress.txt

# 6. Run Ralph
./ralph.sh --tool claude 15
```

## Core Files

### Scripts

- **ralph.sh** - Main Ralph agent script (supports Claude CLI and AMP backends)
- **ralph-copilot.sh** - GitHub Copilot CLI variant
- **ralph-autorun.sh** - System-wide auto-runner that finds and executes incomplete PRDs
- **ralph-autorun** - Management command for the auto-runner service

### Project Files (in your project's `.ralph/` directory)

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
cd your-project/.ralph
./ralph.sh --tool claude 25
```

**Run with GitHub Copilot CLI:**
```bash
cd your-project/.ralph
./ralph-copilot.sh 25
```

**Run with AMP:**
```bash
cd your-project/.ralph
./ralph.sh --tool amp 15
```

### Automatic Execution (Ralph Auto-Runner)

The auto-runner scans `~/dev/` for incomplete PRDs and runs Ralph automatically every hour.

**Install the auto-runner system-wide:**

```bash
# 1. Copy scripts to your bin directory
mkdir -p ~/.local/bin
cp ralph-autorun.sh ~/.local/bin/
cp ralph-autorun ~/.local/bin/
chmod +x ~/.local/bin/ralph-autorun.sh ~/.local/bin/ralph-autorun

# 2. Create LaunchAgent for macOS
cat > ~/Library/LaunchAgents/com.user.ralph-autorun.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.ralph-autorun</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/.local/bin/ralph-autorun.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Minute</key>
        <integer>1</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.ralph-autorun.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.ralph-autorun.err.log</string>
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
launchctl load ~/Library/LaunchAgents/com.user.ralph-autorun.plist
```

**Management commands:**

```bash
ralph-autorun status    # Check if running
ralph-autorun start     # Start hourly scheduler
ralph-autorun stop      # Stop scheduler
ralph-autorun restart   # Restart scheduler
ralph-autorun test      # Run manually once
ralph-autorun logs      # Show recent logs
ralph-autorun watch     # Watch logs in real-time
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
- `passes: false` - Story incomplete, Ralph should work on it
- `passes: true` - Story complete, Ralph skips it
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

## Ralph's Workflow

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
   - When all stories have `passes: true`, Ralph reports completion

## AI Backend Support

### Claude CLI (`ralph.sh --tool claude`)
- ✅ **Playwright MCP**: Full browser automation support
- ✅ **Plugin**: `playwright@claude-plugins-official`
- ✅ **Config**: `~/.claude/settings.json`

### GitHub Copilot CLI (`ralph-copilot.sh`)
- ❌ **Playwright MCP**: Not available natively
- ⚠️ **Alternative**: Can run Playwright tests via bash commands

### VS Code GitHub Copilot
- ✅ **Playwright MCP**: Built-in support
- ✅ **All browser tools**: Navigate, snapshot, console, click, etc.

### AMP (`ralph.sh --tool amp`)
- Uses `prompt.md` format
- Configure based on AMP documentation

**Recommendation:** Use `ralph.sh --tool claude` for PRDs requiring browser testing.

## Dependencies

### Required CLI Tools

```bash
# For all scripts
brew install jq              # JSON parsing

# For ralph.sh --tool claude  
brew install claude-cli      # Claude AI CLI

# For ralph-copilot.sh
gh extension install github/gh-copilot  # GitHub Copilot CLI

# Verify installations
which jq && echo "✓ jq installed"
which claude && echo "✓ claude installed"
which gh && gh copilot --version && echo "✓ gh copilot installed"
```

## Flowchart Visualization

The `flowchart/` directory contains an interactive React Flow visualization explaining how Ralph works.

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
ralph/
├── ralph.sh                    # Main agent script (multi-backend)
├── ralph-copilot.sh           # GitHub Copilot variant
├── ralph-autorun.sh           # System-wide auto-runner
├── ralph-autorun              # Management command
├── CLAUDE.md.example          # Agent instructions template
├── prd.json.example           # PRD template
├── prompt.md                  # Legacy prompt (for AMP)
├── prompt.example-rails.md    # Rails-specific example
├── AGENTS.md                  # Agent patterns and learnings
├── README.md                  # This file
├── Ralph-System-Complete-Documentation.md  # Full documentation
├── Ralph-AutoRunner-README.md # Auto-runner docs
└── flowchart/                 # Interactive visualization
```

### Your Project Structure
```
your-project/
├── .ralph/
│   ├── ralph.sh
│   ├── ralph-copilot.sh
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
   - Use descriptive branch names (feature/*, bugfix/*)
   - Ralph auto-archives when branch changes
   - Keep old PRDs in archive/ for reference

3. **Progress Tracking**
   - Update Codebase Patterns section in progress.txt
   - Document gotchas and learnings for future iterations
   - Ralph reads patterns before starting new stories

4. **Monitoring**
   - Check auto-runner logs weekly: `ralph-autorun logs`
   - Review progress.txt after each run
   - Monitor git commits for Ralph's work

5. **Manual Overrides**
   - Safe to run ralph.sh manually while auto-runner active
   - Auto-runner detects and skips if Ralph already running
   - Stop auto-runner during active development: `ralph-autorun stop`

## Troubleshooting

### Ralph Won't Start
```bash
# Check if script is executable
chmod +x .ralph/ralph.sh

# Verify dependencies
which claude jq

# Test with explicit path
/bin/bash .ralph/ralph.sh --tool claude 1
```

### Auto-Runner Not Running
```bash
# Check if loaded
launchctl list | grep ralph-autorun

# Restart service
ralph-autorun restart

# Test manually
ralph-autorun test

# Check logs
ralph-autorun logs
```

### PRD Not Found by Auto-Runner
```bash
# Verify PRD location
find ~/dev -name "prd.json" ! -path "*/archive/*"

# Check PRD has incomplete stories
jq '[.userStories[] | select(.passes == false)] | length' .ralph/prd.json
```

## Integration with GitHub

### Recommended .gitignore

```gitignore
# Ralph working files
.ralph/.last-branch
.ralph/archive/*/

# Keep these tracked:
# .ralph/ralph.sh
# .ralph/ralph-copilot.sh
# .ralph/CLAUDE.md
# .ralph/prd.json
# .ralph/progress.txt
```

### Commit Messages

Ralph automatically creates commits with format:
```
feat: US-XXX - User story title

- Bullet points of changes
- Files modified  
- Test results
```

## Resources

- **Full Documentation**: [Ralph-System-Complete-Documentation.md](Ralph-System-Complete-Documentation.md)
- **Auto-Runner Guide**: [Ralph-AutoRunner-README.md](Ralph-AutoRunner-README.md)
- **Flowchart**: [flowchart/](flowchart/)
- **Skills**: [skills/](skills/) - PRD and Ralph skill documentation

## License

MIT

## Version

**Ralph Version**: 2.0.0  
**Last Updated**: February 3, 2026  
**Tested On**: macOS (Darwin)  
**Required macOS**: 10.15+ (for LaunchAgent support)
