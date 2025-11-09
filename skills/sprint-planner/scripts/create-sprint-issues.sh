#!/bin/bash
# This script plans a new sprint by creating a milestone and generating task issues from an approved spec.

set -e

# --- CONFIGURATION ---
PROJECT_NUMBER="1"
APPROVED_BACKLOG_ID="888736cd"
OWNER="@me"
# In a real scenario, this should be detected dynamically from the git remote URL
REPO="bodangren/git-workflow"

# --- VALIDATION ---
if ! command -v jq &> /dev/null
then
    echo "Error: jq is not installed. Please install it to continue." >&2
    exit 1
fi

# --- SCRIPT LOGIC ---

echo "Planning new sprint..."

# 1. Get items from the Approved Backlog and let the user select
echo "Querying for approved Epics in the backlog..."
EPIC_JSON=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq --arg backlog_id "$APPROVED_BACKLOG_ID" '[.items[] | select(."workflow Stage".id == $backlog_id)]')

if [ "$(echo "$EPIC_JSON" | jq 'length')" -eq 0 ]; then
    echo "No approved Epics found in the backlog. Nothing to plan."
    exit 0
fi

echo "The following Epics are ready to be planned:"
echo "$EPIC_JSON" | jq -r '.[] | "- #\(.content.number): \(.content.title)''

read -p "Enter the issue number of the Epic to plan (e.g., 28): " SELECTED_EPIC_NUMBER

# 2. Get details for the selected Epic
SELECTED_EPIC_JSON=$(echo "$EPIC_JSON" | jq --argjson epic_num "$SELECTED_EPIC_NUMBER" '.[] | select(.content.number == $epic_num)')
SELECTED_EPIC_URL=$(echo "$SELECTED_EPIC_JSON" | jq -r '.content.url')
EPIC_BODY=$(echo "$SELECTED_EPIC_JSON" | jq -r '.content.body')

# 3. Find the corresponding spec file from the Epic body
# This is a simplified pattern match. A more robust version would be needed for complex bodies.
SPEC_FILE=$(echo "$EPIC_BODY" | grep -o "docs/specs/[^[:space:]`]*")

if [ ! -f "$SPEC_FILE" ]; then
    echo "Error: Could not find a valid spec file in the body of Epic #$SELECTED_EPIC_NUMBER." >&2
    exit 1
fi
echo "Found corresponding spec: $SPEC_FILE"

# 4. Create a new Sprint milestone
read -p "Enter the name for the new sprint milestone (e.g., 'Sprint 3'): " SPRINT_NAME
echo "Creating new milestone: $SPRINT_NAME"
gh api --method POST -H "Accept: application/vnd.github.v3+json" "/repos/$REPO/milestones" -f title="$SPRINT_NAME"

# 5. Decompose the spec into tasks using Gemini and create issues
echo "Decomposing spec file $SPEC_FILE into tasks with Gemini..."

EPIC_TITLE=$(echo "$SELECTED_EPIC_JSON" | jq -r '.content.title')

GEMINI_PROMPT="Read the following specification document and the parent epic. Your task is to decompose this spec into a list of atomic, actionable tasks for a GitHub sprint. For each task, provide a clear, imperative title and a brief one-sentence description.

Format the output as a simple, machine-readable list, with each task on a new line, formatted as:
**Title:** A brief, clear title for the task.
**Description:** A one-sentence description of what needs to be done.
---

Here is the parent epic:
Title: ${EPIC_TITLE}
Body:
${EPIC_BODY}

Here is the full specification document:
@${SPEC_FILE}
"

# Call Gemini and parse the output
gemini_output=$(gemini -p "$GEMINI_PROMPT")

# Process the output using awk for more robust parsing
echo "$gemini_output" | awk -v spec_file="$SPEC_FILE" -v epic_number="$SELECTED_EPIC_NUMBER" -v sprint_name="$SPRINT_NAME" '
BEGIN { RS = "---\n" }
{
    title = ""
    desc = ""
    # Use a loop to handle fields that might be out of order
    for (i = 1; i <= NF; i++) {
        if ($i ~ /\*\*Title:\*\*/) {
            # Reconstruct the line from the field onwards to capture the full title
            title_line = $i
            for (j = i + 1; j <= NF; j++) {
                title_line = title_line " " $j
            }
            sub(/.*\*\*Title:\*\* /, "", title_line)
            title = title_line
        }
        if ($i ~ /\*\*Description:\*\*/) {
            # Reconstruct the line from the field onwards to capture the full description
            desc_line = $i
            for (j = i + 1; j <= NF; j++) {
                desc_line = desc_line " " $j
            }
            sub(/.*\*\*Description:\*\* /, "", desc_line)
            desc = desc_line
        }
    }
    
    # Clean up any potential newlines within the captured title/desc
    gsub(/\n/, " ", title)
    gsub(/\n/, " ", desc)
    
    if (title != "" && desc != "") {
        # Escape quotes for the shell command
        gsub(/"/, "\\\"", title)
        gsub(/"/, "\\\"", desc)
        
        # Construct the shell command to create the issue
        command = "gh issue create --title \"TASK: " title "\" --body \"" desc ".\\n\\nFrom spec: '"'"'" spec_file "'"'"'.\\nParent Epic: #" epic_number "'\" --milestone \"'"'"'" sprint_name "'"'"'\""
        
        # Print a user-friendly message and then execute the command
        print "echo \"Creating issue for task: " title "\""
        print command
    }
}' | sh

echo "Sprint planning complete. Issues have been created and assigned to milestone '$SPRINT_NAME'."