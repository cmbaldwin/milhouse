#!/usr/bin/env bash
# Agent execution logic for Milhouse
# Handles PRD processing, archiving, progress tracking, and agent iteration loop

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
            # prd_file is like: /Users/cody/dev/project/.milhouse/prd.json
            # Get the parent of .milhouse (the project name)
            local milhouse_dir=$(dirname "$prd_file")
            local project_dir=$(dirname "$milhouse_dir")
            local project_name=$(basename "$project_dir")
            # Skip archive directories
            if [[ "$project_name" == "archive" ]]; then
                continue
            fi
            # Only add if not already in list
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
    local milhouse_repo_dir="${MILHOUSE_REPO_DIR:-$HOME/.local/lib/milhouse}"
    local prompt_file="$milhouse_repo_dir/prompt.md"
    local claude_md="$project_dir/CLAUDE.md"
    local combined=""

    # Start with milhouse agent instructions (iteration workflow)
    if [[ -f "$prompt_file" ]]; then
        combined="$(cat "$prompt_file")"
    else
        echo "Error: prompt.md not found at $prompt_file" >&2
        return 1
    fi

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
    # Parse arguments - support both positional and --tool flag
    local turns="25"
    local tool="claude"
    local verbose="true"  # Default to verbose (streaming) output
    
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

    # Determine project directory - CLAUDE.md must be in project root
    local PROJECT_DIR=""
    local MILHOUSE_DIR=""
    
    # Check if we're in a .milhouse directory
    if [[ "$(basename "$PWD")" == ".milhouse" ]]; then
        MILHOUSE_DIR="$PWD"
        PROJECT_DIR="$(dirname "$PWD")"
    # Check if there's a .milhouse subdirectory
    elif [[ -d "$PWD/.milhouse" ]]; then
        MILHOUSE_DIR="$PWD/.milhouse"
        PROJECT_DIR="$PWD"
    # If CLAUDE.md exists in current dir, treat as project root
    elif [[ -f "$PWD/CLAUDE.md" ]]; then
        PROJECT_DIR="$PWD"
        # Look for .milhouse subdirectory or use current dir
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
            echo "  cd $dev_folder/<project>/.milhouse && milhouse run"
            echo "  or"
            echo "  cd $dev_folder/<project> && milhouse run"
        else
            echo "No projects found in $dev_folder/"
            echo ""
            echo "To configure the dev folder, create/edit ~/.config/milhouse/config:"
            echo "  dev_folder=/path/to/your/projects"
            echo ""
            echo "Or set the environment variable:"
            echo "  export DEFAULT_DEV_FOLDER=/path/to/your/projects"
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
        echo ""
        echo "Milhouse requires a CLAUDE.md file in the project root directory."
        echo "Please create $PROJECT_DIR/CLAUDE.md with your project instructions."
        echo ""
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

    # Build unified prompt (agent workflow instructions + project context)
    PROMPT=$(build_prompt "$PROJECT_DIR")
    if [[ $? -ne 0 ]]; then
        echo "Failed to build prompt. Ensure prompt.md exists in milhouse installation."
        return 1
    fi

    echo "Starting Milhouse - Tool: $tool - Max iterations: $turns - Output: $([ "$verbose" = "true" ] && echo "verbose" || echo "quiet")"

    # Main agent execution loop
    for i in $(seq 1 $turns); do
        echo ""
        echo "==============================================================="
        echo "  Milhouse Iteration $i of $turns ($tool)"
        echo "==============================================================="

        # All tools receive the same combined prompt
        case "$tool" in
            claude)
                if [ "$verbose" = "true" ]; then
                    echo "[Claude processing...]"
                    OUTPUT=$(claude -p "$PROMPT" --dangerously-skip-permissions --print 2>&1)
                    echo "$OUTPUT"
                else
                    OUTPUT=$(claude -p "$PROMPT" --dangerously-skip-permissions --print 2>&1) || true
                fi
                ;;
            copilot)
                OUTPUT=$(gh copilot --allow-all -p "$PROMPT" 2>&1 | tee /dev/stderr) || true
                ;;
            opencode)
                if [ "$verbose" = "true" ]; then
                    OUTPUT=$(opencode run -m opencode/kimi-k2.5-free "$PROMPT" 2>&1 | tee /dev/stderr) || true
                else
                    OUTPUT=$(opencode run -m opencode/kimi-k2.5-free "$PROMPT" 2>&1) || true
                fi
                ;;
            amp)
                OUTPUT=$(echo "$PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
                ;;
        esac

        # Check for completion signal
        if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
            echo ""
            echo "Milhouse completed all tasks!"
            echo "Completed at iteration $i of $turns"
            archive_completed_run "$MILHOUSE_DIR"
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
