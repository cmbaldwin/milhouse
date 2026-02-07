#!/usr/bin/env bash
# AMP adapter for Milhouse

amp_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"

    local exit_code=0
    local tmp_rc=$(mktemp)

    # AMP reads from stdin
    (timeout "${timeout_mins}m" bash -c 'echo "$1" | amp --dangerously-allow-all' _ "$prompt" 2>&1; echo $? > "$tmp_rc") | tee "$output_file"
    exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    
    rm -f "$tmp_rc"
    return $exit_code
}
