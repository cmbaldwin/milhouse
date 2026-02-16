#!/usr/bin/env bash
set -euo pipefail

project_dir="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir)
            project_dir="$2"
            shift 2
            ;;
        -h|--help)
            cat << 'EOF'
Usage: check_milhouse_install.sh [--project-dir <path>]

Checks whether a project is ready to run Milhouse.
EOF
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

project_dir="$(cd "$project_dir" && pwd)"
status=0

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    status=1
}

check_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        pass "Found file: $file_path"
    else
        fail "Missing file: $file_path"
    fi
}

echo "Checking Milhouse readiness for: $project_dir"
echo ""

if command -v milhouse >/dev/null 2>&1; then
    pass "milhouse command is available"
else
    fail "milhouse command not found in PATH"
fi

if command -v codex >/dev/null 2>&1; then
    pass "codex command is available"
else
    fail "codex command not found in PATH"
fi

if command -v jq >/dev/null 2>&1; then
    pass "jq command is available"
else
    fail "jq command not found in PATH"
fi

if [[ -d "$project_dir/.milhouse" ]]; then
    pass "Found directory: $project_dir/.milhouse"
else
    fail "Missing directory: $project_dir/.milhouse"
fi

check_file "$project_dir/AGENTS.md"
check_file "$project_dir/.milhouse/prd.json"
check_file "$project_dir/.milhouse/progress.txt"

if [[ -f "$project_dir/.milhouse/prd.json" ]]; then
    if jq -e '.userStories and (.userStories | type == "array")' "$project_dir/.milhouse/prd.json" >/dev/null 2>&1; then
        pass "prd.json includes a userStories array"
    else
        fail "prd.json is missing a valid userStories array"
    fi
fi

echo ""
if [[ "$status" -eq 0 ]]; then
    echo "Ready: Milhouse install checks passed."
else
    echo "Not ready: One or more checks failed."
fi

exit "$status"
