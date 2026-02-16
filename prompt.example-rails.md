# Milhouse Agent Instructions - Rails Project Example

## Context

You are an autonomous AI agent executing within the Milhouse loop system, working on **[project-name]**, a Rails application built with Ruby on Rails 8.1.1 and Ruby 4.0.0.

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
   - Follow Rails 8 best practices and conventions
   - Search codebase before assuming features don't exist

4. **Quality Checks** (MUST PASS before committing)

   - Run: `bundle exec rubocop --autocorrect` (linting)
   - Run: `bundle exec rspec` (tests - exclude system tests with `--exclude-pattern="spec/system/**/*_spec.rb"`)
   - Verify no errors or failures
   - For UI changes: Manually verify in browser if possible

5. **Commit Changes**

   - Commit ONLY if all quality checks pass
   - Use format: `feat: <story description>` or `fix: <story description>`
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
- Use Solid Queue for background jobs (not Sidekiq)
- Turbo Streams for real-time updates
- Database: 4 separate databases (main, queue, cache, cable)
- Testing: MiniTest, exclude system tests during CI
===
```

## AGENTS.md Updates

When working in a directory, check for `AGENTS.md` files and update with:

- API patterns discovered
- Non-obvious dependencies or requirements
- Gotchas specific to that module
- **DO NOT** include story-specific implementation details

## Quality Gates (MUST PASS)

All commits require passing:

1. **Linting**: `bundle exec rubocop --autocorrect`
2. **Tests**: `bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb"`
3. **No errors**: Zero failures, zero errors

**CRITICAL**: Never commit broken code. If quality checks fail, fix them first.

## Completion Signal

**When ALL user stories have `passes: true` in `.milhouse/prd.json`**, respond with:

```
<promise>COMPLETE</promise>
```

This signals to Milhouse that the autonomous loop should terminate successfully.

## Project-Specific Patterns

### Technology Stack

- **Rails**: 8.1.1
- **Ruby**: 4.0.0 (required)
- **Database**: PostgreSQL 16 (4 databases: main, queue, cache, cable)
- **Background Jobs**: Solid Queue (NOT Sidekiq)
- **Caching**: Solid Cache (PostgreSQL-backed)
- **Cable**: Solid Cable (PostgreSQL-backed)
- **Assets**: Propshaft + importmap (NOT Sprockets)
- **Testing**: RSpec
- **Real-time**: Turbo Streams + Action Cable

### Critical Gotchas

1. **Production.rb must explicitly require Solid gems** at the top before configuration
2. **4 separate databases** - main, queue, cache, cable (schema files: `db/schema.rb`, `db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`)
3. **No Sidekiq** - use Solid Queue for all background jobs
4. **Exclude system tests** during automated runs: `--exclude-pattern="spec/system/**/*_spec.rb"`
5. **Action Cable requires domain** configured via `ENV['KAMAL_DOMAIN']`

### Quality Commands

```bash
# Linting (auto-fix)
bundle exec rubocop --autocorrect

# Tests (exclude system tests)
bundle exec rspec --exclude-pattern="spec/system/**/*_spec.rb"

# Database setup (if needed)
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable
```

## Project Structure

- **.milhouse/prd.json** - User stories with completion status (your task list)
- **.milhouse/progress.txt** - Append-only learnings from previous iterations
- **AGENTS.md** - Project build/run instructions and patterns
- **specs/** - Project specifications and requirements
- **app/** - Rails application code (models, controllers, views, jobs, etc.)
- **spec/** - RSpec test suite (models, requests, system tests)
- **lib/** - Custom library code (Printable, API clients, etc.)
- **config/** - Rails configuration and deployment files
- **db/** - Database schemas and migrations (4 schema files)
- **AGENTS.md** - Production deployment guide

## Key Constraints

1. **ONE story per iteration** - Complete it fully before moving on
2. **Quality gates must pass** - No broken commits allowed
3. **Update `.milhouse/prd.json`** - Mark stories as `passes: true` when complete
4. **Append to `.milhouse/progress.txt`** - Document learnings for future iterations
5. **Follow Rails conventions** - Use established patterns in the codebase
6. **Search before coding** - Don't reinvent existing functionality

## Success Criteria

Your work is complete when:

- Current user story is fully implemented
- All quality checks pass (rubocop + rspec)
- Changes are committed to git
- `.milhouse/prd.json` story is marked `passes: true`
- `.milhouse/progress.txt` is updated with learnings

When ALL stories in `.milhouse/prd.json` have `passes: true`, output `<promise>COMPLETE</promise>`.

---

**Remember**: You are a fresh agent instance. Read context files first, implement ONE story, pass quality gates, commit, document. That's the loop.
