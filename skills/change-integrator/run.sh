#!/bin/bash
# This script finalizes a completed task by integrating approved specs and cleaning up branches.

set -e

# --- PLACEHOLDERS (In a real run, these would be dynamic arguments) ---
PR_NUMBER="23"
BRANCH_NAME="feat/16-implement-sprint-planner"
CHANGE_DIR="docs/changes/003-implement-sprint-planner"
SPEC_FILE="docs/specs/003-implement-sprint-planner.md"
ITEM_ID="PVTI_lAHOARC_Ns4BG9YUzggmXPI"

echo "Starting complete-change workflow for PR #$PR_NUMBER..."

# 1. Verify PR is merged
# In a real script, we would parse this output to confirm.
echo "Verifying PR status..."
gh pr status

# 2. Checkout main and pull
echo "Switching to main and pulling latest changes..."
git checkout main
git pull

# 3. Delete merged branch
echo "Deleting merged branch: $BRANCH_NAME..."
git push origin --delete "$BRANCH_NAME"
git branch -D "$BRANCH_NAME"

# 4. Integrate Spec
echo "Integrating spec files..."
# This is a placeholder. A real script would combine the proposal files.
mv "$CHANGE_DIR/spec-delta.md" "$SPEC_FILE"
rm -r "$CHANGE_DIR"

# 5. Update Project Board
# This uses placeholder IDs. A real script would fetch these dynamically.
FIELD_ID="PVTSSF_lAHOARC_Ns4BG9YUzg32qas" # Workflow Stage
OPTION_ID="6bc77efe" # Done
PROJECT_ID="PVT_kwHOARC_Ns4BG9YU"
echo "Updating project board..."
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id "$FIELD_ID" --single-select-option-id "$OPTION_ID"

# 6. Commit and Push integration changes
echo "Committing spec integration..."
git add docs/
git commit -m "docs: Integrate approved spec for $BRANCH_NAME"

# 7. Update Retrospective
echo "(Placeholder: A real script would prompt for retrospective notes and append to RETROSPECTIVE.md)"

# 8. Push final changes
git push

echo "Complete-change workflow finished."
