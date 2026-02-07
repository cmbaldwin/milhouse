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

get_simple_prompt() {
    # Instead of constructing a massive prompt, just tell Claude to read the files
    # Claude has --dangerously-skip-permissions so it can read files directly
    echo "You are Milhouse, an autonomous AI agent. Read and follow the agent instructions in .milhouse/prompt.md. Your project context is in CLAUDE.md at the project root. Follow the workflow: read prd.json, pick one incomplete story, implement it, run quality checks, commit, update progress.txt, and signal completion with <promise>COMPLETE</promise> when all stories pass."
}

milhouse_config() {
    local config_file="${MILHOUSE_CONFIG:-$HOME/.config/milhouse/config}"
    local config_dir="$(dirname "$config_file")"

    case "${1:-}" in
        set)
            local key="$2"
            local value="$3"
            if [[ -z "$key" || -z "$value" ]]; then
                echo "Usage: milhouse config set <key> <value>"
                echo ""
                echo "Available keys:"
                echo "  default_tool    Default AI tool (claude|copilot|opencode|amp|pi)"
                echo "  dev_folder      Dev folder to scan for projects"
                return 1
            fi
            mkdir -p "$config_dir"
            if [[ -f "$config_file" ]] && grep -q "^${key}=" "$config_file" 2>/dev/null; then
                sed -i '' "s|^${key}=.*|${key}=${value}|" "$config_file"
            else
                echo "${key}=${value}" >> "$config_file"
            fi
            echo "Set ${key}=${value}"
            ;;
        edit)
            mkdir -p "$config_dir"
            if [[ ! -f "$config_file" ]]; then
                cat > "$config_file" << 'CONF'
# Milhouse Configuration
# Default AI tool for 'milhouse run' (claude|copilot|opencode|amp|pi)
default_tool=claude

# Dev folder to scan for projects
# dev_folder=~/dev
CONF
                echo "Created default config at $config_file"
            fi
            "${EDITOR:-vi}" "$config_file"
            ;;
        *)
            if [[ -f "$config_file" ]]; then
                echo "Milhouse Configuration ($config_file):"
                echo ""
                cat "$config_file"
            else
                echo "No configuration file found."
                echo ""
                echo "Run 'milhouse config edit' to create one, or:"
                echo "  milhouse config set default_tool copilot"
            fi
            ;;
    esac
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
    local verbose="true"
    local timeout_mins="15"  # Per-iteration timeout in minutes

    # Read default tool from config, fall back to claude
    local config_file="${MILHOUSE_CONFIG:-$HOME/.config/milhouse/config}"
    local tool="claude"
    if [[ -f "$config_file" ]]; then
        local configured_tool=$(grep "^default_tool=" "$config_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [[ -n "$configured_tool" ]]; then
            tool="$configured_tool"
        fi
    fi

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
    if [[ "$tool" != "claude" && "$tool" != "copilot" && "$tool" != "opencode" && "$tool" != "amp" && "$tool" != "pi" ]]; then
        echo "Error: Invalid tool '$tool'. Must be 'claude', 'copilot', 'opencode', 'amp', or 'pi'."
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

    # Use simple prompt - Claude reads files itself
    local SIMPLE_PROMPT
    SIMPLE_PROMPT=$(get_simple_prompt)

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
                    (timeout "${timeout_mins}m" claude --dangerously-skip-permissions --print "$SIMPLE_PROMPT" < /dev/null 2>&1; echo $? > "$tmpfile.rc") | tee "$tmpfile"
                    exit_code=$(cat "$tmpfile.rc" 2>/dev/null || echo 1)
                    rm -f "$tmpfile.rc"
                else
                    timeout "${timeout_mins}m" claude --dangerously-skip-permissions --print "$SIMPLE_PROMPT" < /dev/null > "$tmpfile" 2>&1
                    exit_code=$?
                fi
                ;;
            copilot)
                (timeout "${timeout_mins}m" bash -c 'gh copilot --allow-all -p "$1" 2>&1' _ "$SIMPLE_PROMPT"; echo $? > "$tmpfile.rc") | tee "$tmpfile"
                exit_code=$(cat "$tmpfile.rc" 2>/dev/null || echo 1)
                rm -f "$tmpfile.rc"
                ;;
            opencode)
                (timeout "${timeout_mins}m" bash -c 'opencode run -m opencode/kimi-k2.5-free "$1" 2>&1' _ "$SIMPLE_PROMPT"; echo $? > "$tmpfile.rc") | tee "$tmpfile"
                exit_code=$(cat "$tmpfile.rc" 2>/dev/null || echo 1)
                rm -f "$tmpfile.rc"
                ;;
            amp)
                # AMP reads from stdin, so we pass the simple prompt via stdin
                (timeout "${timeout_mins}m" bash -c 'echo "$1" | amp --dangerously-allow-all' _ "$SIMPLE_PROMPT" 2>&1; echo $? > "$tmpfile.rc") | tee "$tmpfile"
                exit_code=$(cat "$tmpfile.rc" 2>/dev/null || echo 1)
                rm -f "$tmpfile.rc"
                ;;
            pi)

                # Pi Coding Agent
                # The tool attempts to start a TUI if it detects a TTY.
                # We need to force it into non-interactive mode.
                # According to common patterns, redirecting stdin from /dev/null might help if it checks isatty
                # OR we need a specific flag.
                # For now, let's try to run it with </dev/null to break TTY detection if it relies on stdin being a TTY.
                # AND ensure we pass the prompt clearly.
                # If 'pi' expects the prompt as an argument, "$1" is correct.
                # We also remove --yes if it's not a real flag (it wasn't in the help text I saw, I guessed it).
                
                # Let's try to find the correct non-interactive invocation.
                # Inspecting the error: "InteractiveMode.init". We want "HeadlessMode" or "ScriptMode".
                # I will try to pass the prompt via argument and redirect stdin to /dev/null to prevent TUI.
                (timeout "${timeout_mins}m" bash -c 'pi "$1" < /dev/null 2>&1' _ "$SIMPLE_PROMPT"; echo $? > "$tmpfile.rc") | tee "$tmpfile"
                exit_code=$(cat "$tmpfile.rc" 2>/dev/null || echo 1)
                rm -f "$tmpfile.rc"
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
