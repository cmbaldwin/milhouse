# Ralph Project - AI Agent Instructions

## Project Overview

Ralph is an autonomous AI agent system that executes product development tasks defined in PRD (Product Requirements Document) files. It supports multiple AI backends (Claude CLI, GitHub Copilot CLI, AMP) and can run both manually and automatically via scheduled tasks.

**Repository**: `/Users/cody/Dev/ralph`

## Documentation Search with qmd

This project is indexed with **qmd** for fast documentation search. Use this FIRST before making changes or when you need context.

### When to Use qmd

**ALWAYS search documentation before:**
- Making changes to core scripts (ralph.sh, ralph-autorun.sh, etc.)
- Answering questions about how Ralph works
- Understanding system architecture or design decisions
- Finding examples of similar functionality
- Checking existing conventions or patterns

### How to Search

**Keyword search (fast, default):**
```bash
qmd search "AutoRunner" -c ralph
qmd search "PRD structure" -c ralph
qmd search "branch management" -c ralph
```

**Get specific documents:**
```bash
qmd get qmd://ralph/readme.md
qmd get qmd://ralph/ralph-autorunner-readme.md
```

**List all documentation:**
```bash
qmd ls ralph
```

### Available Documentation

The `ralph` qmd collection includes:
- **readme.md** - Main system documentation
- **ralph-autorunner-readme.md** - Auto-runner configuration and usage
- **ralph-system-complete-documentation.md** - Complete system reference
- **agents.md** - Agent behavior and patterns
- **skills/prd/skill.md** - PRD management skill
- **skills/ralph/skill.md** - Ralph workflow skill
- **prompt.md** - Legacy prompt format
- **prompt-example-rails.md** - Rails-specific example

### Search Workflow

1. **Before any code changes:**
   ```bash
   qmd search "relevant keywords" -c ralph
   ```

2. **Review the results** - Read the relevant sections

3. **Get full documents if needed:**
   ```bash
   qmd get qmd://ralph/path/to/file.md
   ```

4. **Make informed changes** based on existing patterns

## Project Structure

```
ralph/
├── ralph.sh                           # Main agent script (multi-backend)
├── ralph-copilot.sh                   # GitHub Copilot CLI variant
├── ralph-autorun.sh                   # Auto-runner daemon script
├── ralph-autorun                      # Auto-runner management CLI
├── CLAUDE.md                          # This file
├── README.md                          # Main documentation
├── Ralph-AutoRunner-README.md         # Auto-runner docs
├── agents.md                          # Agent patterns
├── skills/                            # Skill definitions
│   ├── prd/SKILL.md                  # PRD management
│   └── ralph/SKILL.md                # Ralph workflow
└── flowchart/                         # Interactive visualization
    ├── src/                          # React Flow app
    └── README.md                     # Visualization docs
```

## Core Concepts

### PRD Files (prd.json)
- Located in `your-project/.ralph/prd.json`
- Contains user stories with `passes` boolean field
- Ralph processes stories where `passes: false`
- Updates `passes: true` when complete

### CLAUDE.md Files
- Project-specific agent instructions
- Located in `your-project/.ralph/CLAUDE.md`
- Defines quality checks, conventions, tech stack
- Used by ralph.sh to generate prompts

### Progress Tracking
- `progress.txt` - Append-only learning journal
- Documents what was completed each run
- Helps agents learn from previous work

### Auto-Runner
- System-wide service (macOS LaunchAgent)
- Scans `~/dev/**/.ralph/prd.json` hourly
- Runs Ralph on first incomplete PRD found
- Configurable operating hours (default: 9 PM - 7 AM)
- Managed via `ralph-autorun` command

## Development Guidelines

### Making Changes to Ralph

1. **Search documentation first:**
   ```bash
   qmd search "topic" -c ralph
   ```

2. **Understand existing patterns** - Read relevant docs

3. **Test locally** before committing

4. **Update documentation** if changing core functionality

5. **Keep commit messages descriptive**

### Code Style

- **Bash scripts**: Follow existing patterns in ralph.sh
- **Use oroshi patterns**: Check oroshi integration in codebase
- **Configuration**: Support both env vars and config files
- **Logging**: Log important events with timestamps
- **Error handling**: Capture errors and provide helpful messages

### Testing Changes

**Test ralph.sh:**
```bash
cd /Users/cody/Dev/ralph
./ralph.sh --help
```

**Test auto-runner:**
```bash
ralph-autorun test  # Dry run
ralph-autorun logs  # Check recent activity
```

**Verify qmd index is current:**
```bash
qmd status
qmd search "test query" -c ralph
```

## Common Tasks

### Updating Documentation

When you modify README.md, Ralph-AutoRunner-README.md, or other markdown files:

1. **Update the qmd index:**
   ```bash
   qmd update
   ```

2. **Verify the changes are indexed:**
   ```bash
   qmd search "new content" -c ralph
   ```

### Adding New Features

1. **Search for similar features:**
   ```bash
   qmd search "feature name" -c ralph
   ```

2. **Follow existing patterns** found in documentation

3. **Update relevant documentation** (README.md, etc.)

4. **Update qmd index:**
   ```bash
   qmd update
   ```

### Troubleshooting

**If qmd returns no results:**
- Check collection status: `qmd status`
- Update index: `qmd update`
- List files: `qmd ls ralph`

**If changes aren't reflected:**
- The qmd index updates on `qmd update`
- Run it after modifying markdown files

## Best Practices

### For AI Agents Working on Ralph

1. ✅ **DO** search qmd before making changes
2. ✅ **DO** read existing documentation thoroughly
3. ✅ **DO** follow established patterns and conventions
4. ✅ **DO** update documentation when adding features
5. ✅ **DO** test changes before committing

6. ❌ **DON'T** modify core scripts without understanding the full system
7. ❌ **DON'T** skip searching documentation
8. ❌ **DON'T** introduce breaking changes to stable interfaces
9. ❌ **DON'T** forget to update qmd index after doc changes

### Documentation-First Workflow

```
1. Search qmd → 2. Read docs → 3. Understand context → 4. Make changes → 5. Update docs → 6. Update qmd
```

## Quick Reference

### qmd Commands
```bash
qmd search "query" -c ralph          # Search ralph docs (fast)
qmd ls ralph                         # List all files
qmd get qmd://ralph/readme.md        # Get specific file
qmd status                           # Check index status
qmd update                           # Update index after doc changes
```

### Ralph Commands
```bash
ralph-autorun status                 # Check auto-runner status
ralph-autorun logs                   # View recent activity
ralph-autorun schedule               # Show operating hours
ralph-autorun test                   # Dry run (doesn't execute)
```

### File Locations
- Ralph repo: `/Users/cody/Dev/ralph`
- Auto-runner config: `~/.ralph-autorun.conf`
- Auto-runner logs: `~/.ralph-autorun.log`
- qmd index: `~/.cache/qmd/index.sqlite`
- Skills directory: `~/.claude/skills/`

## Emergency Contacts / References

- Main documentation: [README.md](README.md)
- Auto-runner docs: [Ralph-AutoRunner-README.md](Ralph-AutoRunner-README.md)
- System reference: [Ralph-System-Complete-Documentation.md](Ralph-System-Complete-Documentation.md)
- qmd skill: `~/.claude/skills/qmd.md`

---

**Remember**: Search documentation with qmd BEFORE making changes. The documentation contains crucial context about how the system works and why design decisions were made.
