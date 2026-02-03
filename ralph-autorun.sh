#!/bin/bash
# Ralph Auto-Runner
# Checks ~/dev/ for incomplete Ralph PRDs and runs them

set -e

LOG_FILE="$HOME/.ralph-autorun.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Ralph Auto-Runner: Starting check"

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
