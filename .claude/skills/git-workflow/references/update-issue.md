# Update Issue Command

Handle review feedback, test failures, or spec clarifications for an open pull request.

## Purpose

Iterate on an open PR by addressing review comments, fixing test failures, or updating specs. Maintains clean commit history and communication with reviewers.

## When to Use

- After receiving PR review comments
- When CI/CD checks fail
- Spec clarifications needed
- Requested changes from reviewers
- Test failures discovered in CI
- Additional implementation needed

## Workflow

### 1. Verify Current State

```bash
# Check current branch
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "⚠ Error: On main branch"
  echo "Switch to feature branch with open PR"
  exit 1
fi

echo "Current branch: $CURRENT_BRANCH"

# Extract issue number
ISSUE_NUMBER=$(echo "$CURRENT_BRANCH" | sed -E 's/(feat|fix|chore|refactor)\/([0-9]+).*/\2/')

echo "Issue: #$ISSUE_NUMBER"

# Check if PR exists
PR_NUMBER=$(gh pr view --json number --jq .number 2>/dev/null)

if [ -z "$PR_NUMBER" ]; then
  echo "⚠ Error: No open PR found for this branch"
  echo "Run 'submit-issue' first to create PR"
  exit 1
fi

echo "PR: #$PR_NUMBER"
```

### 2. Get PR Status and Review Comments

```bash
# Get PR details
PR_DETAILS=$(gh pr view --json state,isDraft,reviewDecision,reviews,comments,statusCheckRollup)

echo "=== PR Status ==="
echo "$PR_DETAILS" | jq '{
  state,
  isDraft,
  reviewDecision,
  checksCount: .statusCheckRollup | length,
  reviewCount: .reviews | length,
  commentCount: .comments | length
}'

# Show review comments
echo ""
echo "=== Review Comments ==="
gh pr view --comments | grep -A 5 "COMMENT\|REQUESTED_CHANGES"

# Show failed checks
echo ""
echo "=== Status Checks ==="
FAILED_CHECKS=$(echo "$PR_DETAILS" | jq -r '.statusCheckRollup[] | select(.conclusion == "FAILURE") | .name')

if [ -n "$FAILED_CHECKS" ]; then
  echo "❌ Failed checks:"
  echo "$FAILED_CHECKS" | sed 's/^/  - /'
else
  echo "✓ All checks passing"
fi
```

### 3. Determine Update Type

Ask user what type of update is needed:

```
What needs updating?

1. Address review comments
2. Fix CI/CD failures
3. Update specs
4. Fix tests
5. Add more implementation
6. All of the above

Enter choice (1-6):
```

### 4. Address Review Comments

If review comments need addressing:

```bash
echo "Review comments to address:"
echo ""

# List each review comment with context
gh api repos/:owner/:repo/pulls/$PR_NUMBER/comments \
  --jq '.[] | "File: \(.path):\(.line)\nComment: \(.body)\n"'

echo ""
echo "Make your changes, then return here."
read -p "Press Enter when changes are ready..."
```

### 5. Fix CI/CD Failures

If CI checks are failing:

```bash
echo "Failed checks:"
gh pr checks --watch

# Get failure details
for CHECK in $FAILED_CHECKS; do
  echo "=== $CHECK ==="
  gh pr checks --json name,conclusion,detailsUrl \
    --jq ".[] | select(.name == \"$CHECK\") | .detailsUrl"
done

echo ""
echo "Common CI failure fixes:"
echo "  - Linting: npm run lint -- --fix"
echo "  - Tests: npm run test"
echo "  - Build: npm run build"
echo "  - Type errors: npx tsc --noEmit"
echo ""
read -p "Press Enter after fixing issues..."
```

### 6. Update Specs (if needed)

If spec changes are requested:

```bash
# Get affected specs from issue
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body --jq .body)
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/[^)]+\.md" -o)

echo "Affected specs:"
echo "$AFFECTED_SPECS"
echo ""

for SPEC_PATH in $AFFECTED_SPECS; do
  echo "Edit: $SPEC_PATH"
  echo "  - Update requirements based on feedback"
  echo "  - Ensure scenarios match implementation"
  echo "  - Add missing edge cases"
done

echo ""
read -p "Press Enter after updating specs..."
```

### 7. Run Tests Locally

```bash
echo ""
echo "Running tests locally..."

# Run full test suite
npm run lint && \
npm run type-check && \
npm run test && \
npm run build

TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Tests failed locally"
  echo "Fix issues before pushing update"
  exit 1
fi

echo "✓ All tests passed locally"
```

### 8. Commit Changes

```bash
# Check for changes
if [ -z "$(git status --porcelain)" ]; then
  echo "⚠ No changes to commit"
  echo "Make your changes and run 'update-issue' again"
  exit 1
fi

# Show what changed
echo "Changes to commit:"
git status --short
echo ""

# Determine commit message prefix
read -p "Commit message type (fix/refactor/docs/test): " COMMIT_TYPE
read -p "Brief description: " DESCRIPTION

# Create commit message
COMMIT_MSG="${COMMIT_TYPE}: ${DESCRIPTION}

Addresses PR #${PR_NUMBER} review comments"

# Commit
git add .
git commit -m "$COMMIT_MSG"

echo "✓ Changes committed"
```

### 9. Push Update

```bash
echo ""
echo "Pushing update to PR..."

git push origin "$CURRENT_BRANCH"

if [ $? -ne 0 ]; then
  echo "❌ Push failed"
  exit 1
fi

echo "✓ Update pushed to PR #$PR_NUMBER"
```

### 10. Re-run CI Checks

```bash
echo ""
echo "Watching CI checks..."

# Monitor PR checks
gh pr checks --watch

echo ""
echo "✓ CI checks completed"
```

### 11. Comment on PR

Add comment summarizing the update:

```bash
# Build comment
UPDATE_COMMENT=$(cat <<EOF
## Update Summary

Addressed review feedback:
- ${DESCRIPTION}

### Changes Made

$(git log -1 --pretty=format:"- %s")

### Testing

- [x] Local tests passing
- [x] CI checks passing
- [x] Review comments addressed

Ready for re-review.
EOF
)

# Post comment
gh pr comment $PR_NUMBER --body "$UPDATE_COMMENT"

echo "✓ Comment added to PR"
```

### 12. Re-request Review (if needed)

```bash
echo ""
echo "Re-requesting review..."

# Get previous reviewers
REVIEWERS=$(gh pr view --json reviews --jq '.reviews[].author.login' | sort -u)

# Re-request reviews
for REVIEWER in $REVIEWERS; do
  gh pr edit --add-reviewer "$REVIEWER" 2>/dev/null && echo "  Re-requested: $REVIEWER"
done

echo "✓ Reviews re-requested"
```

### 13. Update TODO.md

Update PR status:

```markdown
## In Review

- [ ] #201 - Curriculum Framework
  - **PR**: #456
  - **Status**: Updated - Awaiting Re-review
  - **Last Updated**: 2025-10-23
  - **Updates**: 2
  - **Addressed**: Review comments, test failures
```

### 14. Update Sprint File

```markdown
## Curriculum Framework

**Status**: PR Updated ✓
**PR**: #456
**Last Updated**: 2025-10-23
**Updates**: 2

**Recent Changes**:
- Addressed review comments on validation logic
- Fixed CI test failures
- Updated spec with edge cases

**Status**: Awaiting re-review
```

### 15. Provide Summary

```
✓ PR Update Complete!

PR: #456 - Curriculum Framework
Branch: feat/201-curriculum-framework

Updates:
  ✓ Changes committed and pushed
  ✓ CI checks passing
  ✓ Comment added to PR
  ✓ Reviewers notified

Status: Ready for re-review

Next steps:
  - Wait for reviewer feedback
  - Run 'update-issue' again if more changes needed
  - Run 'close-issue' after PR merges

View PR:
  gh pr view --web
```

## Update Scenarios

### Scenario 1: Minor Fixes (No New Commits Needed)

For very small changes, can amend last commit:

```bash
# Make small change
# Stage change
git add .

# Amend last commit
git commit --amend --no-edit

# Force push (safe for feature branch)
git push --force-with-lease origin "$CURRENT_BRANCH"
```

**Use sparingly** - only for typos, formatting, or immediate fixes.

### Scenario 2: Spec Clarification

If reviewer requests spec changes:

```bash
# 1. Update spec in docs/specs/
vim docs/specs/capability/spec.md

# 2. Update implementation to match
# ... make code changes ...

# 3. Commit both
git add docs/specs/ src/
git commit -m "refactor: clarify spec and update implementation

Addresses PR #${PR_NUMBER} review comments on edge case handling"

# 4. Push
git push origin "$CURRENT_BRANCH"
```

### Scenario 3: Failed CI Tests

```bash
# 1. Pull CI logs
gh run view --log

# 2. Identify failure
# 3. Fix locally
npm run test -- --verbose

# 4. Commit fix
git add .
git commit -m "fix: resolve CI test failure in user validation"

# 5. Push
git push origin "$CURRENT_BRANCH"
```

### Scenario 4: Significant Rework

If major changes requested:

```bash
# Consider creating new commits for clarity
git add feature-part-1/
git commit -m "refactor: restructure authentication flow"

git add feature-part-2/
git commit -m "test: add comprehensive auth tests"

git add docs/
git commit -m "docs: update auth spec with new flow"

git push origin "$CURRENT_BRANCH"
```

### Scenario 5: Merge Conflicts

If main branch has advanced:

```bash
# 1. Fetch latest
git fetch origin main

# 2. Rebase onto main
git rebase origin/main

# 3. Resolve conflicts
# ... resolve each conflict ...
git add .
git rebase --continue

# 4. Force push (safe for feature branch)
git push --force-with-lease origin "$CURRENT_BRANCH"

# 5. Comment on PR
gh pr comment --body "✓ Rebased on latest main, conflicts resolved"
```

## Review Comment Patterns

### Addressing Code Style Comments

```
Reviewer: "Use const instead of let here"

Response:
  1. Make change
  2. Commit: "style: use const for immutable variables"
  3. Comment: "✓ Updated to use const"
```

### Addressing Logic Comments

```
Reviewer: "This doesn't handle empty arrays"

Response:
  1. Add edge case handling
  2. Add test for edge case
  3. Commit: "fix: handle empty array edge case"
  4. Comment: "✓ Added empty array handling and test"
```

### Addressing Spec Comments

```
Reviewer: "Spec doesn't mention this behavior"

Response:
  1. Update spec to document behavior
  2. Ensure implementation matches
  3. Commit: "docs: document error handling in spec"
  4. Comment: "✓ Updated spec to reflect implementation"
```

### Addressing Performance Comments

```
Reviewer: "This could be O(n²), consider optimization"

Response:
  1. Refactor to O(n)
  2. Add performance test
  3. Commit: "perf: optimize lookup from O(n²) to O(n)"
  4. Comment: "✓ Optimized with hash map lookup, added perf test"
```

## File Update Patterns

### TODO.md Tracking Updates

```markdown
## In Review

- [ ] #201 - Curriculum Framework
  - **PR**: #456
  - **Status**: Updated (x2) - Awaiting Re-review
  - **Submitted**: 2025-10-22
  - **Last Updated**: 2025-10-23
  - **History**:
    - 2025-10-22: Initial submission
    - 2025-10-23: Addressed review comments
    - 2025-10-23: Fixed CI failures
```

### Sprint File Update History

```markdown
## Curriculum Framework

**Status**: PR Updated (x2) ✓
**PR**: #456
**Submitted**: 2025-10-22

**Update History**:
- **2025-10-23**: Addressed review comments
  - Fixed validation edge cases
  - Updated spec with scenarios
  - Added tests for error handling

- **2025-10-23**: Fixed CI failures
  - Resolved linting errors
  - Fixed flaky integration test
  - Updated dependencies

**Current Status**: Awaiting re-review
```

## Error Handling

### No PR Found

```
⚠ Error: No open PR for branch feat/201-curriculum-framework

Create PR first:
  run: submit-issue
```

### PR Already Merged

```
⚠ Error: PR #456 is already merged

Cannot update merged PR. If more work needed:
  1. Close current issue: run 'close-issue'
  2. Create new issue for additional work
```

### Push Rejected

```
❌ Error: Push rejected

Remote has changes not present locally.

Pull and rebase:
  git pull --rebase origin feat/201-curriculum-framework
  # Resolve any conflicts
  git push origin feat/201-curriculum-framework
```

### Tests Still Failing

```
❌ Error: Tests failing after update

PR update aborted. Fix tests before updating:
  npm run test -- --verbose

After fixing:
  run: update-issue
```

## Best Practices

1. **Small, focused updates**: One logical change per commit
2. **Test locally first**: Always run full test suite before pushing
3. **Clear commit messages**: Explain what and why
4. **Respond to all comments**: Address each review comment specifically
5. **Update specs when needed**: Keep specs in sync with implementation
6. **Re-request reviews**: Notify reviewers when ready
7. **Track update history**: Document what changed in each update
8. **Keep PR focused**: If expanding scope significantly, consider new PR

## Notes

- Address review comments promptly
- Test locally before every push
- Keep commit history clean and logical
- Update specs if implementation changes
- Communicate changes clearly in PR comments
- Re-request review after significant updates
- Track update count for visibility
- Consider rebasing if main has advanced significantly
- Use amend sparingly (only for trivial fixes)
- Always run full test suite before pushing
