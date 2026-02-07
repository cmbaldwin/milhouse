#!/usr/bin/env bash
# OpenCode adapter for Milhouse

opencode_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"

    local exit_code=0
    local tmp_rc=$(mktemp)

    (timeout "${timeout_mins}m" bash -c 'opencode run -m opencode/kimi-k2.5-free "$1" 2>&1' _ "$prompt"; echo $? > "$tmp_rc") | tee "$output_file"
    exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    
    rm -f "$tmp_rc"
    return $exit_code
}
