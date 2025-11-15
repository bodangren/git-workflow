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
    # Use a temporary file to store the JSON objects
    json_objects_file=$(mktemp)
    
    while IFS= read -r -d '' file; do
        frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$file" | sed '1d')

        # Basic JSON escaping for file path
        escaped_file=$(echo "$file" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

        json_object="{"
        json_object+="\"file\": \"$escaped_file\","
        if [ -n "$frontmatter" ]; then
            json_object+="\"compliant\": true,"
            json_object+="\"frontmatter\": {"
            
            # Convert YAML to JSON:
            # 1. Remove leading/trailing whitespace
            # 2. Escape double quotes
            # 3. Add quotes around keys and values
            # 4. Join with commas
            frontmatter_json=$(echo "$frontmatter" | sed -e 's/^[ \t]*//;s/[ \t]*$//' | awk -F': ' 'NF>1{gsub(/"/, "\\\""); printf "\"%s\": \"%s\",", $1, $2}' | sed 's/,$//')
            
            json_object+="$frontmatter_json"
            json_object+="}"
        else
            json_object+="\"compliant\": false,"
            json_object+="\"frontmatter\": null"
        fi
        json_object+="}"
        
        echo "$json_object" >> "$json_objects_file"
    done < <(find docs -name "*.md" -print0)

    # Now, assemble the final JSON array
    echo "["
    if [ -s "$json_objects_file" ]; then
        paste -sd, "$json_objects_file"
    fi
    echo "]"
    
    # Clean up the temporary file
    rm "$json_objects_file"
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
