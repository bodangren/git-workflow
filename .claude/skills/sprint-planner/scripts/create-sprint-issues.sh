#!/bin/bash
# This script plans a new sprint by creating a milestone and generating task issues from a tasks.yml file.

set -e

# --- USAGE ---
usage() {
    echo "Usage: $0 [TASKS_FILE]"
    echo "  TASKS_FILE: Path to the tasks.yml file (default: docs/changes/sprint-7-framework-improvements/tasks.yml)"
    exit 1
}

# Parse command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

TASKS_FILE="${1:-docs/changes/sprint-7-framework-improvements/tasks.yml}"

# --- CONFIGURATION ---
# In a real scenario, this should be detected dynamically from the git remote URL
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# --- VALIDATION ---
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed. Please install it to continue." >&2
    exit 1
fi
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install it to continue." >&2
    exit 1
fi
if [ ! -f "$TASKS_FILE" ]; then
    echo "Error: Tasks file not found at $TASKS_FILE" >&2
    exit 1
fi

# Validate YAML structure
echo "Validating tasks.yml structure..."
if ! yq '.' "$TASKS_FILE" > /dev/null 2>&1; then
    echo "Error: Invalid YAML syntax in $TASKS_FILE" >&2
    exit 1
fi

# Check for required root-level 'epic' field
if ! yq '.epic' "$TASKS_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required 'epic' field in $TASKS_FILE" >&2
    exit 1
fi

# Check for required root-level 'tasks' array
if ! yq '.tasks' "$TASKS_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required 'tasks' array in $TASKS_FILE" >&2
    exit 1
fi

TASK_COUNT=$(yq '.tasks | length' "$TASKS_FILE")
if [ "$TASK_COUNT" -eq 0 ]; then
    echo "Error: No tasks found in $TASKS_FILE" >&2
    exit 1
fi

echo "✓ Validated YAML structure with $TASK_COUNT tasks"

# --- SCRIPT LOGIC ---

echo "Planning new sprint from $TASKS_FILE..."

# 1. Get Epic title from the tasks file
EPIC_TITLE=$(yq -r '.epic' "$TASKS_FILE")
echo "Found Epic: $EPIC_TITLE"

# 2. Create or verify the Sprint milestone
read -p "Enter the name for the new sprint milestone (e.g., 'Sprint 1: Framework Improvements'): " SPRINT_NAME
if [ -z "$SPRINT_NAME" ]; then
    echo "Error: Milestone name cannot be empty." >&2
    exit 1
fi

echo "Checking for milestone: $SPRINT_NAME"
EXISTING_MILESTONE=$(gh api "/repos/$REPO/milestones" | jq -r --arg name "$SPRINT_NAME" '.[] | select(.title == $name) | .title')

if [ "$EXISTING_MILESTONE" == "$SPRINT_NAME" ]; then
    echo "Milestone '$SPRINT_NAME' already exists. Using existing milestone."
else
    echo "Creating new milestone: $SPRINT_NAME"
    gh api --method POST -H "Accept: application/vnd.github.v3+json" "/repos/$REPO/milestones" -f title="$SPRINT_NAME"
    echo "Milestone '$SPRINT_NAME' created."
fi

# 3. Create an Epic Issue for the entire sprint
echo "Creating parent Epic issue..."
EPIC_BODY="This Epic tracks all work for the '$SPRINT_NAME' sprint. All tasks below are part of this epic."
EPIC_ISSUE_URL=$(gh issue create --title "$EPIC_TITLE" --body "$EPIC_BODY" --milestone "$SPRINT_NAME")
EPIC_ISSUE_NUMBER=$(echo "$EPIC_ISSUE_URL" | awk -F'/' '{print $NF}')
echo "Parent Epic issue #$EPIC_ISSUE_NUMBER created."

# 4. Ensure all labels exist
echo "Ensuring all necessary labels exist..."
ALL_LABELS=$(yq -r '.tasks[].labels | .type + "\n" + .component + "\n" + (.priority // "")' "$TASKS_FILE" | sort -u | grep -v '^$')

while IFS= read -r label; do
    if [ -n "$label" ]; then
        echo "  - Ensuring label '$label' exists..."
        # Assign a color based on the label type for better visual organization
        color="D4C5F9" # default purple
        if [[ "$label" == P* ]]; then color="B60205"; fi # red for priority
        if [[ "$label" == "feature" ]]; then color="0E8A16"; fi # green
        if [[ "$label" == "enhancement" ]]; then color="5319E7"; fi # purple
        if [[ "$label" == "bug" ]]; then color="B60205"; fi # red
        if [[ "$label" == "docs" ]]; then color="0075CA"; fi # blue
        if [[ "$label" == "refactor" || "$label" == "chore" ]]; then color="FBCA04"; fi # yellow
        
        gh label create "$label" --color "$color" --description "Auto-created for sprint planning" || true
    fi
done <<< "$ALL_LABELS"
echo "Label setup complete."

# 5. Load context from RETROSPECTIVE.md to inform better task creation
echo "Loading context from RETROSPECTIVE.md..."
RETROSPECTIVE_FILE="RETROSPECTIVE.md"
if [ -f "$RETROSPECTIVE_FILE" ]; then
    echo "✓ Found RETROSPECTIVE.md with past learnings"
    # Count recent learnings to inform user about context
    RECENT_LEARNINGS=$(grep -c "^### #[0-9]" "$RETROSPECTIVE_FILE" 2>/dev/null || echo "0")
    echo "  - Contains $RECENT_LEARNINGS completed issues with learnings"
else
    echo "⚠ RETROSPECTIVE.md not found - no historical context available"
fi

# 6. Parse the tasks.yml file and create an issue for each task
echo "Creating issues for all tasks..."

# Use yq to output each task's fields separated by a pipe for safe reading
yq -r '.tasks[] | .title +"|" + .description +"|" + .labels.type +"|" + .labels.component +"|" + (.labels.priority // "")' "$TASKS_FILE" | while IFS='|' read -r title description type component priority;

do

    echo "---"
    echo "Processing task: $title"

    # Validate required fields
    if [ -z "$title" ]; then
        echo "Error: Task missing required 'title' field. Skipping." >&2
        continue
    fi

    if [ -z "$description" ]; then
        echo "Error: Task '$title' missing required 'description' field. Skipping." >&2
        continue
    fi

    if [ -z "$type" ]; then
        echo "Error: Task '$title' missing required 'labels.type' field. Skipping." >&2
        continue
    fi

    if [ -z "$component" ]; then
        echo "Error: Task '$title' missing required 'labels.component' field. Skipping." >&2
        continue
    fi

    # Construct the issue body
    BODY=$(printf "%s\n\n**Parent Epic:** #%s" "$description" "$EPIC_ISSUE_NUMBER")

    # Construct the labels string (priority is optional)
    if [ -n "$priority" ]; then
        LABELS="$type,$component,$priority"
    else
        LABELS="$type,$component"
    fi

    # --- DEBUGGING ---
    echo "  - Title: $title"
    echo "  - Body: $BODY"
    echo "  - Milestone: $SPRINT_NAME"
    echo "  - Labels: $LABELS"
    # --- END DEBUGGING ---

    # Create the GitHub issue
    gh issue create --title "$title" --body "$BODY" --milestone "$SPRINT_NAME" --label "$LABELS"

done

echo "-------------------------------------------------"
echo "Sprint planning complete!"
echo "All tasks from $TASKS_FILE have been created as GitHub issues in the '$SPRINT_NAME' milestone."
echo "View the milestone here: https://github.com/$REPO/milestones"
