#!/usr/bin/env bash
# Agent execution logic for Milhouse
# Handles PRD processing, archiving, progress tracking, and agent iteration loop

run_agent() {
    local turns="$1"
    local tool="${2:-claude}"

    # Validate tool choice
    if [[ "$tool" != "amp" && "$tool" != "claude" ]]; then
        echo "Error: Invalid tool '$tool'. Must be 'amp' or 'claude'."
        return 1
    fi

    # Set up file paths
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local PRD_FILE="$SCRIPT_DIR/prd.json"
    local PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
    local ARCHIVE_DIR="$SCRIPT_DIR/archive"
    local LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

    # Archive previous run if branch changed
    if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
        CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

        if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
            DATE=$(date +%Y-%m-%d)
            FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^milhouse/||; s|^feature/||')
            ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

            echo "Archiving previous run: $LAST_BRANCH"
            mkdir -p "$ARCHIVE_FOLDER"
            [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
            [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
            echo "   Archived to: $ARCHIVE_FOLDER"

            echo "# Milhouse Progress Log" > "$PROGRESS_FILE"
            echo "Started: $(date)" >> "$PROGRESS_FILE"
            echo "---" >> "$PROGRESS_FILE"
        fi
    fi

    # Track current branch
    if [ -f "$PRD_FILE" ]; then
        CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
        if [ -n "$CURRENT_BRANCH" ]; then
            echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
        fi
    fi

    # Initialize progress file if it doesn't exist
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "# Milhouse Progress Log" > "$PROGRESS_FILE"
        echo "Started: $(date)" >> "$PROGRESS_FILE"
        echo "---" >> "$PROGRESS_FILE"
    fi

    echo "Starting Milhouse - Tool: $tool - Max iterations: $turns"

    # Main agent execution loop
    for i in $(seq 1 $turns); do
        echo ""
        echo "==============================================================="
        echo "  Milhouse Iteration $i of $turns ($tool)"
        echo "==============================================================="

        if [[ "$tool" == "amp" ]]; then
            OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
        else
            OUTPUT=$(claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr) || true
        fi

        # Check for completion signal
        if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
            echo ""
            echo "Milhouse completed all tasks!"
            echo "Completed at iteration $i of $turns"
            return 0
        fi

        echo "Iteration $i complete. Continuing..."
        sleep 2
    done

    echo ""
    echo "Milhouse reached max iterations ($turns) without completing all tasks."
    echo "Check $PROGRESS_FILE for status."
    return 1
}
