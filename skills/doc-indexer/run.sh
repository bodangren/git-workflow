#!/bin/bash
# This script finds all markdown files in the docs/ directory, extracts the YAML frontmatter,
# and reports any files that are missing frontmatter.

echo "Indexing documentation frontmatter..."

find docs -name "*.md" -print0 | while IFS= read -r -d '\0' file; do
    if [ -f "$file" ]; then
        # Use awk to extract content between --- delimiters
        frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$file" | sed '1d')

        if [ -n "$frontmatter" ]; then
            echo "---"
            echo "file: $file"
            echo "$frontmatter"
        else
            echo "[WARNING] Non-compliant file (no frontmatter): $file"
        fi
    fi
done