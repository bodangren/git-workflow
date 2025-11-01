#!/bin/bash
# This script plans a new sprint by creating a milestone and generating task issues from an approved spec.

set -e

# --- CONFIGURATION ---
PROJECT_ID="1" # The ID of the GitHub Project Board
APPROVED_BACKLOG_ID="888736cd" # The ID for the 'Approved Backlog' column

# 1. Get items from the Approved Backlog
# In a real implementation, we would parse this JSON to get the list of Epics.
echo "Querying for approved Epics in the backlog..."
gh project item-list "$PROJECT_ID" --owner "@me" --format json > approved_epics.json
echo "(Placeholder: In a real run, user would select from list of Epics in approved_epics.json)"

# 2. For the selected Epic, find the corresponding spec file.
# (Placeholder logic: This would involve parsing the Epic title or body to find the spec path)
SELECTED_EPIC_URL="https://github.com/bodangren/git-workflow/issues/12"
SPEC_FILE="docs/specs/002-implement-core-skills.md"
echo "Selected Epic: $SELECTED_EPIC_URL"
echo "Found corresponding spec: $SPEC_FILE"

# 3. Create a new Sprint milestone.
# (Placeholder logic: Sprint name would be dynamic)
SPRINT_NAME="Sprint 2"
echo "Creating new milestone: $SPRINT_NAME"
gh api --method POST -H "Accept: application/vnd.github.v3+json" /repos/bodangren/git-workflow/milestones -f title="$SPRINT_NAME"

# 4. Parse the tasks from the spec file and create issues.
# (Placeholder logic: This would parse the markdown file for checklist items)
echo "Parsing tasks from $SPEC_FILE and creating issues..."

# Example of creating one issue. A real script would loop over all tasks.
gh issue create --title "TASK: Implement project-init skill" --body "From spec: $SPEC_FILE. Parent Epic: $SELECTED_EPIC_URL" --milestone "$SPRINT_NAME"

echo "Sprint planning complete. Issues have been created and assigned to milestone '$SPRINT_NAME'."

# Clean up temporary file
rm approved_epics.json
