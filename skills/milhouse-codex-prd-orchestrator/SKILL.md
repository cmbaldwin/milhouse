---
name: milhouse-codex-prd-orchestrator
description: "Verify Milhouse project readiness, dispatch Codex-backed Milhouse runs across incomplete PRDs, and enforce balanced 5-hour-window scheduling with weekly usage limits. Use when asked to: check whether Milhouse is installed, run/finish PRDs with Codex sub-agents, or schedule automation that spreads runs without exceeding a weekly cap."
---

# Milhouse Codex PRD Orchestrator

Use this skill to run Milhouse safely at scale across projects with Codex.

## Workflow

1. Validate target project/install state.
2. Dispatch Codex-backed Milhouse runs for incomplete PRDs.
3. Apply weekly budget and 5-hour window balancing before scheduling automation.

## 1) Validate Installation

Run:

```bash
scripts/check_milhouse_install.sh --project-dir /path/to/project
```

Require these before dispatch:

- `milhouse`, `codex`, and `jq` are available in `PATH`.
- Project root contains `AGENTS.md`.
- Project contains `.milhouse/prd.json` and `.milhouse/progress.txt`.
- `.milhouse/prd.json` has a `userStories` array.

## 2) Dispatch Codex Sub-Agents for PRDs

Run:

```bash
scripts/dispatch_prds_codex.sh \
  --dev-folder /path/to/dev \
  --max-projects 1 \
  --turns 25 \
  --weekly-limit 28 \
  --window-hours 5
```

Behavior:

- Scan for `.milhouse/prd.json` files with `passes: false`.
- Run `milhouse run --tool codex` in selected `.milhouse` directories.
- Gate dispatch to one run per window (`--window-hours`, default `5`).
- Enforce weekly cap (`--weekly-limit`) using a persisted state file.
- Spread runs across the whole week by allowing only balanced windows.

Use `--dry-run` to inspect what would run.

## 3) Plan Automation Windows

Preview the balanced weekly windows:

```bash
scripts/preview_window_schedule.py --weekly-limit 28 --window-hours 5
```

Use the output with automation setup.

For Codex app automations, schedule every 5 hours and let the dispatch script enforce budget:

- `rrule`: `FREQ=HOURLY;INTERVAL=5`
- Automation prompt: call `dispatch_prds_codex.sh` with `--weekly-limit` and `--window-hours 5`

## Recommended Defaults

- `--window-hours 5`
- `--max-projects 1` for predictable usage
- `--turns 25` (raise only when needed)
- Keep `--spread-weekly` enabled (default)

## Fast Triage Commands

```bash
scripts/check_milhouse_install.sh --project-dir /path/to/project
scripts/dispatch_prds_codex.sh --dev-folder /path/to/dev --dry-run
scripts/preview_window_schedule.py --weekly-limit 20 --window-hours 5
```
