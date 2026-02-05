#!/usr/bin/env bash
# Milhouse Auto-Runner Library
# Extracted autorunner logic for the Milhouse agent system

# Configuration
LOG_FILE="${LOG_FILE:-$HOME/.milhouse-autorun.log}"
CONFIG_FILE="${CONFIG_FILE:-$HOME/.milhouse-autorun.conf}"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function to check if current time is within allowed hours
check_schedule() {
  local CURRENT_HOUR=$(date +%H | sed 's/^0*//')  # Remove leading zeros

  # Handle wrap-around case (e.g., 21:00-07:00)
  if [ "$OFF_START_HOUR" -lt "$OFF_END_HOUR" ]; then
    # Simple case: 7-21 (off during day)
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] && [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      log "Current hour $CURRENT_HOUR is within off hours ($OFF_START_HOUR:00-$OFF_END_HOUR:00)"
      log "Milhouse will not run. Next run window starts at $OFF_END_HOUR:00"
      return 1
    fi
  else
    # Wrap-around case: 21-7 (off during night)
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] || [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      log "Current hour $CURRENT_HOUR is within off hours ($OFF_START_HOUR:00-$OFF_END_HOUR:00)"
      log "Milhouse will not run. Next run window starts at $OFF_END_HOUR:00"
      return 1
    fi
  fi

  log "Current hour $CURRENT_HOUR is within operating hours"
  return 0
}

# Load or create default configuration
load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    # Default: OFF from 7AM to 9PM (only runs 9PM-7AM)
    cat > "$CONFIG_FILE" << 'EOF'
# Milhouse Auto-Runner Schedule Configuration
# Times are in 24-hour format in your local timezone
# Milhouse will NOT run during these hours (off hours)
# Default: OFF from 7AM to 9PM (only runs at night)
OFF_START_HOUR=7
OFF_END_HOUR=21
EOF
    log "Created default configuration at $CONFIG_FILE"
  fi

  # Source configuration
  source "$CONFIG_FILE"
}

# Main daemon logic - scans for PRDs and runs Milhouse
autorun_daemon() {
  log "=========================================="
  log "Milhouse Auto-Runner: Starting check"

  # Load configuration
  load_config

  # Check if we're within operating hours
  if ! check_schedule; then
    log "Skipping run due to schedule configuration"
    return 0
  fi

  # Find all prd.json files in ~/dev/, excluding archive folders
  local PRD_FILES=$(find "$HOME/dev" -type f -name "prd.json" ! -path "*/archive/*" ! -path "*/.git/*" 2>/dev/null || true)

  if [ -z "$PRD_FILES" ]; then
    log "No PRD files found in ~/dev/"
    return 0
  fi

  # Check each PRD for incomplete stories
  while IFS= read -r prd_file; do
    log "Checking: $prd_file"

    # Check if PRD has any incomplete stories (passes: false)
    local INCOMPLETE=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file" 2>/dev/null || echo "0")

    if [ "$INCOMPLETE" -gt 0 ]; then
      local MILHOUSE_DIR=$(dirname "$prd_file")
      local MILHOUSE_SCRIPT="$MILHOUSE_DIR/milhouse.sh"

      log "Found incomplete PRD with $INCOMPLETE stories remaining"
      log "PRD location: $prd_file"
      log "Milhouse directory: $MILHOUSE_DIR"

      if [ ! -f "$MILHOUSE_SCRIPT" ]; then
        log "ERROR: milhouse.sh not found at $MILHOUSE_SCRIPT"
        continue
      fi

      if [ ! -x "$MILHOUSE_SCRIPT" ]; then
        log "Making milhouse.sh executable..."
        chmod +x "$MILHOUSE_SCRIPT"
      fi

      log "=========================================="
      log "RUNNING RALPH IN: $MILHOUSE_DIR"
      log "Command: $MILHOUSE_SCRIPT --tool claude 15"
      log "=========================================="

      # Check if milhouse is already running
      if pgrep -f "milhouse.sh.*$MILHOUSE_DIR" > /dev/null; then
        log "Milhouse is already running in this directory, skipping..."
        continue
      fi

      # Run milhouse.sh with 15 iterations
      cd "$MILHOUSE_DIR"

      if "$MILHOUSE_SCRIPT" --tool claude 15 >> "$LOG_FILE" 2>&1; then
        log "Milhouse completed successfully"
      else
        local EXIT_CODE=$?
        log "ERROR: Milhouse failed with exit code $EXIT_CODE"
        log "Check $LOG_FILE for details"
        return $EXIT_CODE
      fi

      # Only run one Milhouse instance at a time
      break
    else
      log "PRD is complete (no incomplete stories)"
    fi
  done <<< "$PRD_FILES"

  log "Milhouse Auto-Runner: Check complete"
  log "=========================================="
}

# Start the auto-runner service (macOS LaunchAgent)
autorun_start() {
  local PLIST_FILE="${PLIST_FILE:-$HOME/Library/LaunchAgents/com.user.milhouse-autorun.plist}"

  echo "Loading Milhouse Auto-Runner..."
  launchctl load "$PLIST_FILE" 2>/dev/null || echo "Already loaded"
  launchctl list | grep milhouse-autorun
  echo "✓ Milhouse Auto-Runner is now active"
  echo "  Runs every hour at 1 minute past"
}

# Stop the auto-runner service
autorun_stop() {
  local PLIST_FILE="${PLIST_FILE:-$HOME/Library/LaunchAgents/com.user.milhouse-autorun.plist}"

  echo "Stopping Milhouse Auto-Runner..."
  launchctl unload "$PLIST_FILE" 2>/dev/null || echo "Not running"
  echo "✓ Milhouse Auto-Runner stopped"
}

# Restart the auto-runner service
autorun_restart() {
  local PLIST_FILE="${PLIST_FILE:-$HOME/Library/LaunchAgents/com.user.milhouse-autorun.plist}"

  echo "Restarting Milhouse Auto-Runner..."
  launchctl unload "$PLIST_FILE" 2>/dev/null
  launchctl load "$PLIST_FILE"
  echo "✓ Milhouse Auto-Runner restarted"
}

# Check the status of the auto-runner service
autorun_status() {
  if launchctl list | grep -q milhouse-autorun; then
    echo "✓ Milhouse Auto-Runner is ACTIVE"
    launchctl list | grep milhouse-autorun
  else
    echo "✗ Milhouse Auto-Runner is NOT running"
  fi
}

# View recent logs
autorun_logs() {
  echo "=== Main Log ==="
  tail -50 "$LOG_FILE" 2>/dev/null || echo "No log file yet"
  echo ""
  echo "=== Error Log ==="
  tail -20 "$HOME/.milhouse-autorun.err.log" 2>/dev/null || echo "No errors"
}

# Watch logs in real-time
autorun_watch() {
  echo "Watching Milhouse Auto-Runner logs (Ctrl+C to stop)..."
  tail -f "$LOG_FILE"
}

# View or edit configuration
autorun_config() {
  local edit_mode="${1:-}"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default configuration..."
    cat > "$CONFIG_FILE" << 'EOF'
# Milhouse Auto-Runner Schedule Configuration
# Times are in 24-hour format in your local timezone
# Milhouse will NOT run during these hours (off hours)
# Default: OFF from 7AM to 9PM (only runs at night)
OFF_START_HOUR=7
OFF_END_HOUR=21
EOF
    echo "✓ Created: $CONFIG_FILE"
  fi

  if [ "$edit_mode" = "edit" ]; then
    ${EDITOR:-nano} "$CONFIG_FILE"
    echo "✓ Configuration updated"
    echo "  Run 'milhouse autorun restart' to apply changes"
  else
    echo "Current configuration:"
    echo ""
    cat "$CONFIG_FILE"
    echo ""
    echo "To edit: milhouse autorun config edit"
  fi
}

# Show current schedule and status
autorun_schedule() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "No configuration file found. Run 'milhouse autorun config' to create one."
    return 1
  fi

  source "$CONFIG_FILE"
  local CURRENT_HOUR=$(date +%H | sed 's/^0*//')

  echo "Schedule Configuration:"
  echo "  OFF hours: ${OFF_START_HOUR}:00 - ${OFF_END_HOUR}:00"
  echo "  Current time: $(date '+%H:%M %Z')"
  echo "  Current hour: $CURRENT_HOUR"
  echo ""

  # Check if currently in off hours
  if [ "$OFF_START_HOUR" -lt "$OFF_END_HOUR" ]; then
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] && [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      echo "Status: ⏸️  OFF (within off hours)"
      echo "Next run window: ${OFF_END_HOUR}:00"
    else
      echo "Status: ✓ ACTIVE (within operating hours)"
    fi
  else
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] || [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      echo "Status: ⏸️  OFF (within off hours)"
      echo "Next run window: ${OFF_END_HOUR}:00"
    else
      echo "Status: ✓ ACTIVE (within operating hours)"
    fi
  fi
}

# Daemon mode - called by LaunchAgent
autorun_daemon() {
    load_config

    log "=========================================="
    log "Milhouse Auto-Runner: Starting check"
    log "=========================================="

    # Check schedule
    if ! check_schedule; then
        exit 0
    fi

    # Find incomplete PRDs
    log "Scanning for incomplete PRDs in ~/dev..."

    local prd_file=$(find ~/dev -name "prd.json" -path "*/.milhouse/*" -not -path "*/archive/*" -not -path "*/.git/*" 2>/dev/null | while read prd; do
        local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd" 2>/dev/null)
        if [[ $incomplete -gt 0 ]]; then
            echo "$prd"
            break
        fi
    done)

    if [[ -z "$prd_file" ]]; then
        log "No incomplete PRDs found"
        log "=========================================="
        exit 0
    fi

    log "Found PRD: $prd_file"

    local milhouse_dir="$(dirname "$prd_file")"
    local incomplete_count=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file" 2>/dev/null)

    log "PRD location: $prd_file"
    log "Milhouse directory: $milhouse_dir"
    log "Incomplete stories: $incomplete_count"
    log "=========================================="

    # Check if milhouse is already running
    if pgrep -f "milhouse run" > /dev/null 2>&1; then
        log "Milhouse is already running, skipping this iteration"
        exit 0
    fi

    log "RUNNING MILHOUSE IN: $milhouse_dir"
    cd "$milhouse_dir" || exit 1

    # Run milhouse
    if command -v milhouse &> /dev/null; then
        milhouse run 25 2>&1 | tee -a "$LOG_FILE"
    else
        log "ERROR: milhouse command not found"
        exit 1
    fi

    log "Milhouse run completed"
    log "=========================================="
}

# Test mode - dry run showing what would be executed
autorun_test() {
    echo "TEST MODE: Scanning for incomplete PRDs..."
    echo ""

    find ~/dev -name "prd.json" -path "*/.milhouse/*" -not -path "*/archive/*" -not -path "*/.git/*" 2>/dev/null | while read prd; do
        local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd" 2>/dev/null)
        if [[ $incomplete -gt 0 ]]; then
            echo "Would run: $prd"
            echo "  Incomplete stories: $incomplete"
            echo "  Directory: $(dirname "$prd")"
            echo ""
        fi
    done

    if [ -z "$(find ~/dev -name "prd.json" -path "*/.milhouse/*" -not -path "*/archive/*" -not -path "*/.git/*" 2>/dev/null | head -1)" ]; then
        echo "No milhouse PRDs found in ~/dev"
    fi
}
