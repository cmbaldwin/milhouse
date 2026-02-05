# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs repeatedly until all PRD items are complete. Each iteration is a fresh agent instance with clean context.

## Core Principles

### Memory & Context

- **No persistent memory between iterations** - Each Ralph instance starts fresh
- **Memory persists via:**
  - Git commit history
  - `progress.txt` - append-only learning journal
  - `prd.json` - completion status tracking
  - `AGENTS.md` - discovered patterns for future iterations

### Task Management

- **One story at a time** - Complete implementation of single user story per iteration
- **Priority-driven** - Select highest priority incomplete story (`passes: false`)
- **Quality gates** - Must pass all checks before marking complete
- **Atomic commits** - One commit per story completion

### Learning & Patterns

- **Always update AGENTS.md** with discovered patterns for future iterations
- **Document in progress.txt** after each story completion
- **Search before coding** - Look for existing patterns in codebase
- **Follow project conventions** - Read CLAUDE.md for project-specific patterns

## Ralph Execution Flow

1. **Context Gathering**

   ```bash
   # Ralph reads these files first
   - prd.json           # Find incomplete stories
   - progress.txt       # Previous learnings
   - CLAUDE.md          # Project conventions
   - AGENTS.md          # Discovered patterns
   - git log            # Recent changes
   ```

2. **Task Selection**

   ```bash
   # Find highest priority incomplete story
   jq -r '.userStories[] | select(.passes == false) |
     [.priority, .id, .title] | @tsv' prd.json |
     sort -n | head -1
   ```

3. **Implementation**
   - Search codebase for existing patterns
   - Implement feature completely
   - Follow acceptance criteria exactly
   - Write/update tests as needed

4. **Quality Checks**

   ```bash
   # Project-specific checks (defined in CLAUDE.md)
   # Examples:
   bundle exec rubocop --autocorrect  # Ruby/Rails
   npm run lint -- --fix              # Node.js
   pytest                             # Python
   ```

5. **Documentation & Commit**

   ```bash
   # Update tracking files
   - Mark story passes: true in prd.json
   - Append learnings to progress.txt
   - Commit with standard format
   ```

6. **Stop Condition**
   - Output `<promise>COMPLETE</promise>` when all stories pass
   - Ralph loop detects this and stops

## File Formats

### prd.json Structure

```json
{
  "project": "project-name",
  "branchName": "feature/branch-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "User story description",
      "acceptanceCriteria": [
        "Specific, testable criterion 1",
        "Specific, testable criterion 2"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Additional context"
    }
  ]
}
```

### progress.txt Format

```
[YYYY-MM-DD HH:MM:SS] Story: US-XXX - Story Title
Implemented: <what was built>
Files: <list of modified files>
Tests: PASSING
Learnings:
- <reusable pattern discovered>
- <gotcha or constraint found>
---
```

### Commit Message Format

```
feat: US-XXX - User story title

- Bullet point of change 1
- Bullet point of change 2
- Files modified: file1.rb, file2.rb
- Tests: PASSING

Co-Authored-By: Ralph (Autonomous Agent) <ralph@example.com>
```

## Multi-Backend Support

Milhouse supports four AI backends:

### 1. Claude CLI (Default)

```bash
milhouse run 25
milhouse run --tool claude 25

# Features:
- Playwright MCP support (browser automation)
- Full tool access
- Preferred for browser testing
- Uses: claude --dangerously-skip-permissions --print < CLAUDE.md
```

### 2. GitHub Copilot CLI

```bash
milhouse run --tool copilot 25

# Features:
- Native GitHub integration
- Uses --allow-all for permissions
- Command: gh copilot --allow-all -p "prompt"
```

### 3. OpenCode

```bash
milhouse run --tool opencode 25

# Features:
- Open source AI coding assistant
- Command: opencode run "prompt"
```

### 4. AMP

```bash
milhouse run --tool amp 15

# Features:
- Uses prompt.md format instead of CLAUDE.md
- Command: amp --dangerously-allow-all
```

## Auto-Runner System

Ralph can run automatically every hour via `ralph-autorun`:

```bash
# Management commands
ralph-autorun status    # Check if running
ralph-autorun start     # Start hourly scheduler
ralph-autorun stop      # Stop scheduler
ralph-autorun test      # Run once manually
ralph-autorun logs      # View activity logs
ralph-autorun watch     # Watch logs in real-time
ralph-autorun config    # View or edit schedule
ralph-autorun schedule  # Show current schedule status
```

**How it works:**

1. Scans `~/dev/` for `.ralph/prd.json` files
2. Checks if current time is within operating hours
3. Finds first PRD with incomplete stories
4. Runs `ralph.sh --tool claude 15` in that directory
5. Logs all activity to `~/.ralph-autorun.log`
6. Runs every hour at :01 past (12:01, 13:01, etc.)

**Schedule configuration:**

By default, Ralph only runs from 9 PM to 7 AM (overnight) to avoid interfering with work hours. Configure in `~/.ralph-autorun.conf`:

```bash
# OFF hours (Ralph will NOT run during these times)
OFF_START_HOUR=7   # 7 AM
OFF_END_HOUR=21    # 9 PM
```

Times are in 24-hour format in your local timezone.

## Best Practices

### Story Writing

- **Atomic stories** - Each story should be independently completable
- **Clear acceptance criteria** - Testable, specific requirements
- **Priority ordering** - Use numeric priority (1 = highest)
- **Browser testing** - Include "Verify in browser using dev-browser skill" if UI changes

### Implementation Patterns

- **Search first** - Look for similar implementations in codebase
- **Follow conventions** - Match existing code style and patterns
- **Test coverage** - Write tests for new functionality
- **Quality first** - Never commit broken code

### Progress Tracking

- **Update AGENTS.md** - Document new patterns discovered
- **Detailed progress.txt** - Help future iterations understand context
- **Git commits** - One commit per completed story
- **Archive on branch change** - Old PRDs auto-archived to `archive/`

### Error Handling

- **Quality check failures** - Fix issues, don't skip
- **Rate limits** - Ralph waits and retries automatically
- **Incomplete stories** - Ralph continues from where it left off
- **Branch switches** - Automatically archives current PRD

## Discovered Patterns

### Pattern: Browser Testing with Playwright MCP

When acceptance criteria includes "Verify in browser":

```bash
# Use Claude CLI backend for Playwright MCP support
./ralph.sh --tool claude 25

# Ralph can then use browser automation:
- Navigate to pages
- Take screenshots
- Click elements
- Fill forms
- Verify DOM state
```

### Pattern: Archiving Completed PRDs

Ralph auto-archives when branch changes:

```bash
# Archives to: .ralph/archive/YYYY-MM-DD-branch-name/
- prd.json
- progress.txt
```

### Pattern: Concurrent Run Prevention

Auto-runner detects if Ralph already running:

```bash
# In ralph-autorun.sh:
if pgrep -f "ralph.sh" > /dev/null; then
  echo "Ralph already running, skipping"
  exit 0
fi
```

### Pattern: Multi-Project Management

Auto-runner handles multiple projects:

```bash
# Searches all of ~/dev/ recursively
find ~/dev -name "prd.json" ! -path "*/archive/*"

# Runs first incomplete PRD found
# Only one Ralph instance at a time
```

## Troubleshooting

### Ralph won't start

```bash
# Check permissions
chmod +x ralph.sh ralph-copilot.sh

# Verify dependencies
which jq claude gh

# Test explicitly
/bin/bash ralph.sh --tool claude 1
```

### Stories not progressing

```bash
# Check quality check commands in CLAUDE.md
# Verify tests pass locally
# Review progress.txt for errors
tail -50 progress.txt
```

### Auto-runner not finding PRD

```bash
# Verify PRD location
find ~/dev -name "prd.json" ! -path "*/archive/*"

# Check incomplete stories exist
jq '[.userStories[] | select(.passes == false)] | length' prd.json

# Test auto-runner manually
ralph-autorun test
```
