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

# 5. Parse the tasks from the spec file and create issues
echo "Parsing tasks from $SPEC_FILE and creating issues..."
# This awk script will find lines starting with '- [ ]' and extract the title
awk -F'**|:**' '/^- \[ \]/{gsub(/^ *| *$/, "", $2); print $2}' "$SPEC_FILE" | while read -r task_title; do
    if [ -n "$task_title" ]; then
        echo "Creating issue for task: $task_title"
        gh issue create --title "TASK: $task_title" --body "From spec: '$SPEC_FILE'. Parent Epic: #$SELECTED_EPIC_NUMBER" --milestone "$SPRINT_NAME"
    fi
done

echo "Sprint planning complete. Issues have been created and assigned to milestone '$SPRINT_NAME'."