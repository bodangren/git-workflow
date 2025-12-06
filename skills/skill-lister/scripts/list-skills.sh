#!/bin/bash
# This script scans the .claude/skills/ directory, extracts metadata from SKILL.md files,
# and lists all available skills with their scripts.

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

SKILLS_DIR=".claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Error: Skills directory not found at $SKILLS_DIR"
    exit 1
fi

if [ "$JSON_OUTPUT" = true ]; then
    # Use a temporary file to store the JSON objects
    json_objects_file=$(mktemp)

    for skill_dir in "$SKILLS_DIR"/*/; do
        # Skip if not a directory
        [ -d "$skill_dir" ] || continue

        skill_name=$(basename "$skill_dir")
        skill_md="$skill_dir/SKILL.md"
        scripts_dir="$skill_dir/scripts"

        # Basic JSON escaping for skill name and paths
        escaped_skill_name=$(echo "$skill_name" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        escaped_skill_dir=$(echo "$skill_dir" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

        json_object="{"
        json_object+="\"skill\": \"$escaped_skill_name\","
        json_object+="\"directory\": \"$escaped_skill_dir\","

        # Extract frontmatter from SKILL.md if it exists
        if [ -f "$skill_md" ]; then
            frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$skill_md" | sed '1d')

            if [ -n "$frontmatter" ]; then
                json_object+="\"metadata\": {"

                # Extract name and description from frontmatter
                name=$(echo "$frontmatter" | grep "^name:" | sed 's/^name: *//' | sed 's/"/\\"/g')
                description=$(echo "$frontmatter" | grep "^description:" | sed 's/^description: *//' | sed 's/"/\\"/g')

                json_object+="\"name\": \"$name\","
                json_object+="\"description\": \"$description\""
                json_object+="},"
            else
                json_object+="\"metadata\": null,"
            fi
        else
            json_object+="\"metadata\": null,"
        fi

        # List scripts if scripts directory exists
        json_object+="\"scripts\": ["
        if [ -d "$scripts_dir" ]; then
            script_list=""
            for script in "$scripts_dir"/*; do
                if [ -f "$script" ]; then
                    escaped_script=$(echo "$script" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
                    script_list+="\"$escaped_script\","
                fi
            done
            # Remove trailing comma
            script_list=$(echo "$script_list" | sed 's/,$//')
            json_object+="$script_list"
        fi
        json_object+="]"

        json_object+="}"

        echo "$json_object" >> "$json_objects_file"
    done

    # Now, assemble the final JSON array
    echo "["
    if [ -s "$json_objects_file" ]; then
        paste -sd, "$json_objects_file"
    fi
    echo "]"

    # Clean up the temporary file
    rm "$json_objects_file"
else
    # Human-readable output
    echo "=== Available AgenticDev Skills ==="
    echo ""

    for skill_dir in "$SKILLS_DIR"/*/; do
        # Skip if not a directory
        [ -d "$skill_dir" ] || continue

        skill_name=$(basename "$skill_dir")
        skill_md="$skill_dir/SKILL.md"
        scripts_dir="$skill_dir/scripts"

        echo "---"
        echo "Skill: $skill_name"
        echo "Location: $skill_dir"

        # Extract frontmatter from SKILL.md if it exists
        if [ -f "$skill_md" ]; then
            frontmatter=$(awk '/^---$/{if(c>0){exit} c++} c>0' "$skill_md" | sed '1d')

            if [ -n "$frontmatter" ]; then
                name=$(echo "$frontmatter" | grep "^name:" | sed 's/^name: *//')
                description=$(echo "$frontmatter" | grep "^description:" | sed 's/^description: *//')

                [ -n "$name" ] && echo "Name: $name"
                [ -n "$description" ] && echo "Description: $description"
            else
                echo "[WARNING] No frontmatter found in SKILL.md"
            fi
        else
            echo "[WARNING] No SKILL.md file found"
        fi

        # List scripts if scripts directory exists
        if [ -d "$scripts_dir" ]; then
            script_count=$(find "$scripts_dir" -maxdepth 1 -type f | wc -l)
            if [ "$script_count" -gt 0 ]; then
                echo "Scripts:"
                for script in "$scripts_dir"/*; do
                    if [ -f "$script" ]; then
                        script_name=$(basename "$script")
                        echo "  - $script"
                    fi
                done
            else
                echo "Scripts: None found"
            fi
        else
            echo "[WARNING] No scripts directory found"
        fi

        echo ""
    done
fi
