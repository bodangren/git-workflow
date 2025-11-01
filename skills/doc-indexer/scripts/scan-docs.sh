#!/bin/bash
# This script finds all markdown files in the docs/ directory, extracts the YAML frontmatter,
# reports any files that are missing frontmatter, and can output as JSON.

JSON_OUTPUT=false

usage() {
    echo "Usage: $0 [-j]"
    echo "  -j: Output the result as a JSON array."
    exit 1
}

while getopts ":j" opt; do
  case ${opt} in
    j )
      JSON_OUTPUT=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      ;;
  esac
done

if [ "$JSON_OUTPUT" = true ]; then
    echo "["
    first_entry=true
    while IFS= read -r -d '' file; do
        frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$file" | sed '1d')

        if [ "$first_entry" = false ]; then
            echo ","
        fi
        first_entry=false

        # Basic JSON escaping for file path
        escaped_file=$(echo "$file" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

        echo "  {"
        echo "    \"file\": \"$escaped_file\","
        if [ -n "$frontmatter" ]; then
            echo "    \"compliant\": true,"
            echo "    \"frontmatter\": {"
            # Basic YAML to JSON conversion
            echo "$frontmatter" | awk -F': ' 'NF>1{gsub(/"/, "\\\""); printf "      \"%s\": \"%s\",\n", $1, $2}' | sed '$ s/,$//'
            echo "    }"
        else
            echo "    \"compliant\": false,"
            echo "    \"frontmatter\": null"
        fi
        echo "  }"
    done < <(find docs -name "*.md" -print0)
    echo "]"
else
    while IFS= read -r -d '' file; do
        frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$file" | sed '1d')

        if [ -n "$frontmatter" ]; then
            echo "---"
            echo "file: $file"
            echo "$frontmatter"
        else
            echo "[WARNING] Non-compliant file (no frontmatter): $file"
        fi
    done < <(find docs -name "*.md" -print0)
fi
