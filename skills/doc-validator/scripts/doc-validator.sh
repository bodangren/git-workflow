#!/bin/bash

# This script scans for Markdown files in non-standard locations
# and outputs warnings.

# Define allowed patterns for Markdown files
# These patterns cover root-level docs, general docs directory, and skill-specific docs/references/examples
ALLOWED_PATTERNS=(
    "README.md"
    "LICENSE"
    "AGENTS.md"
    "RETROSPECTIVE.md"
    "docs/**/*.md"
    "skills/*/SKILL.md"
    "skills/*/references/*.md"
    "skills/*/examples/*.md"
    "skills/*/RETROSPECTIVE.md"
    ".claude/skills/*/SKILL.md"
    ".claude/skills/*/references/*.md"
    ".claude/skills/*/examples/*.md"
    ".claude/skills/*/RETROSPECTIVE.md"
)

# Function to check if a file matches any allowed pattern
is_file_allowed() {
    local file="$1"
    # Remove leading ./ for matching
    file="${file#./}"

    for pattern in "${ALLOWED_PATTERNS[@]}"; do
        # Convert glob pattern to regex for matching
        # This handles ** for recursive matching and * for single-level wildcards
        if [[ "$pattern" == *"**"* ]]; then
            # Handle ** pattern (matches any depth)
            # Use a placeholder to avoid double substitution
            local regex="${pattern//\*\*/___DOUBLE_STAR___}"
            regex="${regex//\*/[^/]*}"
            regex="${regex//___DOUBLE_STAR___/.*}"
            regex="^${regex}$"
            if [[ "$file" =~ $regex ]]; then
                return 0
            fi
        elif [[ "$pattern" == *"*"* ]]; then
            # Handle * pattern (matches within single directory level)
            local regex="${pattern//\*/[^/]*}"
            regex="^${regex}$"
            if [[ "$file" =~ $regex ]]; then
                return 0
            fi
        else
            # Exact match
            if [[ "$file" == "$pattern" ]]; then
                return 0
            fi
        fi
    done

    return 1
}

# Find all markdown files, excluding .git and backup directories
# Use process substitution to avoid subshell issues with variables
while IFS= read -r -d '' md_file; do
    if ! is_file_allowed "$md_file"; then
        echo "WARNING: Markdown file in non-standard location: ${md_file}"
    fi
done < <(find . -type f -name "*.md" -not -path "./.git/*" -not -path "./.agenticdev-backup-*" -print0)
