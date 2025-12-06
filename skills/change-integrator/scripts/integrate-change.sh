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

if [ -z "$PR_NUMBER" ] || [ -z "$BRANCH_NAME" ]; then
    echo "Error: PR Number (-p) and Branch Name (-b) are required."
    usage
fi

# Auto-generate learnings if missing
if [ -z "$WENT_WELL" ] || [ -z "$LESSON" ]; then
    echo "Learnings missing. Generating from PR context..."
    PR_BODY=$(gh pr view "$PR_NUMBER" --json body,title -q '.title + "\n" + .body')
    
    # Simple one-shot generation
    GENERATED_JSON=$(gemini -p "Analyze this PR description and extract: 1. One sentence on what went well. 2. One key lesson learned. Output JSON: {\"well\": \"...\", \"lesson\": \"...\"} \n\n $PR_BODY")
    
    WENT_WELL=$(echo "$GENERATED_JSON" | jq -r '.well')
    LESSON=$(echo "$GENERATED_JSON" | jq -r '.lesson')
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
if [ -n "$ITEM_ID" ]; then
    echo "Updating project board for item $ITEM_ID..."
    gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id "$FIELD_ID" --single-select-option-id "$DONE_OPTION_ID" || true
else
    echo "No project board item ID provided, skipping project board update."
fi

# 5b. Close Linked Issue
echo "Closing linked issue..."
# Try to find the linked issue from the PR
LINKED_ISSUE=$(gh pr view "$PR_NUMBER" --json closingIssuesReferences -q '.closingIssuesReferences[0].number')

if [ -n "$LINKED_ISSUE" ] && [ "$LINKED_ISSUE" != "null" ]; then
    echo "Closing linked issue #$LINKED_ISSUE..."
    gh issue close "$LINKED_ISSUE" --comment "Issue closed via PR #$PR_NUMBER integration." || true
else
    echo "No linked issue found in PR metadata. Please verify issue #$PR_NUMBER status manually."
fi

# 6. Update Retrospective
echo "Updating retrospective..."

summarize_retrospective() {
    echo "RETROSPECTIVE.md has $(wc -l < RETROSPECTIVE.md) lines. Summarizing with Gemini..."

    # Isolate content to summarize - Keep the header (first 10 lines approx) and the last 3 entries intact
    # Everything in between gets summarized.
    local temp_summary_input="retro_to_summarize_$$.md"
    
    # Find line number of the "Historical Learnings" header
    local start_line=$(grep -n "## Historical Learnings" RETROSPECTIVE.md | cut -d: -f1)
    if [ -z "$start_line" ]; then start_line=5; fi
    
    # Find line number of the 5th most recent entry (assuming ### format)
    local end_line=$(grep -n "###" RETROSPECTIVE.md | tail -n 5 | head -n 1 | cut -d: -f1)
    if [ -z "$end_line" ]; then end_line=$(wc -l < RETROSPECTIVE.md); fi

    # Extract the middle chunk
    sed -n "$((start_line + 1)),$((end_line - 1))p" RETROSPECTIVE.md > "$temp_summary_input"

    # Preserve Header
    local header_content
    header_content=$(head -n "$start_line" RETROSPECTIVE.md)
    
    # Preserve Recent Entries
    local recent_content
    recent_content=$(tail -n "+$end_line" RETROSPECTIVE.md)

    # Call Gemini to summarize
    local summarized_sprints
    summarized_sprints=$(gemini -p "Summarize the following sprint retrospective entries into a more concise format, extracting the most important, recurring, or impactful learnings. Preserve the markdown structure with '### #PR' headers. @$temp_summary_input")

    # Clean up the temp file
    rm "$temp_summary_input"

    # Reconstruct the file
    echo "$header_content" > RETROSPECTIVE.md
    echo -e "\n$summarized_sprints\n" >> RETROSPECTIVE.md
    echo "$recent_content" >> RETROSPECTIVE.md

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

# Generate retrospective entry using LLM
echo "Generating retrospective entry with LLM..."
LLM_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/summarize_retrospective_llm.py"

# Try to generate summary with LLM
if [ -f "$LLM_SCRIPT" ]; then
    LLM_SUMMARY=$(python3 "$LLM_SCRIPT" --went-well "$WENT_WELL" --lesson-learned "$LESSON" 2>&1)
    LLM_EXIT_CODE=$?

    if [ $LLM_EXIT_CODE -eq 0 ] && [ -n "$LLM_SUMMARY" ]; then
        # LLM call succeeded - use structured format with details tag
        echo "✓ LLM summary generated successfully."
        RETRO_ENTRY="### #$PR_NUMBER - $BRANCH_NAME\n\n$LLM_SUMMARY\n\n<details>\n<summary>Original inputs</summary>\n\n- **Went well:** $WENT_WELL\n- **Lesson:** $LESSON\n</details>\n"
    else
        # LLM call failed - fall back to original format
        echo "⚠️  LLM summary generation failed, using original format."
        RETRO_ENTRY="### #$PR_NUMBER - $BRANCH_NAME\n\n- **Went well:** $WENT_WELL\n- **Lesson:** $LESSON\n"
    fi
else
    # Script not found - fall back to original format
    echo "⚠️  LLM script not found at $LLM_SCRIPT, using original format."
    RETRO_ENTRY="### #$PR_NUMBER - $BRANCH_NAME\n\n- **Went well:** $WENT_WELL\n- **Lesson:** $LESSON\n"
fi

echo -e "\n$RETRO_ENTRY" >> RETROSPECTIVE.md
git add RETROSPECTIVE.md
git commit -m "docs: Add retrospective for PR #$PR_NUMBER"

# 7. Push final changes
echo "Pushing final integration commits..."
git push

echo "Complete-change workflow finished for PR #$PR_NUMBER."
