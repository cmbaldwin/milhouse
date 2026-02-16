#!/usr/bin/env bash
set -euo pipefail

config_file="${MILHOUSE_CONFIG:-$HOME/.config/milhouse/config}"
default_dev_folder="${MILHOUSE_DEV_FOLDER:-$HOME/dev}"
if [[ -f "$config_file" ]]; then
    configured_dev_folder=$(grep "^dev_folder=" "$config_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    if [[ -n "${configured_dev_folder:-}" ]]; then
        default_dev_folder="$configured_dev_folder"
    fi
fi

dev_folder="$default_dev_folder"
max_projects=1
turns=25
weekly_limit=0
window_hours=5
state_file="${MILHOUSE_CODEX_STATE_FILE:-$HOME/.milhouse-codex-dispatch-state.json}"
dry_run="false"
spread_weekly="true"
allow_same_window="false"

usage() {
    cat << 'EOF'
Usage: dispatch_prds_codex.sh [options]

Options:
  --dev-folder <path>      Root folder to scan for projects (default: milhouse config or ~/dev)
  --max-projects <n>       Max projects to dispatch in one call (default: 1)
  --turns <n>              Iterations per milhouse run (default: 25)
  --weekly-limit <n>       Max dispatches per ISO week (0 = unlimited)
  --window-hours <n>       Window size for balancing (default: 5)
  --state-file <path>      State file used for budget/window tracking
  --no-spread-weekly       Disable balanced window spread logic
  --allow-same-window      Allow multiple dispatches inside the same window
  --dry-run                Print planned runs only
  -h, --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev-folder)
            dev_folder="$2"
            shift 2
            ;;
        --max-projects)
            max_projects="$2"
            shift 2
            ;;
        --turns)
            turns="$2"
            shift 2
            ;;
        --weekly-limit)
            weekly_limit="$2"
            shift 2
            ;;
        --window-hours)
            window_hours="$2"
            shift 2
            ;;
        --state-file)
            state_file="$2"
            shift 2
            ;;
        --no-spread-weekly)
            spread_weekly="false"
            shift
            ;;
        --allow-same-window)
            allow_same_window="true"
            shift
            ;;
        --dry-run)
            dry_run="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        exit 1
    fi
}

require_number() {
    local label="$1"
    local value="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "Invalid $label: $value (must be an integer >= 0)" >&2
        exit 1
    fi
}

iso_week() {
    date +%G-W%V
}

current_window_id() {
    local seconds_per_window=$((window_hours * 3600))
    echo $(( $(date +%s) / seconds_per_window ))
}

current_window_in_week() {
    local day_of_week hour_of_day hour_of_week
    day_of_week=$((10#$(date +%u) - 1))
    hour_of_day=$((10#$(date +%H)))
    hour_of_week=$(( day_of_week * 24 + hour_of_day ))
    echo $(( hour_of_week / window_hours ))
}

total_windows_per_week() {
    echo $(( (168 + window_hours - 1) / window_hours ))
}

is_allowed_window_for_week() {
    local window_index="$1"
    local total_windows="$2"
    local limit="$3"
    local i idx last_idx

    if (( limit <= 0 || limit >= total_windows )); then
        return 0
    fi

    last_idx=-1
    for (( i=0; i<limit; i++ )); do
        idx=$(( i * total_windows / limit ))
        if (( idx == last_idx )); then
            continue
        fi
        if (( idx == window_index )); then
            return 0
        fi
        last_idx=$idx
    done
    return 1
}

read_state() {
    state_week=""
    state_count=0
    state_last_window=""

    if [[ -f "$state_file" ]]; then
        state_week=$(jq -r '.week // empty' "$state_file" 2>/dev/null || echo "")
        local parsed_count
        parsed_count=$(jq -r '.count // 0' "$state_file" 2>/dev/null || echo "0")
        if [[ "$parsed_count" =~ ^[0-9]+$ ]]; then
            state_count="$parsed_count"
        fi
        state_last_window=$(jq -r '.last_window_id // empty' "$state_file" 2>/dev/null || echo "")
    fi
}

write_state() {
    local count="$1"
    local last_window="$2"
    local state_dir
    state_dir="$(dirname "$state_file")"
    mkdir -p "$state_dir"

    cat > "$state_file" << EOF
{
  "week": "$current_week",
  "count": $count,
  "last_window_id": "$last_window",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

require_command milhouse
require_command codex
require_command jq
require_command find

require_number "max-projects" "$max_projects"
require_number "turns" "$turns"
require_number "weekly-limit" "$weekly_limit"
require_number "window-hours" "$window_hours"

if (( max_projects <= 0 )); then
    echo "max-projects must be > 0" >&2
    exit 1
fi

if (( turns <= 0 )); then
    echo "turns must be > 0" >&2
    exit 1
fi

if (( window_hours <= 0 )); then
    echo "window-hours must be > 0" >&2
    exit 1
fi

if [[ ! -d "$dev_folder" ]]; then
    echo "Dev folder does not exist: $dev_folder" >&2
    exit 1
fi

current_week="$(iso_week)"
window_id="$(current_window_id)"
window_in_week="$(current_window_in_week)"
weekly_window_count="$(total_windows_per_week)"

read_state
if [[ "$state_week" != "$current_week" ]]; then
    state_count=0
    state_last_window=""
fi

echo "Dispatch context:"
echo "  Dev folder: $dev_folder"
echo "  Week: $current_week"
echo "  Weekly limit: $weekly_limit"
echo "  Current weekly count: $state_count"
echo "  Window hours: $window_hours"
echo "  Current window index (week): $window_in_week / $weekly_window_count"
echo ""

if [[ "$allow_same_window" != "true" && "$state_last_window" == "$window_id" ]]; then
    echo "Skip: dispatch already happened in current ${window_hours}h window."
    exit 0
fi

if (( weekly_limit > 0 && state_count >= weekly_limit )); then
    echo "Skip: weekly limit reached ($state_count / $weekly_limit)."
    exit 0
fi

if [[ "$spread_weekly" == "true" ]] && ! is_allowed_window_for_week "$window_in_week" "$weekly_window_count" "$weekly_limit"; then
    echo "Skip: current window is outside the balanced weekly window set."
    exit 0
fi

candidates=()
while IFS= read -r -d '' prd_file; do
    incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file" 2>/dev/null || echo "0")
    if [[ "$incomplete" =~ ^[0-9]+$ ]] && (( incomplete > 0 )); then
        candidates+=("$prd_file")
    fi
done < <(find "$dev_folder" -type f -name "prd.json" -path "*/.milhouse/*" ! -path "*/archive/*" ! -path "*/.git/*" -print0)

if (( ${#candidates[@]} == 0 )); then
    echo "No incomplete PRDs found."
    exit 0
fi

dispatched=0
failed=0
new_count="$state_count"

for prd_file in "${candidates[@]}"; do
    if (( dispatched >= max_projects )); then
        break
    fi

    if (( weekly_limit > 0 && new_count >= weekly_limit )); then
        echo "Weekly limit reached during this run; stopping dispatch."
        break
    fi

    milhouse_dir="$(dirname "$prd_file")"
    project_dir="$(dirname "$milhouse_dir")"

    echo "Target project: $project_dir"
    echo "Command: (cd \"$milhouse_dir\" && milhouse run --tool codex $turns)"

    if [[ "$dry_run" == "true" ]]; then
        dispatched=$((dispatched + 1))
        echo ""
        continue
    fi

    if (cd "$milhouse_dir" && milhouse run --tool codex "$turns"); then
        dispatched=$((dispatched + 1))
        new_count=$((new_count + 1))
        echo "Result: success"
    else
        failed=$((failed + 1))
        echo "Result: failed"
    fi
    echo ""
done

if [[ "$dry_run" != "true" && "$dispatched" -gt 0 ]]; then
    write_state "$new_count" "$window_id"
fi

echo "Dispatch summary:"
echo "  Dispatched: $dispatched"
echo "  Failed: $failed"
if [[ "$dry_run" != "true" ]]; then
    if (( weekly_limit > 0 )); then
        echo "  Weekly usage: $new_count / $weekly_limit"
    else
        echo "  Weekly usage: $new_count (unlimited)"
    fi
fi

if (( failed > 0 )); then
    exit 1
fi

exit 0
