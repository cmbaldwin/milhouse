# Ralph Agent System - Complete Documentation

**Purpose:** Documentation for adding Ralph autonomous agent system to a GitHub repository.

## Overview

Ralph is an autonomous AI agent system that executes product development tasks defined in PRD (Product Requirements Document) files. It supports multiple AI backends (Claude CLI, GitHub Copilot CLIz, or AMP) and can run both manually and automatically via scheduled tasks.

---

## System Components

### 1. Ralph Agent Scripts (Project-Specific)

Located in: `<project>/.ralph/`

#### 1.1 ralph.sh (Multi-Backend)

**File Path:** `/Users/cody/Dev/oroshi-moab/.ralph/ralph.sh`

**Purpose:** Main Ralph agent script supporting multiple AI backends (Claude, AMP)

**Usage:**

```bash
./ralph.sh [--tool claude|amp] [max_iterations]

# Examples:
./ralph.sh                           # Default: claude, 10 iterations
./ralph.sh --tool claude 25          # Claude, 25 iterations
./ralph.sh --tool amp 15             # AMP, 15 iterations
```

**Features:**

- Supports Claude CLI (`claude --print`) and AMP backends
- Reads instructions from `CLAUDE.md` (Claude) or `prompt.md` (AMP)
- Executes PRD user stories sequentially
- Archives completed PRDs when branch changes
- Tracks progress in `progress.txt`
- Updates `prd.json` with completion status
- Stops when all stories complete or max iterations reached

**Dependencies:**

- `jq` (JSON parsing)
- `claude` CLI or `amp` CLI (depending on --tool flag)

**Key Files It Uses:**

- `prd.json` - Product requirements with user stories
- `CLAUDE.md` - Agent instructions and conventions
- `progress.txt` - Execution log and learnings
- `.last-branch` - Tracks current branch for archiving

#### 1.2 ralph-copilot.sh (GitHub Copilot Specific)

**File Path:** `/Users/cody/Dev/oroshi-moab/.ralph/ralph-copilot.sh`

**Purpose:** Ralph agent script specifically for GitHub Copilot CLI

**Usage:**

```bash
./ralph-copilot.sh [max_iterations]

# Examples:
./ralph-copilot.sh           # Default: 10 iterations
./ralph-copilot.sh 25        # 25 iterations
```

**Key Differences from ralph.sh:**

- Uses `gh copilot -p` instead of `claude --print`
- Uses `--allow-all` for permissions (vs `--dangerously-skip-permissions`)
- Uses `--add-dir` to grant file access to parent directories
- Simplified argument parsing (no --tool flag)

**Dependencies:**

- `jq` (JSON parsing)
- `gh` (GitHub CLI)
- `gh copilot` extension

**Configuration:**

```bash
# Grants access to project directories
--add-dir "$SCRIPT_DIR/.."              # Parent project
--add-dir "$SCRIPT_DIR/../../oroshi"    # Sibling oroshi gem
```

---

### 2. Ralph Auto-Runner (System-Wide)

Automatically runs Ralph agents on incomplete PRDs every hour.

#### 2.1 Main Auto-Runner Script

**File Path:** `/Users/cody/.local/bin/ralph-autorun.sh`

**Purpose:** Scans `~/dev/` for incomplete PRDs and runs ralph.sh automatically

**What It Does:**

1. Finds all `prd.json` files in `~/dev/` (excluding archives)
2. Checks each for incomplete stories (`passes: false`)
3. Runs `ralph.sh --tool claude 15` in first incomplete PRD found
4. Skips if Ralph is already running
5. Logs all activity

**Configuration:**

- Search path: `~/dev/` (recursive)
- Excludes: `*/archive/*` and `*/.git/*`
- Iterations: 15 per run
- Backend: Claude (default)
- Log file: `~/.ralph-autorun.log`

#### 2.2 Management Command

**File Path:** `/Users/cody/.local/bin/ralph-autorun`

**Purpose:** Control the auto-runner service

**Commands:**

```bash
ralph-autorun status    # Check if running
ralph-autorun start     # Start hourly scheduler
ralph-autorun stop      # Stop scheduler
ralph-autorun restart   # Restart scheduler
ralph-autorun test      # Run manually once
ralph-autorun logs      # Show recent logs
ralph-autorun watch     # Watch logs in real-time
```

#### 2.3 LaunchAgent (macOS Scheduler)

**File Path:** `/Users/cody/Library/LaunchAgents/com.user.ralph-autorun.plist`

**Purpose:** macOS system scheduler for hourly execution

**Schedule:** Every hour at 1 minute past (12:01, 13:01, 14:01, etc.)

**Configuration:**

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Minute</key>
    <integer>1</integer>
</dict>
```

**Features:**

- Runs even after computer sleep (catches up on wake)
- Logs to `~/.ralph-autorun.out.log` and `~/.ralph-autorun.err.log`
- Sets PATH to include common binary locations
- Working directory: `~/dev/`

**Control Commands:**

```bash
# Load (start)
launchctl load ~/Library/LaunchAgents/com.user.ralph-autorun.plist

# Unload (stop)
launchctl unload ~/Library/LaunchAgents/com.user.ralph-autorun.plist

# Check status
launchctl list | grep ralph-autorun
```

---

## Project Structure

### Required Files in `.ralph/` Directory

```
<project>/.ralph/
├── ralph.sh              # Main agent script (multi-backend)
├── ralph-copilot.sh      # GitHub Copilot variant
├── CLAUDE.md             # Agent instructions and conventions
├── prd.json              # Product requirements document
├── progress.txt          # Execution log and learnings
├── .last-branch          # Branch tracking for archiving
└── archive/              # Archived completed PRDs
    └── YYYY-MM-DD-branch-name/
        ├── prd.json
        └── progress.txt
```

### PRD File Structure (prd.json)

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

### CLAUDE.md Structure

Must include:

- Project context and tech stack
- Task execution instructions
- Quality check commands
- Progress report format
- Codebase patterns and conventions
- Stop condition (`<promise>COMPLETE</promise>`)

---

## Installation Instructions

### For a New Project

1. **Create .ralph directory:**

```bash
mkdir -p <project>/.ralph
cd <project>/.ralph
```

2. **Copy agent scripts:**

```bash
# From this project
cp /Users/cody/Dev/oroshi-moab/.ralph/ralph.sh .
cp /Users/cody/Dev/oroshi-moab/.ralph/ralph-copilot.sh .
chmod +x ralph.sh ralph-copilot.sh
```

3. **Create CLAUDE.md:**

```bash
# Copy template and customize
cp /Users/cody/Dev/oroshi-moab/.ralph/CLAUDE.md .
# Edit to match your project's patterns
```

4. **Create initial PRD:**

```bash
# Create prd.json with your user stories
cat > prd.json << 'EOF'
{
  "project": "your-project-name",
  "branchName": "feature/your-feature",
  "description": "Project description",
  "userStories": []
}
EOF
```

5. **Initialize progress file:**

```bash
cat > progress.txt << 'EOF'
# Ralph Progress Log
Started: $(date)
---

## Codebase Patterns
- Add project-specific patterns here
---
EOF
```

### System-Wide Auto-Runner (Already Installed)

The auto-runner is already installed system-wide and will automatically discover new projects in `~/dev/`.

**Files installed:**

- `/Users/cody/.local/bin/ralph-autorun.sh` - Main script
- `/Users/cody/.local/bin/ralph-autorun` - Management command
- `/Users/cody/Library/LaunchAgents/com.user.ralph-autorun.plist` - Scheduler

**No additional setup needed** - just place a `.ralph/` folder with `prd.json` in any project under `~/dev/`

---

## Usage Examples

### Manual Execution

**Run Ralph with Claude (recommended for Playwright MCP support):**

```bash
cd /Users/cody/Dev/oroshi-moab/.ralph
./ralph.sh --tool claude 25
```

**Run Ralph with GitHub Copilot:**

```bash
cd /Users/cody/Dev/oroshi-moab/.ralph
./ralph-copilot.sh 25
```

**Monitor Progress:**

```bash
# Watch PRD updates
watch -n 5 'jq ".userStories[] | {id, title, passes}" prd.json'

# Follow progress log
tail -f progress.txt

# Count remaining stories
jq '[.userStories[] | select(.passes == false)] | length' prd.json
```

### Automatic Execution

**Check auto-runner status:**

```bash
ralph-autorun status
```

**Watch auto-runner in real-time:**

```bash
ralph-autorun watch
```

**Test auto-runner manually:**

```bash
ralph-autorun test
```

**View logs:**

```bash
ralph-autorun logs
# Or directly:
tail -f ~/.ralph-autorun.log
```

---

## MCP Tool Support

### Claude CLI (ralph.sh --tool claude)

- ✅ **Playwright MCP**: Full browser automation support
- ✅ **Plugin**: `playwright@claude-plugins-official`
- ✅ **Config**: `~/.claude/settings.json`

### GitHub Copilot CLI (ralph-copilot.sh)

- ❌ **Playwright MCP**: Not available natively
- ⚠️ **Alternative**: Can run Playwright tests via bash commands
- ℹ️ **Limitation**: No interactive browser automation

### VS Code GitHub Copilot

- ✅ **Playwright MCP**: Built-in support
- ✅ **All browser tools**: Navigate, snapshot, console, click, etc.

**Recommendation:** Use `ralph.sh --tool claude` for PRDs requiring browser testing.

---

## File Paths Reference

### Project Files (oroshi-moab)

```
/Users/cody/Dev/oroshi-moab/.ralph/
├── ralph.sh
├── ralph-copilot.sh
├── CLAUDE.md
├── prd.json
├── progress.txt
├── PLAYWRIGHT_SETUP.md
├── .last-branch
└── archive/
    └── 2026-02-03-demo-showcase/
        ├── prd.json
        └── progress.txt
```

### System-Wide Files

```
/Users/cody/.local/bin/
├── ralph-autorun.sh
└── ralph-autorun

/Users/cody/.local/share/ralph-autorun/
└── README.md

/Users/cody/Library/LaunchAgents/
└── com.user.ralph-autorun.plist

/Users/cody/
├── .ralph-autorun.log
├── .ralph-autorun.out.log
└── .ralph-autorun.err.log
```

### Desktop Reference

```
/Users/cody/Desktop/Ralph-AutoRunner-README.md
```

---

## Dependencies

### Required CLI Tools

```bash
# For all scripts
brew install jq              # JSON parsing

# For ralph.sh --tool claude
brew install claude-cli      # Claude AI CLI

# For ralph-copilot.sh
gh extension install github/gh-copilot  # GitHub Copilot CLI

# For AMP (optional)
# Install AMP CLI as per their documentation
```

### Verification

```bash
# Check installations
which jq && echo "✓ jq installed"
which claude && echo "✓ claude installed"
which gh && gh copilot --version && echo "✓ gh copilot installed"
```

---

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

### Rate Limit Errors

- Claude CLI has rate limits
- Auto-runner will retry next hour automatically
- Can run manually with longer sleep between iterations

### PRD Not Found by Auto-Runner

```bash
# Verify PRD location
find ~/dev -name "prd.json" ! -path "*/archive/*"

# Check PRD has incomplete stories
jq '[.userStories[] | select(.passes == false)] | length' <project>/.ralph/prd.json
```

---

## Advanced Configuration

### Custom Auto-Runner Schedule

Edit LaunchAgent plist:

```bash
nano ~/Library/LaunchAgents/com.user.ralph-autorun.plist

# Change Minute value (currently 1):
<key>Minute</key>
<integer>1</integer>

# Then reload:
ralph-autorun restart
```

### Multiple Projects

Auto-runner automatically handles multiple projects:

- Searches all of `~/dev/` recursively
- Runs first incomplete PRD found
- Only one Ralph instance at a time
- Next run will pick up next incomplete PRD

### Custom Iteration Count

Edit auto-runner script:

```bash
nano /Users/cody/.local/bin/ralph-autorun.sh

# Find line:
"$RALPH_SCRIPT" --tool claude 15

# Change 15 to desired number
```

---

## Best Practices

### 1. PRD Structure

- Keep user stories atomic and testable
- Include clear acceptance criteria
- Add browser testing instructions if needed
- Document learnings in progress.txt

### 2. Branch Management

- Use descriptive branch names (feature/_, bugfix/_)
- Ralph auto-archives when branch changes
- Keep old PRDs in archive/ for reference

### 3. Progress Tracking

- Update Codebase Patterns section in progress.txt
- Document gotchas and learnings for future iterations
- Ralph reads patterns before starting new stories

### 4. Monitoring

- Check auto-runner logs weekly: `ralph-autorun logs`
- Review progress.txt after each run
- Monitor git commits for Ralph's work

### 5. Manual Overrides

- Safe to run ralph.sh manually while auto-runner active
- Auto-runner detects and skips if Ralph already running
- Stop auto-runner during active development: `ralph-autorun stop`

---

## Integration with GitHub

### Recommended Repository Structure

```
your-repo/
├── .ralph/
│   ├── ralph.sh
│   ├── ralph-copilot.sh
│   ├── CLAUDE.md
│   ├── prd.json
│   ├── progress.txt
│   └── README.md (this file)
├── .gitignore
└── [your project files]
```

### .gitignore Additions

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

---

## License & Credits

- Ralph agent system by Anthropic/Claude
- Auto-runner system by [your organization]
- macOS LaunchAgent pattern standard
- GitHub Copilot CLI integration by GitHub

---

## Support & Maintenance

### Logs Location

- Main log: `~/.ralph-autorun.log`
- Stdout: `~/.ralph-autorun.out.log`
- Stderr: `~/.ralph-autorun.err.log`

### Commands Quick Reference

```bash
# Status
ralph-autorun status

# View logs
ralph-autorun logs
ralph-autorun watch

# Control
ralph-autorun start
ralph-autorun stop
ralph-autorun restart

# Test
ralph-autorun test

# Manual run
cd <project>/.ralph && ./ralph.sh --tool claude 15
```

---

## Version Information

- **Ralph Scripts Version**: 1.0.0
- **Auto-Runner Version**: 1.0.0
- **Last Updated**: 2026-02-03
- **Tested On**: macOS (Darwin)
- **Required macOS**: 10.15+ (for LaunchAgent support)

---

**End of Documentation**
