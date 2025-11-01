#!/bin/bash
# This script finalizes a completed task by integrating approved specs and cleaning up branches.

set -e

usage() {
    echo "Usage: $0 -p <pr-number> -b <branch-name> -i <item-id> [-c <change-dir>]"
    echo "  -p: The number of the pull request that was merged."
    echo "  -b: The name of the feature branch that was merged."
    echo "  -i: The project board item ID for the task."
    echo "  -c: (Optional) The path to the original change proposal directory."
    exit 1
}

while getopts ":p:b:i:c:" opt; do
  case ${opt} in
    p ) PR_NUMBER=$OPTARG;; 
    b ) BRANCH_NAME=$OPTARG;; 
    i ) ITEM_ID=$OPTARG;; 
    c ) CHANGE_DIR=$OPTARG;; 
    \? ) echo "Invalid option: $OPTARG" 1>&2; usage;; 
    : ) echo "Invalid option: $OPTARG requires an argument" 1>&2; usage;; 
  esac
done

if [ -z "$PR_NUMBER" ] || [ -z "$BRANCH_NAME" ] || [ -z "$ITEM_ID" ]; then
    usage
fi

# --- CONFIGURATION (should be detected dynamically in a future version) ---
PROJECT_ID="PVT_kwHOARC_Ns4BG9YU"
FIELD_ID="PVTSSF_lAHOARC_Ns4BG9YUzg32qas" # Workflow Stage
DONE_OPTION_ID="6bc77efe"

echo "Starting complete-change workflow for PR #$PR_NUMBER..."

# 1. Verify PR is merged
echo "Verifying PR status..."
if ! gh pr view "$PR_NUMBER" --json state | grep -q '"state":"MERGED"'; then
    echo "Error: PR #$PR_NUMBER is not merged. Aborting." >&2
    exit 1
fi
echo "PR #$PR_NUMBER is confirmed as merged."

# 2. Checkout main and pull
echo "Switching to main and pulling latest changes..."
git checkout main
git pull

# 3. Delete merged branch
echo "Deleting merged branch: $BRANCH_NAME..."
git push origin --delete "$BRANCH_NAME" || echo "Remote branch $BRANCH_NAME may have already been deleted."
git branch -D "$BRANCH_NAME"

# 4. Integrate Spec (if a change directory was provided)
if [ -n "$CHANGE_DIR" ] && [ -d "$CHANGE_DIR" ]; then
    echo "Integrating spec files from $CHANGE_DIR..."
    # A more robust script would combine files; for now, we just move the delta.
    SPEC_FILE_NAME=$(basename "$CHANGE_DIR").md
    mv "$CHANGE_DIR/spec-delta.md" "docs/specs/$SPEC_FILE_NAME"
    rm -r "$CHANGE_DIR"
    git add docs/
git commit -m "docs: Integrate approved spec from $BRANCH_NAME"
else
    echo "No spec change directory provided or found, skipping spec integration."
fi

# 5. Update Project Board
echo "Updating project board for item $ITEM_ID..."
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id "$FIELD_ID" --single-select-option-id "$DONE_OPTION_ID"

# 6. Update Retrospective
echo "Updating retrospective..."
# In a real implementation, this would be a more interactive process.
RETRO_ENTRY="### #$PR_NUMBER - $BRANCH_NAME\n\n- **Went well:** The auto-merge workflow completed successfully.\n- **Lesson:** N/A\n"
echo -e "\n$RETRO_ENTRY" >> RETROSPECTIVE.md
git add RETROSPECTIVE.md
git commit -m "docs: Add retrospective for PR #$PR_NUMBER"

# 7. Push final changes
echo "Pushing final integration commits..."
git push

echo "Complete-change workflow finished for PR #$PR_NUMBER."