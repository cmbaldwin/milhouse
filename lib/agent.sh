#!/usr/bin/env bash
# Agent execution logic for Milhouse
# Handles PRD processing, archiving, progress tracking, and agent iteration loop

# Track child PID for cleanup
MILHOUSE_AGENT_PID=""

_milhouse_cleanup() {
    echo ""
    echo "Milhouse interrupted. Cleaning up..."
    if [[ -n "$MILHOUSE_AGENT_PID" ]] && kill -0 "$MILHOUSE_AGENT_PID" 2>/dev/null; then
        kill "$MILHOUSE_AGENT_PID" 2>/dev/null
        wait "$MILHOUSE_AGENT_PID" 2>/dev/null
    fi
    echo "Stopped."
    exit 130
}

get_dev_folder() {
    local config_file="${MILHOUSE_CONFIG:-$HOME/.config/milhouse/config}"
    if [[ -f "$config_file" ]]; then
        local dev_folder=$(grep "^dev_folder=" "$config_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [[ -n "$dev_folder" ]]; then
            echo "$dev_folder"
            return 0
        fi
    fi
    echo "${DEFAULT_DEV_FOLDER:-$HOME/dev}"
}

find_available_projects() {
    local dev_folder=$(get_dev_folder)
    local -a projects=()
    if [[ -d "$dev_folder" ]]; then
        while IFS= read -r -d '' prd_file; do
            local milhouse_dir=$(dirname "$prd_file")
            local project_dir=$(dirname "$milhouse_dir")
            local project_name=$(basename "$project_dir")
            if [[ "$project_name" == "archive" ]]; then
                continue
            fi
            local exists=false
            if [[ ${#projects[@]} -gt 0 ]]; then
                for p in "${projects[@]}"; do
                    if [[ "$p" == "$project_name" ]]; then
                        exists=true
                        break
                    fi
                done
            fi
            if [[ "$exists" == false ]]; then
                projects+=("$project_name")
            fi
        done < <(find "$dev_folder" -name "prd.json" -path "*/.milhouse/*" -print0 2>/dev/null)
    fi
    if [[ ${#projects[@]} -gt 0 ]]; then
        printf '%s\n' "${projects[@]}"
    fi
}

build_prompt() {
    local project_dir="$1"
    local milhouse_dir="$project_dir/.milhouse"
    local milhouse_repo_dir="${MILHOUSE_REPO_DIR:-$HOME/.local/lib/milhouse}"
    local claude_md="$project_dir/CLAUDE.md"
    local combined=""

    # Prefer local .milhouse/prompt.md, fall back to installed generic prompt.md
    local prompt_file=""
    if [[ -f "$milhouse_dir/prompt.md" ]]; then
        prompt_file="$milhouse_dir/prompt.md"
    elif [[ -f "$milhouse_repo_dir/prompt.md" ]]; then
        prompt_file="$milhouse_repo_dir/prompt.md"
    else
        echo "Error: No prompt.md found in $milhouse_dir/ or $milhouse_repo_dir/" >&2
        return 1
    fi

    combined="$(cat "$prompt_file")"

    # Append project-specific context
    if [[ -f "$claude_md" ]]; then
        combined="$combined"$'\n\n---\n\n'"$(cat "$claude_md")"
    fi

    echo "$combined"
}

archive_completed_run() {
    local milhouse_dir="$1"
    local prd_file="$milhouse_dir/prd.json"
    local progress_file="$milhouse_dir/progress.txt"
    local archive_dir="$milhouse_dir/archive"

    if [[ ! -f "$prd_file" ]]; then
        return 0
    fi

    local branch_name=$(jq -r '.branchName // "unknown"' "$prd_file" 2>/dev/null)
    local folder_name=$(echo "$branch_name" | sed 's|^milhouse/||; s|^feature/||')
    local date=$(date +%Y-%m-%d)
    local archive_folder="$archive_dir/$date-$folder_name"

    echo "Archiving completed run: $branch_name"
    mkdir -p "$archive_folder"
    [[ -f "$prd_file" ]] && cp "$prd_file" "$archive_folder/"
    [[ -f "$progress_file" ]] && cp "$progress_file" "$archive_folder/"
    echo "  Archived to: $archive_folder"

    # Reset progress file for next run
    echo "# Milhouse Progress Log" > "$progress_file"
    echo "Started: $(date)" >> "$progress_file"
    echo "---" >> "$progress_file"
}

run_agent() {
    # Set up Ctrl+C trap for clean shutdown
    trap _milhouse_cleanup INT TERM

    # Parse arguments
    local turns="25"
    local tool="claude"
    local verbose="true"
    local timeout_mins="15"  # Per-iteration timeout in minutes

    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool)
                tool="$2"
                shift 2
                ;;
            --quiet)
                verbose="false"
                shift
                ;;
            --verbose)
                verbose="true"
                shift
                ;;
            --timeout)
                timeout_mins="$2"
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

    # Determine project directory
    local PROJECT_DIR=""
    local MILHOUSE_DIR=""

    if [[ "$(basename "$PWD")" == ".milhouse" ]]; then
        MILHOUSE_DIR="$PWD"
        PROJECT_DIR="$(dirname "$PWD")"
    elif [[ -d "$PWD/.milhouse" ]]; then
        MILHOUSE_DIR="$PWD/.milhouse"
        PROJECT_DIR="$PWD"
    elif [[ -f "$PWD/CLAUDE.md" ]]; then
        PROJECT_DIR="$PWD"
        if [[ -d "$PWD/.milhouse" ]]; then
            MILHOUSE_DIR="$PWD/.milhouse"
        else
            MILHOUSE_DIR="$PWD"
        fi
    fi

    # Validate .milhouse directory exists
    if [[ -z "$MILHOUSE_DIR" ]] || [[ ! -d "$MILHOUSE_DIR" ]]; then
        local dev_folder=$(get_dev_folder)
        echo "Error: No Milhouse project found in current directory."
        echo ""
        echo "Make sure you're running from either:"
        echo "  - A project directory with a .milhouse/ subdirectory"
        echo "  - A .milhouse/ subdirectory"
        echo ""
        echo "Searching for available projects in $dev_folder..."
        echo ""

        local projects=($(find_available_projects))
        if [[ ${#projects[@]} -gt 0 ]]; then
            echo "Available projects:"
            for project in "${projects[@]}"; do
                echo "  - $project"
            done
            echo ""
            echo "To run milhouse in a project:"
            echo "  cd $dev_folder/<project> && milhouse run"
        else
            echo "No projects found in $dev_folder/"
            echo ""
            echo "To set up a new project:"
            echo "  cd $dev_folder/<your-project>"
            echo "  milhouse install ."
        fi
        return 1
    fi

    # Check if CLAUDE.md exists in project root
    if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        echo "Warning: No CLAUDE.md found in project root ($PROJECT_DIR)"
        echo "Milhouse requires a CLAUDE.md file in the project root directory."
        return 1
    fi

    # Set up file paths
    local SCRIPT_DIR="$MILHOUSE_DIR"
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

    if command -v qmd &> /dev/null && qmd collection list 2>/dev/null | grep -q "^$project_name "; then
        echo "Using qmd collection: $project_name"

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

    # Build unified prompt (agent workflow instructions + project context)
    PROMPT=$(build_prompt "$PROJECT_DIR")
    if [[ $? -ne 0 ]]; then
        echo "Failed to build prompt. Ensure prompt.md exists."
        return 1
    fi

    echo "Starting Milhouse - Tool: $tool - Max iterations: $turns - Timeout: ${timeout_mins}m/iter"
    echo "Press Ctrl+C to stop at any time."
    echo ""

    local consecutive_failures=0
    local MAX_CONSECUTIVE_FAILURES=3

    # Main agent execution loop
    for i in $(seq 1 $turns); do
        echo ""
        echo "==============================================================="
        echo "  Milhouse Iteration $i of $turns ($tool)"
        echo "  Started: $(date '+%H:%M:%S')  Timeout: ${timeout_mins}m"
        echo "==============================================================="

        # Check if all stories are already complete before running
        if [ -f "$PRD_FILE" ]; then
            local remaining=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null)
            if [[ "$remaining" == "0" ]]; then
                echo ""
                echo "All stories in prd.json are complete!"
                archive_completed_run "$MILHOUSE_DIR"
                trap - INT TERM
                return 0
            fi
            echo "  Stories remaining: $remaining"
        fi

        # Create temp file for output capture (allows tee for streaming)
        local tmpfile=$(mktemp)

        local exit_code=0
        case "$tool" in
            claude)
                if [ "$verbose" = "true" ]; then
                    timeout "${timeout_mins}m" claude -p "$PROMPT" --dangerously-skip-permissions --print 2>&1 | tee "$tmpfile" || exit_code=$?
                else
                    timeout "${timeout_mins}m" claude -p "$PROMPT" --dangerously-skip-permissions --print > "$tmpfile" 2>&1 || exit_code=$?
                fi
                ;;
            copilot)
                timeout "${timeout_mins}m" bash -c 'gh copilot --allow-all -p "$1" 2>&1' _ "$PROMPT" | tee "$tmpfile" || exit_code=$?
                ;;
            opencode)
                timeout "${timeout_mins}m" opencode run -m opencode/kimi-k2.5-free "$PROMPT" 2>&1 | tee "$tmpfile" || exit_code=$?
                ;;
            amp)
                echo "$PROMPT" | timeout "${timeout_mins}m" amp --dangerously-allow-all 2>&1 | tee "$tmpfile" || exit_code=$?
                ;;
        esac

        OUTPUT=$(cat "$tmpfile")
        rm -f "$tmpfile"

        # Handle timeout (exit code 124)
        if [[ $exit_code -eq 124 ]]; then
            echo ""
            echo "WARNING: Iteration $i timed out after ${timeout_mins} minutes."
            consecutive_failures=$((consecutive_failures + 1))
        # Handle other errors
        elif [[ $exit_code -ne 0 ]]; then
            echo ""
            echo "WARNING: $tool exited with code $exit_code on iteration $i."
            consecutive_failures=$((consecutive_failures + 1))
        else
            consecutive_failures=0
        fi

        # Check for consecutive failures
        if [[ $consecutive_failures -ge $MAX_CONSECUTIVE_FAILURES ]]; then
            echo ""
            echo "ERROR: $MAX_CONSECUTIVE_FAILURES consecutive failures. Stopping."
            echo "Check $PROGRESS_FILE for status."
            trap - INT TERM
            return 1
        fi

        # Check for completion signal
        if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
            echo ""
            echo "Milhouse completed all tasks!"
            echo "Completed at iteration $i of $turns"
            archive_completed_run "$MILHOUSE_DIR"
            trap - INT TERM
            return 0
        fi

        # Check for empty output (agent produced nothing)
        if [[ -z "$OUTPUT" ]]; then
            echo ""
            echo "WARNING: $tool produced no output on iteration $i."
            consecutive_failures=$((consecutive_failures + 1))
        fi

        echo ""
        echo "Iteration $i complete. Continuing in 2s..."
        sleep 2
    done

    echo ""
    echo "Milhouse reached max iterations ($turns) without completing all tasks."
    echo "Check $PROGRESS_FILE for status."
    trap - INT TERM
    return 1
}
