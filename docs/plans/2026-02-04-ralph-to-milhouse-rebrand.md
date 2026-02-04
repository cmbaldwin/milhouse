# Ralph to Milhouse Rebrand and Unified CLI

**Date**: 2026-02-04
**Status**: Approved
**Author**: Cody Baldwin

## Overview

Complete rebrand from "ralph" to "milhouse" with a unified CLI tool that consolidates all functionality (agent execution, autorunner, sync, qmd integration) into a single command-line interface.

## Goals

1. Rename all "ralph" references to "milhouse" across the entire codebase
2. Create unified `milhouse` CLI tool with subcommands
3. Build sync system to update milhouse instances across projects
4. Integrate qmd search automatically into milhouse workflow
5. Auto-setup qmd collections for projects

## Phase 1: Complete Rebrand with Unified CLI

### New CLI Structure

Single entry point: `milhouse` with subcommands:

```bash
milhouse run [turns]          # Run milhouse agent on current project
milhouse autorun start        # Start the autorunner daemon
milhouse autorun stop         # Stop the autorunner daemon
milhouse autorun status       # Check autorunner status
milhouse autorun logs         # View autorunner logs
milhouse autorun schedule     # Show/edit schedule
milhouse sync                 # Sync/update all milhouse instances in ~/dev
milhouse qmd setup            # Set up qmd for current project
milhouse qmd update           # Update qmd index
milhouse install [project]    # Install milhouse into a project
milhouse version              # Show version info
milhouse help                 # Show help
```

### Repository Structure

```
milhouse/
├── milhouse                  # Main CLI tool (bash script)
├── lib/
│   ├── agent.sh             # Core agent logic (from ralph.sh)
│   ├── autorun.sh           # Autorunner daemon logic
│   ├── sync.sh              # Sync/update logic
│   └── qmd.sh               # QMD integration logic
├── docs/
│   └── plans/               # Design documents
├── README.md
├── Milhouse-System-Documentation.md
├── CLAUDE.md
└── skills/
    ├── prd/SKILL.md
    └── milhouse/SKILL.md
```

### Project Structure (when installed)

```
your-project/
├── .milhouse/
│   ├── .milhouse-source     # Marker file (repo URL/hash)
│   ├── CLAUDE.md            # Project-specific + milhouse instructions
│   ├── prd.json             # User stories
│   └── progress.txt         # Learning journal
└── ... (project files)
```

### Files to Rename

**Scripts**:
- `ralph.sh` → part of `milhouse` CLI (lib/agent.sh)
- `ralph-copilot.sh` → part of `milhouse` CLI
- `ralph-autorun.sh` → part of `milhouse` CLI (lib/autorun.sh)
- `ralph-autorun` → consolidated into `milhouse`

**Documentation**:
- `Ralph-AutoRunner-README.md` → `Milhouse-System-Documentation.md` (consolidated)
- `Ralph-System-Complete-Documentation.md` → merged into main docs

**Skills**:
- `skills/ralph/SKILL.md` → `skills/milhouse/SKILL.md`

### System Files to Update

- LaunchAgent: `com.user.ralph-autorun.plist` → `com.user.milhouse-autorun.plist`
- Config: `~/.ralph-autorun.conf` → `~/.milhouse.conf`
- Logs: `~/.ralph-autorun.log` → `~/.milhouse-autorun.log`, `~/.milhouse-autorun.err.log` → `~/.milhouse-autorun.err.log`

### Content Updates

- All variable names: `RALPH_*` → `MILHOUSE_*`
- All directory references: `.ralph` → `.milhouse`
- All documentation references
- All script comments and echo statements
- qmd collection: `ralph` → `milhouse`
- GitHub repository name

## Phase 2: Sync/Update/QMD Integration

### `milhouse sync` Command

**Purpose**: Keep all milhouse instances across projects up-to-date

**Process**:
1. Scan `~/dev` for all `.milhouse/` directories
2. Check for `.milhouse/.milhouse-source` marker (contains repo URL/hash)
3. For each identified milhouse instance:
   - Copy latest `milhouse` CLI from this repo to `~/.local/bin/milhouse`
   - Projects use the global `milhouse` command (no local copies)
4. For each project with `.milhouse/`:
   - Ensure qmd collection exists
   - Update qmd index
   - Update CLAUDE.md with qmd instructions

**Marker File** (`.milhouse/.milhouse-source`):
```
repo=https://github.com/cmbaldwin/milhouse
commit=<current-git-hash>
```

### `milhouse qmd setup` Command

**Purpose**: Set up qmd integration for current project

**Process**:
1. Detect project name from directory or git repo
2. Create qmd collection: `qmd collection add . --name project-name --mask "**/*.md" --exclude "node_modules/**"`
3. Add context description
4. Run initial embedding (optional, for semantic search)
5. Update `.milhouse/CLAUDE.md` with qmd search instructions for this collection

### `milhouse qmd update` Command

**Purpose**: Refresh qmd index for current project

**Process**:
1. Run `qmd update` for current project's collection
2. Optionally run `qmd embed` if semantic search is configured

### QMD Integration in Agent Workflow

**When `milhouse run` executes**:
1. Before reading CLAUDE.md, check if qmd collection exists for parent project
2. If not, offer to run `milhouse qmd setup`
3. Search relevant documentation based on current user story:
   - Extract keywords from user story title/description
   - Run: `qmd search "keywords" -c project-name -n 5`
4. Include search results in prompt context sent to AI
5. Update CLAUDE.md to always instruct agent to search qmd first

### CLAUDE.md Enhancement

Each `.milhouse/CLAUDE.md` will include:
1. **Parent project context** (if parent CLAUDE.md exists, read and include relevant sections)
2. **QMD integration instructions**:
   - Always search qmd before making changes
   - Use project-specific collection name
   - Examples of search commands
3. **Milhouse-specific instructions**:
   - How to use milhouse commands
   - Progress tracking
   - Quality checks

### Installation Workflow

**New project setup**:
```bash
cd your-project
milhouse install
# Creates .milhouse/, CLAUDE.md template, prd.json template
# Sets up qmd collection
# Adds .milhouse-source marker
```

**Syncing existing installations**:
```bash
milhouse sync
# Scans ~/dev for all .milhouse instances
# Updates CLI tool
# Ensures qmd collections exist
# Updates CLAUDE.md files
```

## Implementation Steps

### Phase 1: Rebrand
1. Create unified `milhouse` CLI script with subcommand routing
2. Extract logic from ralph.sh into lib/agent.sh
3. Extract logic from ralph-autorun.sh into lib/autorun.sh
4. Rename all files
5. Update all content references
6. Update qmd collection name
7. Test basic functionality
8. Update LaunchAgent
9. Commit and push

### Phase 2: Sync/Update/QMD
1. Implement lib/sync.sh (scanning, updating)
2. Implement lib/qmd.sh (setup, update, search integration)
3. Add `milhouse sync` command
4. Add `milhouse qmd setup` and `milhouse qmd update` commands
5. Add `milhouse install` command
6. Integrate qmd search into agent workflow
7. Create CLAUDE.md template with qmd instructions
8. Test sync across multiple projects
9. Test qmd auto-setup
10. Commit and push

## Testing Plan

1. Test all `milhouse` subcommands individually
2. Test autorunner start/stop/status
3. Test sync across multiple test projects
4. Test qmd setup on fresh project
5. Test qmd integration in agent workflow
6. Verify backward compatibility (or migration path)

## Notes

- **Computer sleep issue**: Auto-runner may not wake from sleep. Research LaunchAgent wake behavior. (Deferred to post-implementation)
- **Migration**: Existing ralph installations will need manual migration or a one-time migration script
- **GitHub repo**: Rename to `milhouse` on GitHub after local rename is complete

## Success Criteria

- ✅ All "ralph" references renamed to "milhouse"
- ✅ Single `milhouse` CLI works with all subcommands
- ✅ `milhouse sync` updates all instances in ~/dev
- ✅ `milhouse qmd setup` auto-configures new projects
- ✅ Agent workflow includes qmd search results
- ✅ Documentation is updated and accurate
