# Milhouse Project - AI Agent Instructions

## Project Overview

Milhouse is an autonomous AI agent system that executes product development tasks defined in PRD (Product Requirements Document) files. It supports multiple AI backends (Claude CLI, GitHub Copilot CLI, AMP) and can run both manually and automatically via scheduled tasks.

**Repository**: `/Users/cody/Dev/milhouse`

## Documentation Search with qmd

This project is indexed with **qmd** for fast documentation search. Use this FIRST before making changes or when you need context.

### When to Use qmd

**ALWAYS search documentation before:**
- Making changes to core scripts (milhouse.sh, milhouse-autorun.sh, etc.)
- Answering questions about how Milhouse works
- Understanding system architecture or design decisions
- Finding examples of similar functionality
- Checking existing conventions or patterns

### How to Search

**Keyword search (fast, default):**
```bash
qmd search "AutoRunner" -c milhouse
qmd search "PRD structure" -c milhouse
qmd search "branch management" -c milhouse
```

**Get specific documents:**
```bash
qmd get qmd://milhouse/readme.md
qmd get qmd://milhouse/milhouse-autorunner-readme.md
```

**List all documentation:**
```bash
qmd ls milhouse
```

### Available Documentation

The `milhouse` qmd collection includes:
- **readme.md** - Main system documentation
- **milhouse-autorunner-readme.md** - Auto-runner configuration and usage
- **milhouse-system-complete-documentation.md** - Complete system reference
- **agents.md** - Agent behavior and patterns
- **skills/prd/skill.md** - PRD management skill
- **skills/milhouse/skill.md** - Milhouse workflow skill
- **prompt.md** - Legacy prompt format
- **prompt-example-rails.md** - Rails-specific example

### Search Workflow

1. **Before any code changes:**
   ```bash
   qmd search "relevant keywords" -c milhouse
   ```

2. **Review the results** - Read the relevant sections

3. **Get full documents if needed:**
   ```bash
   qmd get qmd://milhouse/path/to/file.md
   ```

4. **Make informed changes** based on existing patterns

## Project Structure

```
milhouse/
├── milhouse.sh                           # Main agent script (multi-backend)
├── milhouse-copilot.sh                   # GitHub Copilot CLI variant
├── milhouse-autorun.sh                   # Auto-runner daemon script
├── milhouse-autorun                      # Auto-runner management CLI
├── CLAUDE.md                          # This file
├── README.md                          # Main documentation
├── Milhouse-AutoRunner-README.md         # Auto-runner docs
├── agents.md                          # Agent patterns
├── skills/                            # Skill definitions
│   ├── prd/SKILL.md                  # PRD management
│   └── milhouse/SKILL.md                # Milhouse workflow
└── flowchart/                         # Interactive visualization
    ├── src/                          # React Flow app
    └── README.md                     # Visualization docs
```

## Ruby/Rails Defaults

Milhouse is an opinionated Ruby AI automation tool with curated skills and MCP servers.

### Setup

```bash
milhouse ruby setup    # Install all Ruby/Rails tools
milhouse ruby status   # Check installation status
```

### Included Skills

| Skill | Command | Source |
|-------|---------|--------|
| Rails System Test Analyzer | `/rails-system-test-analyzer` | [robzolkos/skill-rails-system-test-analyzer](https://github.com/robzolkos/skill-rails-system-test-analyzer) |
| Rails Upgrade Assistant | `/rails-upgrade-assistant` | [maquina-app/rails-upgrade-skill](https://github.com/maquina-app/rails-upgrade-skill) |
| RubyCritic | (model-invoked) | [esparkman/claude-rubycritic-skill](https://github.com/esparkman/claude-rubycritic-skill) |

### Included MCP Server

| Server | Source |
|--------|--------|
| rails-mcp-server | [maquina-app/rails-mcp-server](https://github.com/maquina-app/rails-mcp-server) |

### Key Files

- `lib/ruby.sh` - Ruby/Rails setup functions
- `defaults/ruby/README.md` - Full Ruby/Rails documentation

## Core Concepts

### PRD Files (prd.json)
- Located in `your-project/.milhouse/prd.json`
- Contains user stories with `passes` boolean field
- Milhouse processes stories where `passes: false`
- Updates `passes: true` when complete

### CLAUDE.md Files
- Project-specific agent instructions
- Located in `your-project/.milhouse/CLAUDE.md`
- Defines quality checks, conventions, tech stack
- Used by milhouse.sh to generate prompts

### Progress Tracking
- `progress.txt` - Append-only learning journal
- Documents what was completed each run
- Helps agents learn from previous work

### Auto-Runner
- System-wide service (macOS LaunchAgent)
- Scans `~/dev/**/.milhouse/prd.json` hourly
- Runs Milhouse on first incomplete PRD found
- Configurable operating hours (default: 9 PM - 7 AM)
- Managed via `milhouse-autorun` command

## Development Guidelines

### Making Changes to Milhouse

1. **Search documentation first:**
   ```bash
   qmd search "topic" -c milhouse
   ```

2. **Understand existing patterns** - Read relevant docs

3. **Test locally** before committing

4. **Update documentation** if changing core functionality

5. **Keep commit messages descriptive**

### Code Style

- **Bash scripts**: Follow existing patterns in milhouse.sh
- **Use oroshi patterns**: Check oroshi integration in codebase
- **Configuration**: Support both env vars and config files
- **Logging**: Log important events with timestamps
- **Error handling**: Capture errors and provide helpful messages

### Testing Changes

**Test milhouse.sh:**
```bash
cd /Users/cody/Dev/milhouse
./milhouse.sh --help
```

**Test auto-runner:**
```bash
milhouse-autorun test  # Dry run
milhouse-autorun logs  # Check recent activity
```

**Verify qmd index is current:**
```bash
qmd status
qmd search "test query" -c milhouse
```

## Common Tasks

### Updating Documentation

When you modify README.md, Milhouse-AutoRunner-README.md, or other markdown files:

1. **Update the qmd index:**
   ```bash
   qmd update
   ```

2. **Verify the changes are indexed:**
   ```bash
   qmd search "new content" -c milhouse
   ```

### Adding New Features

1. **Search for similar features:**
   ```bash
   qmd search "feature name" -c milhouse
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
- List files: `qmd ls milhouse`

**If changes aren't reflected:**
- The qmd index updates on `qmd update`
- Run it after modifying markdown files

## Best Practices

### For AI Agents Working on Milhouse

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
qmd search "query" -c milhouse          # Search milhouse docs (fast)
qmd ls milhouse                         # List all files
qmd get qmd://milhouse/readme.md        # Get specific file
qmd status                           # Check index status
qmd update                           # Update index after doc changes
```

### Milhouse Commands
```bash
milhouse-autorun status                 # Check auto-runner status
milhouse-autorun logs                   # View recent activity
milhouse-autorun schedule               # Show operating hours
milhouse-autorun test                   # Dry run (doesn't execute)
```

### File Locations
- Milhouse repo: `/Users/cody/Dev/milhouse`
- Auto-runner config: `~/.milhouse-autorun.conf`
- Auto-runner logs: `~/.milhouse-autorun.log`
- qmd index: `~/.cache/qmd/index.sqlite`
- Skills directory: `~/.claude/skills/`

## Emergency Contacts / References

- Main documentation: [README.md](README.md)
- Auto-runner docs: [Milhouse-AutoRunner-README.md](Milhouse-AutoRunner-README.md)
- System reference: [Milhouse-System-Complete-Documentation.md](Milhouse-System-Complete-Documentation.md)
- qmd skill: `~/.claude/skills/qmd.md`

---

**Remember**: Search documentation with qmd BEFORE making changes. The documentation contains crucial context about how the system works and why design decisions were made.
