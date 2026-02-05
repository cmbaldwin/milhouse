#!/usr/bin/env bash
# Agent execution logic for Milhouse
# Handles PRD processing, archiving, progress tracking, and agent iteration loop

run_agent() {
    # Parse arguments - support both positional and --tool flag
    local turns="25"
    local tool="claude"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool)
                tool="$2"
                shift 2
                ;;
            [0-9]*)
                turns="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Validate tool choice
    if [[ "$tool" != "claude" && "$tool" != "copilot" && "$tool" != "opencode" && "$tool" != "amp" ]]; then
        echo "Error: Invalid tool '$tool'. Must be 'claude', 'copilot', 'opencode', or 'amp'."
        return 1
    fi

    # Set up file paths - use current working directory (user should cd to .milhouse/)
    local SCRIPT_DIR="$PWD"
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

    # QMD Integration - Search documentation before starting
    local project_dir="$(dirname "$SCRIPT_DIR")"
    local project_name="$(basename "$project_dir")"

    # Check if qmd collection exists
    if command -v qmd &> /dev/null && qmd collection list 2>/dev/null | grep -q "^$project_name "; then
        echo "Using qmd collection: $project_name"

        # Read current user story from prd.json
        if [ -f "$PRD_FILE" ]; then
            local current_story=$(jq -r '.userStories[] | select(.passes == false) | .title' "$PRD_FILE" 2>/dev/null | head -1)

            if [[ -n "$current_story" ]]; then
                echo "Searching documentation for: $current_story"
                qmd_search_for_story "$current_story" "$project_name"
                echo ""
            fi
        fi
    else
        echo "No qmd collection found for $project_name"
        echo "Run 'milhouse qmd setup' to enable documentation search"
        echo ""
    fi

    echo "Starting Milhouse - Tool: $tool - Max iterations: $turns"

    # Main agent execution loop
    for i in $(seq 1 $turns); do
        echo ""
        echo "==============================================================="
        echo "  Milhouse Iteration $i of $turns ($tool)"
        echo "==============================================================="

        case "$tool" in
            claude)
                OUTPUT=$(claude --dangerously-skip-permissions --print < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr) || true
                ;;
            copilot)
                PROMPT=$(cat "$SCRIPT_DIR/CLAUDE.md")
                OUTPUT=$(gh copilot --allow-all -p "$PROMPT" 2>&1 | tee /dev/stderr) || true
                ;;
            opencode)
                PROMPT=$(cat "$SCRIPT_DIR/CLAUDE.md")
                OUTPUT=$(opencode run "$PROMPT" 2>&1 | tee /dev/stderr) || true
                ;;
            amp)
                OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
                ;;
        esac

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
