#!/usr/bin/env bash
# Claude adapter for Milhouse

claude_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"
    local verbose="${4:-true}"

    local exit_code=0
    local tmp_rc=$(mktemp)

    if [ "$verbose" = "true" ]; then
        (timeout "${timeout_mins}m" claude --dangerously-skip-permissions --print "$prompt" < /dev/null 2>&1; echo $? > "$tmp_rc") | tee "$output_file"
        exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    else
        timeout "${timeout_mins}m" claude --dangerously-skip-permissions --print "$prompt" < /dev/null > "$output_file" 2>&1
        exit_code=$?
    fi
    
    rm -f "$tmp_rc"
    return $exit_code
}
