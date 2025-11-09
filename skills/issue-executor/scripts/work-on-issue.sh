#!/bin/bash
# This script manages the core development loop for a single issue.

set -e

usage() {
    echo "Usage: $0 <issue-number>"
    exit 1
}

ISSUE_NUMBER=$1

if [ -z "$ISSUE_NUMBER" ]; then
    echo "Error: Issue number not provided." >&2
    usage
fi

# --- VALIDATION ---
if ! command -v jq &> /dev/null
then
    echo "Error: jq is not installed. Please install it to continue." >&2
    exit 1
fi

echo "Starting work on Issue #$ISSUE_NUMBER..."

# 1. Verify clean git state
echo "Verifying git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Please commit or stash changes." >&2
    exit 1
fi
echo "Git status is clean."

# 2. Synthesize Implementation Plan with Gemini
echo "Synthesizing implementation plan for Issue #$ISSUE_NUMBER with Gemini..."

# 2a. Read issue details from GitHub
echo "Fetching issue details..."
ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json title,body)
ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body')

# 2b. Find all associated spec files
echo "Finding associated spec files..."
# This pattern finds all markdown files in docs/specs and docs/changes
SPEC_FILES=$(echo "$ISSUE_BODY" | grep -o 'docs/\(specs\|changes\)/[^[:space:]`'"'"']*\.md')

# 2c. Construct the Gemini prompt
GEMINI_PROMPT="I am about to start work on GitHub issue #${ISSUE_NUMBER}. Here is all the context. Please provide a concise, step-by-step implementation plan.

**Issue Details:**
Title: ${ISSUE_TITLE}
Body:
${ISSUE_BODY}
"

# Add retrospective to prompt if it exists
if [ -f "RETROSPECTIVE.md" ]; then
    GEMINI_PROMPT+="\n**Retrospective Learnings:**\n@RETROSPECTIVE.md"
fi

# Add spec files to prompt
if [ -n "$SPEC_FILES" ]; then
    GEMINI_PROMPT+="\n\n**Referenced Specifications:**"
    for spec in $SPEC_FILES; do
        if [ -f "$spec" ]; then
            GEMINI_PROMPT+="\n@$spec"
        fi
    done
fi

# Add final instruction to prompt
GEMINI_PROMPT+="\n\nBased on all this context, what are the key steps I should take to implement this feature correctly, keeping in mind past learnings and adhering to the specifications? Provide a clear, actionable plan."

# 2d. Call Gemini
echo "------------------------- GEMINI IMPLEMENTATION PLAN -------------------------"
gemini -p "$GEMINI_PROMPT"
echo "----------------------------------------------------------------------------"
echo "Context loaded and implementation plan generated."

# 3. Create a feature branch
echo "Generating branch name..."
# Sanitize title to create a branch name
BRANCH_NAME=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed -e 's/task: //g' -e 's/[^a-z0-9]/-/g' -e 's/--/-/g' -e 's/^-//' -e 's/-$//')
BRANCH_NAME="feat/$ISSUE_NUMBER-$BRANCH_NAME"

echo "Creating new branch: $BRANCH_NAME..."
git checkout -b "$BRANCH_NAME"

echo "Setup complete. You are now on branch '$BRANCH_NAME' and ready to implement Issue #$ISSUE_NUMBER."