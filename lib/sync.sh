#!/usr/bin/env bash

sync_instances() {
    echo "Scanning ~/dev for milhouse instances..."

    # Find all .milhouse directories
    local instances=()
    while IFS= read -r -d '' dir; do
        instances+=("$dir")
    done < <(find ~/dev -type d -name ".milhouse" -not -path "*/node_modules/*" -not -path "*/.git/*" -print0 2>/dev/null)

    echo "Found ${#instances[@]} milhouse instance(s)"

    # Process each instance
    for instance in "${instances[@]}"; do
        sync_instance "$instance"
    done
}

sync_instance() {
    local instance_dir="$1"
    local project_dir="$(dirname "$instance_dir")"

    echo "Processing: $project_dir"

    # Check for .milhouse-source marker
    if [[ -f "$instance_dir/.milhouse-source" ]]; then
        echo "  ✓ Verified milhouse instance"

        # Update milhouse CLI tool globally (user will install to ~/.local/bin)
        echo "  → milhouse CLI is global, managed separately"

        # Check/setup qmd
        setup_qmd_for_project "$project_dir"

        # Update CLAUDE.md
        update_claude_md "$instance_dir" "$project_dir"
    else
        echo "  ⚠ No .milhouse-source marker, skipping"
    fi
}

setup_qmd_for_project() {
    local project_dir="$1"
    local project_name="$(basename "$project_dir")"

    # Check if qmd collection exists
    if qmd collection list 2>/dev/null | grep -q "^$project_name "; then
        echo "  ✓ qmd collection exists: $project_name"
        # Update it
        (cd "$project_dir" && qmd update 2>&1 | tail -3)
    else
        echo "  + Creating qmd collection: $project_name"
        qmd collection add "$project_dir" --name "$project_name" --mask "**/*.md" --exclude "node_modules/**" --exclude "**/node_modules/**" 2>&1 | tail -3
    fi
}

update_claude_md() {
    local instance_dir="$1"
    local project_dir="$2"
    local claude_md="$instance_dir/CLAUDE.md"

    # This will be expanded in next task
    echo "  → CLAUDE.md update (to be implemented)"
}
