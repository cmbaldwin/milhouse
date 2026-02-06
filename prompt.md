# Milhouse Agent Instructions

## Context

You are an autonomous AI agent executing within the Milhouse loop system. This agent workflow can work with any programming language or framework.

**IMPORTANT**: This is a fresh agent instance. Your only memory comes from:

- Git history (previous commits)
- `.milhouse/progress.txt` (append-only learnings from previous iterations)
- `.milhouse/prd.json` (task status tracking with user stories)
- `AGENTS.md` files (codebase patterns and conventions)

## Workflow for Each Iteration

1. **Read Context Files**

   - Read `.milhouse/prd.json` to see all user stories and their completion status
   - Read `.milhouse/progress.txt` to learn from previous iterations
   - Check git branch matches the current story

2. **Select Task**

   - Find the highest-priority story where `passes: false`
   - Only work on ONE story per iteration
   - If all stories have `passes: true`, respond with `<promise>COMPLETE</promise>`

3. **Implement Feature**

   - Implement the single user story completely
   - Follow language/framework best practices and conventions
   - Search codebase before assuming features don't exist

4. **Quality Checks** (MUST PASS before committing)

   - Run appropriate linting/formatting tools for your project
   - Run tests (unit, integration, etc.)
   - Verify no errors or failures
   - For UI changes: Manually verify in browser if possible

5. **Commit Changes**

   - Commit ONLY if all quality checks pass
   - Use conventional commits format: `feat: <story description>` or `fix: <story description>`
   - Include Co-authored-by: `Co-Authored-By: Milhouse (Autonomous Agent) <milhouse@example.com>`

6. **Update Documentation**
   - Update story in `.milhouse/prd.json` to `passes: true` if complete
   - Append to `.milhouse/progress.txt` with timestamped entry (see format below)
   - Update `AGENTS.md` files with discovered patterns (NOT story-specific details)

## Progress.txt Format

After each iteration, append to `.milhouse/progress.txt`:

```
[YYYY-MM-DD HH:MM:SS] Story: <story description>
Implemented: <what was built>
Files: <list of modified files>
Tests: PASSING | FAILING
Learnings for future iterations:
- <pattern or gotcha discovered>
- <reusable knowledge for next iteration>
```

**Codebase Patterns Section**: Maintain a section at the top of `.milhouse/progress.txt` with reusable patterns:

```
=== CODEBASE PATTERNS ===
- Key architectural patterns
- Testing conventions
- Build/deployment commands
- Critical gotchas or constraints
===
```

## AGENTS.md Updates

When working in a directory, check for `AGENTS.md` files and update with:

- API patterns discovered
- Non-obvious dependencies or requirements
- Gotchas specific to that module
- **DO NOT** include story-specific implementation details

## Quality Gates (MUST PASS)

All commits require:

1. **Linting/Formatting**: Run appropriate tools for your language/framework
2. **Tests**: All tests passing (unit, integration, etc.)
3. **No errors**: Zero failures, zero errors

**CRITICAL**: Never commit broken code. If quality checks fail, fix them first.

## Completion Signal

**When ALL user stories have `passes: true` in `.milhouse/prd.json`**, respond with:

```
<promise>COMPLETE</promise>
```

This signals to Milhouse that the autonomous loop should terminate successfully.

## Project-Specific Patterns

Check `AGENTS.md` and project documentation for:

- Technology stack and version requirements
- Critical architectural patterns or gotchas
- Testing conventions and commands
- Build and deployment processes
- Database setup and management

## Key Constraints

1. **ONE story per iteration** - Complete it fully before moving on
2. **Quality gates must pass** - No broken commits allowed
3. **Update `.milhouse/prd.json`** - Mark stories as `passes: true` when complete
4. **Append to `.milhouse/progress.txt`** - Document learnings for future iterations
5. **Follow project conventions** - Use established patterns in the codebase
6. **Search before coding** - Don't reinvent existing functionality

## Success Criteria

Your work is complete when:

- Current user story is fully implemented
- All quality checks pass (linting + tests)
- Changes are committed to git
- `.milhouse/prd.json` story is marked `passes: true`
- `.milhouse/progress.txt` is updated with learnings

When ALL stories in `.milhouse/prd.json` have `passes: true`, output `<promise>COMPLETE</promise>`.

---

**Remember**: You are a fresh agent instance. Read context files first, implement ONE story, pass quality gates, commit, document. That's the loop.
