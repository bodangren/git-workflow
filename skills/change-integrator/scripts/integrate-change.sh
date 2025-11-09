#!/bin/bash
# This script finalizes a completed task by integrating approved specs and cleaning up branches.

set -e

usage() {
    echo "Usage: $0 -p <pr-number> -b <branch-name> -i <item-id> -w <went-well> -l <lesson> [-c <change-dir>]"
    echo "  -p: The number of the pull request that was merged."
    echo "  -b: The name of the feature branch that was merged."
    echo "  -i: The project board item ID for the task."
    echo "  -w: What went well with this change."
    echo "  -l: What was learned from this change."
    echo "  -c: (Optional) The path to the original change proposal directory."
    exit 1
}

while getopts ":p:b:i:w:l:c:" opt; do
  case ${opt} in
    p ) PR_NUMBER=$OPTARG;;
    b ) BRANCH_NAME=$OPTARG;;
    i ) ITEM_ID=$OPTARG;;
    w ) WENT_WELL=$OPTARG;;
    l ) LESSON=$OPTARG;;
    c ) CHANGE_DIR=$OPTARG;;
    \? ) echo "Invalid option: $OPTARG" 1>&2; usage;; 
    : ) echo "Invalid option: $OPTARG requires an argument" 1>&2; usage;; 
  esac
done

if [ -z "$PR_NUMBER" ] || [ -z "$BRANCH_NAME" ] || [ -z "$ITEM_ID" ] || [ -z "$WENT_WELL" ] || [ -z "$LESSON" ]; then
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
git branch -D "$BRANCH_NAME" || true

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
gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id "$FIELD_ID" --single-select-option-id "$DONE_OPTION_ID" || true

# 6. Update Retrospective
echo "Updating retrospective..."

summarize_retrospective() {
    echo "RETROSPECTIVE.md has $(wc -l < RETROSPECTIVE.md) lines. Summarizing with Gemini..."

    # Isolate content to summarize
    local temp_summary_input="retro_to_summarize_$$.md" # Create in CWD
    awk '/^## Sprint 4/{f=1}f' RETROSPECTIVE.md > "$temp_summary_input"

    # Preserve the header and historical learnings
    local header_content
    header_content=$(awk '/^## Sprint 4/{exit}1' RETROSPECTIVE.md)

    # Call Gemini to summarize
    local summarized_sprints
    summarized_sprints=$(gemini -p "Summarize the following sprint retrospective entries into a more concise format, extracting the most important, recurring, or impactful learnings. Preserve the markdown structure with '### #PR' headers. @$temp_summary_input")

    # Clean up the temp file
    rm "$temp_summary_input"

    # Reconstruct the file
    echo "$header_content" > RETROSPECTIVE.md
    echo -e "\n## Summarized Sprints (via Gemini)\n" >> RETROSPECTIVE.md
    echo "$summarized_sprints" >> RETROSPECTIVE.md

    echo "Retrospective summarized and overwritten."
}

# Check current retrospective length and summarize if needed
if [ -f "RETROSPECTIVE.md" ]; then
    LINE_COUNT=$(wc -l < "RETROSPECTIVE.md")
    RETROSPECTIVE_MAX_LINES=150
    if [ "$LINE_COUNT" -gt $RETROSPECTIVE_MAX_LINES ]; then
        summarize_retrospective
    fi
fi

RETRO_ENTRY="### #$PR_NUMBER - $BRANCH_NAME\n\n- **Went well:** $WENT_WELL\n- **Lesson:** $LESSON\n"
echo -e "\n$RETRO_ENTRY" >> RETROSPECTIVE.md
git add RETROSPECTIVE.md
git commit -m "docs: Add retrospective for PR #$PR_NUMBER"

# 7. Push final changes
echo "Pushing final integration commits..."
git push

echo "Complete-change workflow finished for PR #$PR_NUMBER."
