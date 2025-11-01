#!/bin/bash
# This script manages the core development loop for a single issue.

set -e

ISSUE_NUMBER=$1

if [ -z "$ISSUE_NUMBER" ]; then
    echo "Error: Issue number not provided."
    echo "Usage: $0 <issue-number>"
    exit 1
fi

echo "Starting work on Issue #$ISSUE_NUMBER..."

# 1. Verify clean git state
echo "Verifying git status..."
# git status --porcelain will be empty if clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Please commit or stash changes."
    exit 1
fi
echo "Git status is clean."

# 2. Load Context
echo "Loading context for Issue #$ISSUE_NUMBER..."

# 2a. Read issue details from GitHub
# In a real script, we would parse this JSON.
echo "Fetching issue details..."
gh issue view "$ISSUE_NUMBER" --json title,body

# 2b. Find and read the associated spec file
# (Placeholder logic: This would parse the issue body or use the Epic to find the spec)
SPEC_FILE="docs/specs/002-implement-core-skills.md"
echo "Found associated spec: $SPEC_FILE"

# 2c. Read the retrospective
echo "Reading RETROSPECTIVE.md..."
cat RETROSPECTIVE.md

# 2d. Run the doc-indexer to get a map of all docs
echo "Running doc-indexer skill..."
./skills/doc-indexer/run.sh

# 3. Create a feature branch
# (Placeholder logic: This would generate the branch name from the issue title)
BRANCH_NAME="feat/$ISSUE_NUMBER-refactor-issue-executor"
echo "Creating new branch: $BRANCH_NAME..."
git checkout -b "$BRANCH_NAME"

echo "Setup complete. You are now on branch '$BRANCH_NAME' and ready to implement Issue #$ISSUE_NUMBER."
