# Close Issue Command

Clean up after a merged PR and update all tracking files.

## Purpose

Complete the workflow lifecycle by cleaning up branches, closing issues, and updating tracking documentation after a PR merges successfully.

## When to Use

- After PR is merged to main
- Completing the issue lifecycle
- Cleaning up feature branches
- Updating project tracking

## Prerequisites

- [ ] PR must be merged (not just approved)
- [ ] All CI checks passed
- [ ] No pending changes on feature branch

## Workflow

### 1. Verify PR is Merged

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# If already on main, ask for issue number
if [ "$CURRENT_BRANCH" = "main" ]; then
  read -p "Enter issue number to close: " ISSUE_NUMBER

  # Find the feature branch from issue
  FEATURE_BRANCH=$(gh pr list --state merged --search "#$ISSUE_NUMBER" --json headRefName --jq '.[0].headRefName')

  if [ -z "$FEATURE_BRANCH" ]; then
    echo "⚠ Error: Cannot find merged PR for issue #$ISSUE_NUMBER"
    exit 1
  fi
else
  # Extract issue number from branch name
  ISSUE_NUMBER=$(echo "$CURRENT_BRANCH" | sed -E 's/(feat|fix|chore|refactor)\/([0-9]+).*/\2/')
  FEATURE_BRANCH="$CURRENT_BRANCH"
fi

echo "Issue: #$ISSUE_NUMBER"
echo "Branch: $FEATURE_BRANCH"

# Check PR status
PR_NUMBER=$(gh pr list --state merged --head "$FEATURE_BRANCH" --json number --jq '.[0].number')

if [ -z "$PR_NUMBER" ]; then
  echo "⚠ Error: No merged PR found for branch $FEATURE_BRANCH"
  echo ""
  echo "Check PR status:"
  echo "  gh pr list --head $FEATURE_BRANCH"
  echo ""
  echo "If PR is not merged yet, wait for merge before running close-issue"
  exit 1
fi

echo "PR: #$PR_NUMBER"

# Get PR status
PR_STATUS=$(gh pr view $PR_NUMBER --json state,mergedAt,mergeCommit --jq '{state, mergedAt, mergeCommit: .mergeCommit.oid}')

if [ "$(echo "$PR_STATUS" | jq -r .state)" != "MERGED" ]; then
  echo "⚠ Error: PR #$PR_NUMBER is not merged yet"
  echo "Current status: $(echo "$PR_STATUS" | jq -r .state)"
  echo ""
  echo "Wait for PR to merge, then run close-issue again"
  exit 1
fi

echo "✓ PR is merged"
```

### 2. Get PR Details for Documentation

```bash
# Get merge details
MERGE_COMMIT=$(echo "$PR_STATUS" | jq -r .mergeCommit)
MERGED_DATE=$(echo "$PR_STATUS" | jq -r .mergedAt | cut -d'T' -f1)
PR_TITLE=$(gh pr view $PR_NUMBER --json title --jq .title)

echo "Merge commit: $MERGE_COMMIT"
echo "Merged date: $MERGED_DATE"
```

### 3. Switch to Main Branch

```bash
echo ""
echo "Switching to main branch..."

git checkout main

if [ $? -ne 0 ]; then
  echo "❌ Failed to switch to main"
  exit 1
fi

echo "✓ On main branch"
```

### 4. Pull Latest Changes

```bash
echo ""
echo "Pulling latest changes..."

git pull --ff-only origin main

if [ $? -ne 0 ]; then
  echo "❌ Failed to pull main"
  echo ""
  echo "Try:"
  echo "  git pull --rebase origin main"
  exit 1
fi

echo "✓ Main branch updated"
```

### 5. Verify Merge Commit Exists

```bash
# Check that merge commit is present
if git log --oneline | grep -q "$MERGE_COMMIT"; then
  echo "✓ Merge commit found in main"
else
  echo "⚠ Warning: Merge commit not yet in local main"
  echo "Pull may still be syncing. Wait a moment and try again."
fi
```

### 6. Delete Local Feature Branch

```bash
echo ""
echo "Deleting local branch: $FEATURE_BRANCH"

git branch -d "$FEATURE_BRANCH"

if [ $? -ne 0 ]; then
  echo "⚠ Warning: Branch has unmerged changes"
  read -p "Force delete? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch -D "$FEATURE_BRANCH"
  else
    echo "Skipping branch deletion"
  fi
else
  echo "✓ Local branch deleted"
fi
```

### 7. Delete Remote Feature Branch

```bash
echo ""
echo "Deleting remote branch: origin/$FEATURE_BRANCH"

git push origin --delete "$FEATURE_BRANCH" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✓ Remote branch deleted"
else
  echo "ℹ Remote branch already deleted (likely auto-deleted by GitHub)"
fi
```

### 8. Close the GitHub Issue

```bash
echo ""
echo "Closing issue #$ISSUE_NUMBER..."

# Create closing comment
CLOSE_COMMENT="Completed via PR #${PR_NUMBER}

Merge commit: \`${MERGE_COMMIT}\`
Merged: ${MERGED_DATE}"

gh issue close "$ISSUE_NUMBER" --comment "$CLOSE_COMMENT"

if [ $? -eq 0 ]; then
  echo "✓ Issue #$ISSUE_NUMBER closed"
else
  echo "❌ Failed to close issue"
  echo "Close manually on GitHub"
fi
```

### 9. Update Spec Files (if applicable)

```bash
echo ""
echo "Verifying spec updates..."

# Get affected specs from merged PR
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body --jq .body)
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/([^/]+)/spec\.md" -o)

if [ -n "$AFFECTED_SPECS" ]; then
  echo "Affected specs:"
  for SPEC_PATH in $AFFECTED_SPECS; do
    if [ -f "$SPEC_PATH" ]; then
      echo "  ✓ $SPEC_PATH (updated in merge)"
    else
      echo "  ⚠ $SPEC_PATH (not found - may need creation)"
    fi
  done
else
  echo "ℹ No spec changes for this issue"
fi
```

### 10. Update TODO.md

Move issue from "In Review" to "Completed":

```bash
# Update TODO.md
if [ -f "TODO.md" ]; then
  echo ""
  echo "Updating TODO.md..."

  # Remove from In Review section and add to Completed
  # This is a simplified example; actual implementation may vary

  # For manual update, show what to change:
  echo "Remove from 'In Review':"
  grep "#$ISSUE_NUMBER" TODO.md | head -1

  echo ""
  echo "Add to 'Completed' section:"
  echo "- [x] #$ISSUE_NUMBER - $PR_TITLE - PR: #$PR_NUMBER - Completed: $MERGED_DATE ✅"
fi
```

Example update:

```markdown
## Completed

- [x] #201 - Curriculum Framework - PR: #456 - Completed: 2025-10-22 ✅
  - **Merge Commit**: abc123def456
  - **Specs Updated**: docs/specs/curriculum-management/spec.md
  - **Sprint**: S2
```

### 11. Update Sprint File

```bash
# Find sprint file
MILESTONE=$(gh issue view $ISSUE_NUMBER --json milestone --jq .milestone.title)
SPRINT_NUM=$(echo "$MILESTONE" | rg "S([0-9]+)" -o -r '$1')
SPRINT_FILE="docs/sprint/S${SPRINT_NUM}.md"

if [ -f "$SPRINT_FILE" ]; then
  echo ""
  echo "Update $SPRINT_FILE with completion details:"
  echo ""
  echo "## $PR_TITLE"
  echo ""
  echo "**Status**: Completed ✅"
  echo "**PR**: #$PR_NUMBER - Merged: $MERGED_DATE"
  echo "**Merge Commit**: $MERGE_COMMIT"
  echo "**Completed**: $MERGED_DATE"
fi
```

Example sprint file update:

```markdown
## Curriculum Framework

**User Story**: As an educator...

**Status**: Completed ✅
**Issue**: #201
**PR**: #456 - Merged: 2025-10-22
**Merge Commit**: abc123def456
**Branch**: feat/201-curriculum-framework (deleted)
**Started**: 2025-10-21
**Completed**: 2025-10-22
**Duration**: 1 day

**Specs Updated**:
- docs/specs/curriculum-management/spec.md

**Notes**: Implementation went smoothly. No blockers encountered.
All acceptance criteria met.
```

### 12. Update docs/prd.md (if major capability)

If this completes a major capability:

```bash
if echo "$AFFECTED_SPECS" | grep -q "docs/specs/"; then
  echo ""
  echo "Consider updating docs/prd.md:"
  echo "  - Mark capability as ✅ Completed"
  echo "  - Update roadmap status"
  echo "  - Note completion date"
fi
```

### 13. Calculate Sprint Progress

```bash
echo ""
echo "=== Sprint Progress ==="

# Get all issues in sprint
SPRINT_ISSUES=$(gh issue list --milestone "$MILESTONE" --state all --json number,state)
TOTAL=$(echo "$SPRINT_ISSUES" | jq 'length')
CLOSED=$(echo "$SPRINT_ISSUES" | jq '[.[] | select(.state == "CLOSED")] | length')
PROGRESS=$((CLOSED * 100 / TOTAL))

echo "Sprint: $MILESTONE"
echo "Progress: $CLOSED/$TOTAL ($PROGRESS%)"

# Update TODO.md with progress
echo ""
echo "Update TODO.md sprint section with:"
echo "**Progress**: $CLOSED/$TOTAL ($PROGRESS%)"
```

### 14. Clean Up Artifacts

```bash
echo ""
echo "Cleaning up artifacts..."

# Remove any temporary files
npm run clean 2>/dev/null || true

# Clear test artifacts
rm -rf test-results/ screenshots/ .nyc_output/ coverage/

echo "✓ Artifacts cleaned"
```

### 15. Provide Summary

```
✓ Issue Closed Successfully!

Issue: #201 - Curriculum Framework
PR: #456
Merge Commit: abc123def456
Merged: 2025-10-22

Cleanup completed:
  ✓ Switched to main branch
  ✓ Pulled latest changes
  ✓ Deleted local branch: feat/201-curriculum-framework
  ✓ Deleted remote branch: origin/feat/201-curriculum-framework
  ✓ Closed issue #201
  ✓ Updated TODO.md
  ✓ Updated sprint file: docs/sprint/S2.md

Sprint Progress:
  Sprint S2: 3/5 (60%) complete

Specs Updated:
  - docs/specs/curriculum-management/spec.md ✅

Next steps:
  1. Review sprint progress
  2. Run 'next-issue' to start next task
  3. Consider sprint retrospective when complete

Great work! 🎉
```

## Completion Verification Checklist

After running close-issue, verify:

- [ ] On main branch
- [ ] Main branch up to date
- [ ] Feature branch deleted locally
- [ ] Feature branch deleted remotely
- [ ] GitHub issue closed with comment
- [ ] TODO.md updated (moved to Completed)
- [ ] Sprint file updated with completion details
- [ ] Specs verified as updated
- [ ] Sprint progress calculated
- [ ] Artifacts cleaned up

## File Update Patterns

### TODO.md Complete Format

```markdown
## Sprint S2 – Core Curriculum & Content Management

**Started**: 2025-10-21
**Progress**: 3/5 (60%)

**Completed**:
- [x] #201 - Curriculum Framework - PR: #456 - Completed: 2025-10-22 ✅
- [x] #199 - User Authentication - PR: #450 - Completed: 2025-10-20 ✅
- [x] #198 - Database Setup - PR: #448 - Completed: 2025-10-19 ✅

**In Review**:
- [ ] #202 - Lesson Player - PR: #457

**In Progress**:
- [ ] #203 - Virtual Laboratory System - feat/203-virtual-laboratory

**Ready**:
- [ ] #204 - Bilingual CMS
- [ ] #205 - Assessment Engine
```

### Sprint File Complete Format

```markdown
# Sprint S2 – Core Curriculum & Content Management

**Milestone**: S2 – Core Curriculum & Content Management
**Started**: 2025-10-21
**Status**: In Progress (60% complete)

---

## Curriculum Framework ✅

**User Story**: As an educator, I want to define course structures...

**Status**: Completed ✅
**Issue**: #201 - Closed: 2025-10-22
**PR**: #456 - Merged: 2025-10-22
**Merge Commit**: abc123def456
**Branch**: feat/201-curriculum-framework (deleted)
**Started**: 2025-10-21
**Completed**: 2025-10-22
**Duration**: 1 day

**Specs Updated**:
- docs/specs/curriculum-management/spec.md (ADDED Requirements)

**Acceptance Criteria**: All met ✅
- [x] Course hierarchy supported
- [x] Learning objectives trackable
- [x] API endpoints implemented
- [x] Tests passing (95% coverage)

**Notes**:
- Implementation smooth, no major blockers
- Spec updated with final API contracts
- Design doc created for future extensions
- All review feedback addressed

---

## Lesson Player 🔄

**Status**: In Review...
```

### docs/prd.md Update

```markdown
## Core Capabilities

### Content Management

**Status**: In Progress (60% complete)

- [x] **Curriculum Framework** - Completed 2025-10-22
  - Multi-level course hierarchies
  - Learning objective tracking
  - See: `docs/specs/curriculum-management/spec.md`

- [ ] **Lesson Player** - In Review
  - Interactive lesson delivery
  - Progress tracking

- [ ] **Virtual Laboratory** - In Progress
  - Hands-on simulations
  - Safe experimentation environment
```

## Error Handling

### PR Not Merged

```
⚠ Error: PR #456 is not merged

Current status: OPEN

Options:
1. Wait for PR approval and merge
2. Check if there are blocking review comments
3. Verify all CI checks passed

Run 'close-issue' after PR merges.
```

### Cannot Switch to Main

```
⚠ Error: Cannot switch to main branch

Uncommitted changes on feature branch.

Options:
1. Commit changes:
     git add .
     git commit -m "wip: save progress"

2. Stash changes:
     git stash

3. Discard changes (⚠ destructive):
     git reset --hard

Then run 'close-issue' again.
```

### Branch Deletion Failed

```
⚠ Warning: Local branch has unmerged commits

The feature branch contains commits not in main.
This usually means the merge hasn't synced yet.

Options:
1. Wait 1-2 minutes and try again
2. Force delete (⚠ only if you're sure PR merged):
     git branch -D feat/201-curriculum-framework
3. Keep branch for review:
     (skip deletion for now)
```

### Issue Close Failed

```
❌ Failed to close issue #201

Possible causes:
1. Permissions insufficient
2. Issue already closed
3. Network error

Close manually:
  gh issue close 201 --comment "Completed via PR #456"

Or on GitHub web interface.
```

## Advanced: Batch Close Multiple Issues

For closing multiple completed issues:

```bash
# Get all merged PRs from last week
gh pr list --state merged --limit 20 --json number,title,mergedAt,closedAt

# For each merged PR, run close-issue workflow
# This would be implemented as a separate batch command
```

## Sprint Completion

When all issues in sprint are closed:

```bash
echo ""
echo "=== Sprint S2 Complete! ==="
echo ""
echo "Issues completed: 5/5 (100%)"
echo "Duration: 2 weeks"
echo "Started: 2025-10-21"
echo "Completed: 2025-11-04"
echo ""
echo "Retrospective items:"
echo "  - What went well?"
echo "  - What could be improved?"
echo "  - Action items for next sprint?"
echo ""
echo "Run 'seed-sprint' to start Sprint S3"
```

## Notes

- Always verify PR is merged before cleanup
- Update all tracking files with completion details
- Include merge commit reference for traceability
- Clean up both local and remote branches
- Add completion date to all tracking files
- Calculate and update sprint progress
- Verify specs were updated in the merge
- Clean up temporary artifacts
- Provide completion summary
- Consider sprint retrospective when all issues complete
