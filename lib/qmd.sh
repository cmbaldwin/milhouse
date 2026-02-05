#!/usr/bin/env bash

qmd_setup() {
    local project_dir="$(pwd)"
    local project_name="$(basename "$project_dir")"

    echo "Setting up qmd for: $project_name"

    # Check if qmd is installed
    if ! command -v qmd &> /dev/null; then
        echo "Error: qmd not installed. Install with: bun install -g https://github.com/tobi/qmd"
        exit 1
    fi

    # Check if collection already exists
    if qmd collection list 2>/dev/null | grep -q "^$project_name "; then
        echo "qmd collection '$project_name' already exists"
        read -p "Update existing collection? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        qmd update
    else
        # Create new collection
        echo "Creating qmd collection: $project_name"
        qmd collection add "$project_dir" \
            --name "$project_name" \
            --mask "**/*.md" \
            --exclude "node_modules/**" \
            --exclude "**/node_modules/**" \
            --exclude ".git/**"

        # Add context description
        local context_desc="$project_name project documentation"
        qmd context add "qmd://$project_name/" "$context_desc" 2>/dev/null || true
    fi

    echo "✓ qmd setup complete for $project_name"
    echo ""
    echo "Usage:"
    echo "  qmd search \"query\" -c $project_name"
    echo "  qmd ls $project_name"
    echo "  qmd get qmd://$project_name/readme.md"
}

qmd_update() {
    echo "Updating qmd index..."
    qmd update
    echo "✓ qmd index updated"
}

qmd_search_for_story() {
    local story_title="$1"
    local project_name="$2"

    # Extract keywords from story title
    local keywords=$(echo "$story_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g' | tr -s ' ')

    echo "Searching documentation for: $keywords"
    qmd search "$keywords" -c "$project_name" -n 5 2>/dev/null || echo "No results found"
}
