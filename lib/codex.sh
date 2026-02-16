#!/usr/bin/env bash
# Codex adapter for Milhouse

codex_run() {
    local prompt="$1"
    local output_file="$2"
    local timeout_mins="$3"
    local verbose="${4:-true}"

    if ! command -v codex &> /dev/null; then
        echo "Error: codex CLI not found. Install Codex CLI or choose another backend." | tee "$output_file"
        return 127
    fi

    local -a codex_cmd=(codex exec --full-auto)
    if [[ -n "${MILHOUSE_CODEX_PROFILE:-}" ]]; then
        codex_cmd+=(--profile "$MILHOUSE_CODEX_PROFILE")
    fi
    if [[ -n "${MILHOUSE_CODEX_MODEL:-}" ]]; then
        codex_cmd+=(--model "$MILHOUSE_CODEX_MODEL")
    fi
    codex_cmd+=("$prompt")

    local exit_code=0
    local tmp_rc
    tmp_rc=$(mktemp)

    if [[ "$verbose" == "true" ]]; then
        (timeout "${timeout_mins}m" "${codex_cmd[@]}" 2>&1; echo $? > "$tmp_rc") | tee "$output_file"
        exit_code=$(cat "$tmp_rc" 2>/dev/null || echo 1)
    else
        timeout "${timeout_mins}m" "${codex_cmd[@]}" > "$output_file" 2>&1
        exit_code=$?
    fi

    rm -f "$tmp_rc"
    return "$exit_code"
}
