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

install_milhouse() {
    local target_project="${1:-.}"
    local target_dir="$(cd "$target_project" && pwd)"
    local milhouse_dir="$target_dir/.milhouse"

    echo "Installing milhouse in: $target_dir"

    # Create .milhouse directory
    mkdir -p "$milhouse_dir"

    # Create .milhouse-source marker
    local repo_url="https://github.com/cmbaldwin/milhouse"
    local commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

    cat > "$milhouse_dir/.milhouse-source" << EOF
repo=$repo_url
commit=$commit_hash
installed=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

    echo "✓ Created .milhouse-source marker"

    # Create CLAUDE.md template
    if [[ ! -f "$milhouse_dir/CLAUDE.md" ]]; then
        create_claude_md_template "$milhouse_dir" "$(basename "$target_dir")"
        echo "✓ Created CLAUDE.md template"
    fi

    # Create prd.json template
    if [[ ! -f "$milhouse_dir/prd.json" ]]; then
        create_prd_template "$milhouse_dir"
        echo "✓ Created prd.json template"
    fi

    # Create progress.txt
    if [[ ! -f "$milhouse_dir/progress.txt" ]]; then
        echo "# Milhouse Progress Log" > "$milhouse_dir/progress.txt"
        echo "Started: $(date)" >> "$milhouse_dir/progress.txt"
        echo "✓ Created progress.txt"
    fi

    # Setup qmd
    echo ""
    read -p "Set up qmd collection for this project? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        (cd "$target_dir" && qmd_setup)
    fi

    echo ""
    echo "✓ Milhouse installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .milhouse/CLAUDE.md with your project context"
    echo "  2. Edit .milhouse/prd.json with your user stories"
    echo "  3. Run: milhouse run"
}

create_claude_md_template() {
    local milhouse_dir="$1"
    local project_name="$2"

    cat > "$milhouse_dir/CLAUDE.md" << 'EOF'
# Project Instructions for Milhouse

## Project Overview

[Describe your project here]

## Tech Stack

- [Technology 1]
- [Technology 2]

## Documentation Search with qmd

Search project documentation before making changes:

```bash
qmd search "query" -c PROJECT_NAME
```

## Quality Checks

Run these before marking a story complete:

```bash
# Linting
[your lint command]

# Tests
[your test command]

# Build
[your build command]
```

## Conventions

- [Coding conventions]
- [Naming patterns]
- [Project-specific patterns]

EOF

    # Replace PROJECT_NAME placeholder
    sed -i.bak "s/PROJECT_NAME/$project_name/g" "$milhouse_dir/CLAUDE.md"
    rm "$milhouse_dir/CLAUDE.md.bak" 2>/dev/null || true
}

create_prd_template() {
    local milhouse_dir="$1"

    cat > "$milhouse_dir/prd.json" << 'EOF'
{
  "productName": "Your Product",
  "version": "1.0.0",
  "userStories": [
    {
      "id": "US-001",
      "title": "Example user story",
      "description": "As a user, I want to...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
EOF
}
