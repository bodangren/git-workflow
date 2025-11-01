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

# 2. Load Context
echo "Loading context for Issue #$ISSUE_NUMBER..."

# 2a. Read issue details from GitHub
echo "Fetching issue details..."
ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json title,body)
ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body')

# 2b. Find and read the associated spec file
echo "Finding associated spec file..."
# This is a simplified pattern match. A more robust version would be needed for complex bodies.
SPEC_FILE=$(echo "$ISSUE_BODY" | grep -o 'docs/specs/[^[:space:]`'"'"']*')

if [ -n "$SPEC_FILE" ] && [ -f "$SPEC_FILE" ]; then
    echo "Found associated spec: $SPEC_FILE"
    cat "$SPEC_FILE"
else
    echo "No specific spec file linked in issue body."
fi

# 2c. Read the retrospective
echo "Reading RETROSPECTIVE.md..."
if [ -f "RETROSPECTIVE.md" ]; then
    cat RETROSPECTIVE.md
else
    echo "No RETROSPECTIVE.md file found."
fi

# 2d. Run the doc-indexer to get a map of all docs
echo "Running doc-indexer skill..."
if [ -f "skills/doc-indexer/scripts/scan-docs.sh" ]; then
    bash skills/doc-indexer/scripts/scan-docs.sh
else
    echo "Warning: doc-indexer skill not found."
fi

# 3. Create a feature branch
echo "Generating branch name..."
# Sanitize title to create a branch name
BRANCH_NAME=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed -e 's/task: //g' -e 's/[^a-z0-9]/-/g' -e 's/--/-/g' -e 's/^-//' -e 's/-$//')
BRANCH_NAME="feat/$ISSUE_NUMBER-$BRANCH_NAME"

echo "Creating new branch: $BRANCH_NAME..."
git checkout -b "$BRANCH_NAME"

echo "Setup complete. You are now on branch '$BRANCH_NAME' and ready to implement Issue #$ISSUE_NUMBER."