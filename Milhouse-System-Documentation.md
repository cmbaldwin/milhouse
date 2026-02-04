# Milhouse Auto-Runner

Automatically runs Milhouse agents on incomplete PRDs every hour.

## What It Does

1. **Searches** `~/dev/` for any `.milhouse/prd.json` files with incomplete stories
2. **Excludes** archived PRDs (in `archive/` folders)
3. **Runs** `milhouse.sh --tool claude 15` in the first incomplete PRD found
4. **Logs** all activity to `~/.milhouse-autorun.log`
5. **Runs** every hour at 1 minute past (12:01, 1:01, 2:01, etc.)
6. **Resumes** after sleep - if computer was asleep at scheduled time, runs when it wakes
7. **Respects schedule** - Only operates during configured hours (default: 9PM-7AM)

## Installation

Already installed and running! Files created:

- `/Users/cody/.local/bin/milhouse-autorun.sh` - Main script
- `/Users/cody/.local/bin/milhouse-autorun` - Management command
- `/Users/cody/Library/LaunchAgents/com.user.milhouse-autorun.plist` - macOS scheduler
- `/Users/cody/.milhouse-autorun.log` - Activity log
- `/Users/cody/.milhouse-autorun.conf` - Schedule configuration

## Usage

### Management Commands

```bash
milhouse-autorun status    # Check if service is running
milhouse-autorun start     # Start the hourly auto-runner
milhouse-autorun stop      # Stop the auto-runner
milhouse-autorun restart   # Restart the auto-runner
milhouse-autorun test      # Run manually once (for testing)
milhouse-autorun logs      # Show recent logs
milhouse-autorun watch     # Watch logs in real-time
milhouse-autorun config    # View or edit schedule configuration
milhouse-autorun schedule  # Show current schedule and status
```

### Schedule Configuration

Milhouse Auto-Runner has configurable operating hours to avoid running during work hours.

**View current schedule:**

```bash
milhouse-autorun schedule
```

**Edit schedule:**

```bash
milhouse-autorun config edit
```

**Default configuration** (`~/.milhouse-autorun.conf`):

```bash
# Milhouse will NOT run during these hours (off hours)
# Times are in 24-hour format in your local timezone
OFF_START_HOUR=7   # 7 AM
OFF_END_HOUR=21    # 9 PM
```

This means Milhouse runs from **9 PM to 7 AM** only (overnight).

**Common schedules:**

```bash
# Run only at night (default)
OFF_START_HOUR=7
OFF_END_HOUR=21

# Run only during work hours (9AM-5PM)
OFF_START_HOUR=17
OFF_END_HOUR=9

# Run 24/7 (no off hours)
OFF_START_HOUR=0
OFF_END_HOUR=0

# Run only weekends (requires manual cron setup)
# Use schedule configuration for time-of-day only
```

After editing config:

```bash
milhouse-autorun restart  # Apply changes
```

### Current Status

```bash
$ milhouse-autorun status
✓ Milhouse Auto-Runner is ACTIVE
-       0       com.user.milhouse-autorun
```

## How It Works

### Schedule

- Runs every hour at 1 minute past (using macOS LaunchAgent)
- Only operates during configured hours (default: 9 PM - 7 AM)
- Will catch up if computer was asleep during scheduled time
- Only runs one Milhouse instance at a time
- Times respect your local timezone (automatically)

### PRD Discovery

- Searches: `~/dev/**/.milhouse/prd.json`
- Excludes: `*/archive/*` and `*/.git/*`
- Checks: `jq '[.userStories[] | select(.passes == false)] | length'`
- Runs: First PRD with incomplete stories

### Safety Features

- **Concurrent run detection** - Skips if milhouse.sh already running
- **Archived folder exclusion** - Won't run old/completed PRDs
- **Error logging** - Captures all errors to log files
- **Explicit directory** - Shows which folder it's running in

## Logs

### Main Activity Log

```bash
tail -f ~/.milhouse-autorun.log
```

Shows:

- When checks run
- Which PRDs found
- Milhouse execution output
- Completion status

### Error Log

```bash
tail -f ~/.milhouse-autorun.err.log
```

Shows any LaunchAgent or system errors.

## Example Log Output

```
[2026-02-03 16:32:29] ==========================================
[2026-02-03 16:32:29] Milhouse Auto-Runner: Starting check
[2026-02-03 16:32:29] Current hour 21 is within operating hours
[2026-02-03 16:32:33] Checking: /Users/cody/dev/oroshi-moab/.milhouse/prd.json
[2026-02-03 16:32:33] Found incomplete PRD with 19 stories remaining
[2026-02-03 16:32:33] PRD location: /Users/cody/dev/oroshi-moab/.milhouse/prd.json
[2026-02-03 16:32:33] Milhouse directory: /Users/cody/dev/oroshi-moab/.milhouse
[2026-02-03 16:32:33] ==========================================
[2026-02-03 16:32:33] RUNNING MILHOUSE IN: /Users/cody/dev/oroshi-moab/.milhouse
[2026-02-03 16:32:33] Command: /Users/cody/dev/oroshi-moab/.milhouse/milhouse.sh --tool claude 15
[2026-02-03 16:32:33] ==========================================
```

**Example: During off hours**

```
[2026-02-04 14:01:05] ==========================================
[2026-02-04 14:01:05] Milhouse Auto-Runner: Starting check
[2026-02-04 14:01:05] Current hour 14 is within off hours (7:00-21:00)
[2026-02-04 14:01:05] Milhouse will not run. Next run window starts at 21:00
[2026-02-04 14:01:05] Skipping run due to schedule configuration
[2026-02-04 14:01:05] ==========================================
```

## Troubleshooting

### Service Not Running

```bash
milhouse-autorun start
```

### Check Recent Activity

```bash
milhouse-autorun logs
```

### Test Manually

```bash
milhouse-autorun test
```

### Remove/Uninstall

```bash
milhouse-autorun stop
rm /Users/cody/Library/LaunchAgents/com.user.milhouse-autorun.plist
rm /Users/cody/.local/bin/milhouse-autorun*
```

## Notes

- **Sleep Mode**: LaunchAgent will run the next scheduled time after wake
- **Rate Limits**: If Claude CLI hits rate limits, check will retry next hour
- **Multiple PRDs**: Only runs one at a time (first incomplete found)
- **Manual Override**: You can still run `milhouse.sh` manually - auto-runner detects this
