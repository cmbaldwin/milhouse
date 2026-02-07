#!/usr/bin/env bash
# GitHub Copilot adapter for Milhouse

copilot_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"
    # Copilot doesn't strictly support "quiet" in the same way via this wrapper, mostly we just pipe output.
    
    local exit_code=0
    local tmp_rc=$(mktemp)

    (timeout "${timeout_mins}m" bash -c 'gh copilot --allow-all -p "$1" 2>&1' _ "$prompt"; echo $? > "$tmp_rc") | tee "$output_file"
    exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    
    rm -f "$tmp_rc"
    return $exit_code
}
