#!/bin/bash
# Ralph Auto-Runner
# Checks ~/dev/ for incomplete Ralph PRDs and runs them

set -e

LOG_FILE="$HOME/.ralph-autorun.log"
CONFIG_FILE="$HOME/.ralph-autorun.conf"

# Load configuration or create default
if [ ! -f "$CONFIG_FILE" ]; then
  # Default: OFF from 7AM to 9PM (only runs 9PM-7AM)
  cat > "$CONFIG_FILE" << 'EOF'
# Ralph Auto-Runner Schedule Configuration
# Times are in 24-hour format in your local timezone
# Ralph will NOT run during these hours (off hours)
# Default: OFF from 7AM to 9PM (only runs at night)
OFF_START_HOUR=7
OFF_END_HOUR=21
EOF
  log "Created default configuration at $CONFIG_FILE"
fi

# Source configuration
source "$CONFIG_FILE"

# Function to check if current time is within allowed hours
check_schedule() {
  CURRENT_HOUR=$(date +%H | sed 's/^0*//')  # Remove leading zeros
  
  # Handle wrap-around case (e.g., 21:00-07:00)
  if [ "$OFF_START_HOUR" -lt "$OFF_END_HOUR" ]; then
    # Simple case: 7-21 (off during day)
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] && [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      log "Current hour $CURRENT_HOUR is within off hours ($OFF_START_HOUR:00-$OFF_END_HOUR:00)"
      log "Ralph will not run. Next run window starts at $OFF_END_HOUR:00"
      return 1
    fi
  else
    # Wrap-around case: 21-7 (off during night)
    if [ "$CURRENT_HOUR" -ge "$OFF_START_HOUR" ] || [ "$CURRENT_HOUR" -lt "$OFF_END_HOUR" ]; then
      log "Current hour $CURRENT_HOUR is within off hours ($OFF_START_HOUR:00-$OFF_END_HOUR:00)"
      log "Ralph will not run. Next run window starts at $OFF_END_HOUR:00"
      return 1
    fi
  fi
  
  log "Current hour $CURRENT_HOUR is within operating hours"
  return 0
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Ralph Auto-Runner: Starting check"

# Check if we're within operating hours
if ! check_schedule; then
  log "Skipping run due to schedule configuration"
  exit 0
fi

# Find all prd.json files in ~/dev/, excluding archive folders
PRD_FILES=$(find "$HOME/dev" -type f -name "prd.json" ! -path "*/archive/*" ! -path "*/.git/*" 2>/dev/null || true)

if [ -z "$PRD_FILES" ]; then
  log "No PRD files found in ~/dev/"
  exit 0
fi

# Check each PRD for incomplete stories
while IFS= read -r prd_file; do
  log "Checking: $prd_file"
  
  # Check if PRD has any incomplete stories (passes: false)
  INCOMPLETE=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file" 2>/dev/null || echo "0")
  
  if [ "$INCOMPLETE" -gt 0 ]; then
    RALPH_DIR=$(dirname "$prd_file")
    RALPH_SCRIPT="$RALPH_DIR/ralph.sh"
    
    log "Found incomplete PRD with $INCOMPLETE stories remaining"
    log "PRD location: $prd_file"
    log "Ralph directory: $RALPH_DIR"
    
    if [ ! -f "$RALPH_SCRIPT" ]; then
      log "ERROR: ralph.sh not found at $RALPH_SCRIPT"
      continue
    fi
    
    if [ ! -x "$RALPH_SCRIPT" ]; then
      log "Making ralph.sh executable..."
      chmod +x "$RALPH_SCRIPT"
    fi
    
    log "=========================================="
    log "RUNNING RALPH IN: $RALPH_DIR"
    log "Command: $RALPH_SCRIPT --tool claude 15"
    log "=========================================="
    
    # Check if ralph is already running
    if pgrep -f "ralph.sh.*$RALPH_DIR" > /dev/null; then
      log "Ralph is already running in this directory, skipping..."
      continue
    fi
    
    # Run ralph.sh with 15 iterations
    cd "$RALPH_DIR"
    
    if "$RALPH_SCRIPT" --tool claude 15 >> "$LOG_FILE" 2>&1; then
      log "Ralph completed successfully"
    else
      EXIT_CODE=$?
      log "ERROR: Ralph failed with exit code $EXIT_CODE"
      log "Check $LOG_FILE for details"
      exit $EXIT_CODE
    fi
    
    # Only run one Ralph instance at a time
    break
  else
    log "PRD is complete (no incomplete stories)"
  fi
done <<< "$PRD_FILES"

log "Ralph Auto-Runner: Check complete"
log "=========================================="
