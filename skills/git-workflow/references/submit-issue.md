# Submit Issue Command

Complete work on the current issue and create a pull request with proper formatting and auto-merge.

## Purpose

Create a well-formatted pull request that includes spec deltas, proper commit messages, and automated merge configuration.

## When to Use

- After implementation is complete
- After all tests pass (run `test-issue` first)
- When ready for code review
- Implementation meets all acceptance criteria

## Prerequisites

Before running this command:
- [ ] All tests passing (run `test-issue`)
- [ ] Code changes committed locally
- [ ] Acceptance criteria met
- [ ] Specs updated (if applicable)

## Workflow

### 1. Verify Current Branch and Issue

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "⚠ Error: On main branch. Cannot create PR from main."
  exit 1
fi

echo "Current branch: $CURRENT_BRANCH"

# Extract issue number
ISSUE_NUMBER=$(echo "$CURRENT_BRANCH" | sed -E 's/(feat|fix|chore|refactor)\/([0-9]+).*/\2/')

if [ -z "$ISSUE_NUMBER" ]; then
  echo "⚠ Error: Cannot extract issue number from branch name"
  echo "Branch should be formatted: feat/123-description"
  exit 1
fi

echo "Issue: #$ISSUE_NUMBER"

# Verify issue exists and is open
ISSUE_STATE=$(gh issue view "$ISSUE_NUMBER" --json state --jq .state)
if [ "$ISSUE_STATE" != "OPEN" ]; then
  echo "⚠ Error: Issue #$ISSUE_NUMBER is $ISSUE_STATE"
  exit 1
fi
```

### 2. Check for Staged or Uncommitted Changes

```bash
# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo ""
  echo "Uncommitted changes detected:"
  git status --short
  echo ""
  read -p "Commit these changes? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Proceed to commit step
    NEED_COMMIT=true
  else
    echo "⚠ Please commit or stash changes before submitting."
    exit 1
  fi
else
  NEED_COMMIT=false
fi
```

### 3. Verify Spec Updates (if applicable)

```bash
# Get issue body to check for affected specs
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --json body --jq .body)
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/([^/]+)/spec.md" -o)

if [ -n "$AFFECTED_SPECS" ]; then
  echo "Checking spec updates..."

  for SPEC_PATH in $AFFECTED_SPECS; do
    # Check if spec file was modified in this branch
    SPEC_MODIFIED=$(git diff main...HEAD --name-only | grep "$SPEC_PATH")

    if [ -z "$SPEC_MODIFIED" ]; then
      echo "⚠ Warning: $SPEC_PATH was not modified"
      echo ""
      read -p "Spec should be updated. Continue anyway? (y/n) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update spec files and run 'submit-issue' again."
        exit 1
      fi
    else
      echo "✓ $SPEC_PATH was updated"
    fi
  done
fi
```

### 4. Commit Changes (if needed)

```bash
if [ "$NEED_COMMIT" = true ]; then
  # Get issue title for commit message
  ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title --jq .title)

  # Get labels to determine commit type
  LABELS=$(gh issue view "$ISSUE_NUMBER" --json labels --jq '.labels[].name' | tr '\n' ',')

  # Determine commit prefix from labels or branch
  if echo "$LABELS" | grep -q "type:bug"; then
    COMMIT_PREFIX="fix"
  elif echo "$LABELS" | grep -q "type:chore"; then
    COMMIT_PREFIX="chore"
  elif echo "$LABELS" | grep -q "type:docs"; then
    COMMIT_PREFIX="docs"
  elif echo "$CURRENT_BRANCH" | grep -q "^fix/"; then
    COMMIT_PREFIX="fix"
  elif echo "$CURRENT_BRANCH" | grep -q "^chore/"; then
    COMMIT_PREFIX="chore"
  else
    COMMIT_PREFIX="feat"
  fi

  # Create commit message
  COMMIT_MSG="${COMMIT_PREFIX}: ${ISSUE_TITLE}

Closes #${ISSUE_NUMBER}"

  # Stage all changes
  git add .

  # Commit
  git commit -m "$COMMIT_MSG"

  echo "✓ Changes committed"
fi
```

### 5. Run Tests One More Time

```bash
echo ""
echo "Running final test check..."

# Quick test run
npm run lint && npm run test

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Tests failed. Fix issues before submitting."
  echo ""
  echo "To undo commit and fix:"
  echo "  git reset HEAD~1"
  echo ""
  exit 1
fi

echo "✓ Tests passed"
```

### 6. Push Branch to Remote

```bash
echo ""
echo "Pushing branch to remote..."

# Check if branch exists on remote
REMOTE_EXISTS=$(git ls-remote --heads origin "$CURRENT_BRANCH" | wc -l)

if [ "$REMOTE_EXISTS" -eq 0 ]; then
  # First push - set upstream
  git push -u origin "$CURRENT_BRANCH"
else
  # Subsequent push
  git push origin "$CURRENT_BRANCH"
fi

if [ $? -ne 0 ]; then
  echo "❌ Push failed. Check network connection and permissions."
  exit 1
fi

echo "✓ Branch pushed to origin/$CURRENT_BRANCH"
```

### 7. Build PR Body with Spec Deltas

```bash
# Get issue details
ISSUE_DETAILS=$(gh issue view "$ISSUE_NUMBER" --json title,body,labels,milestone)
TITLE=$(echo "$ISSUE_DETAILS" | jq -r .title)
ISSUE_BODY=$(echo "$ISSUE_DETAILS" | jq -r .body)
MILESTONE=$(echo "$ISSUE_DETAILS" | jq -r .milestone.title)

# Extract change type
CHANGE_TYPE=$(echo "$ISSUE_BODY" | rg "\[x\] (ADDED|MODIFIED|REMOVED) Requirements" -o -r '$1')

# Extract affected specs
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/[^)]+\.md" -o | tr '\n' ',' | sed 's/,$//')

# Extract proposed spec changes section (if exists)
SPEC_CHANGES=$(echo "$ISSUE_BODY" | sed -n '/## Proposed Spec Changes/,/## Acceptance Criteria/p' | sed '1d;$d')

# Build PR body
PR_BODY=$(cat <<EOF
## Summary

Implements: $TITLE

## Spec Changes

$(if [ -n "$AFFECTED_SPECS" ]; then
  echo "Updated: \`$AFFECTED_SPECS\`"
  echo ""
  if [ -n "$CHANGE_TYPE" ]; then
    echo "Change Type: **${CHANGE_TYPE}** Requirements"
  fi
  echo ""
  if [ -n "$SPEC_CHANGES" ]; then
    echo "### Spec Deltas"
    echo ""
    echo "$SPEC_CHANGES"
  fi
else
  echo "No spec changes required"
fi)

## Implementation Details

$(git log main..HEAD --pretty=format:"- %s" | head -5)

## Testing

- [x] Unit tests passing
- [x] Integration tests passing
- [x] E2E tests passing
- [x] Linting passing
- [x] Build successful

## Checklist

- [x] Implementation complete
- [x] Tests passing
- [$([ -n "$AFFECTED_SPECS" ] && echo "x" || echo " ")] Specs updated in docs/specs/
- [x] Acceptance criteria met
- [x] Code reviewed (self-review)

---

Closes #${ISSUE_NUMBER}
EOF
)
```

### 8. Create Pull Request

```bash
echo ""
echo "Creating pull request..."

# Determine PR title prefix (same as commit)
if echo "$LABELS" | grep -q "type:bug"; then
  PR_PREFIX="fix"
elif echo "$LABELS" | grep -q "type:chore"; then
  PR_PREFIX="chore"
elif echo "$LABELS" | grep -q "type:docs"; then
  PR_PREFIX="docs"
else
  PR_PREFIX="feat"
fi

PR_TITLE="${PR_PREFIX}: ${TITLE}"

# Create PR
gh pr create \
  --title "$PR_TITLE" \
  --body "$PR_BODY" \
  --label "type:feature" \
  --milestone "$MILESTONE" \
  --draft=false

if [ $? -ne 0 ]; then
  echo "❌ PR creation failed"
  exit 1
fi

echo "✓ Pull request created"
```

### 9. Enable Auto-Merge

```bash
echo ""
echo "Enabling auto-merge..."

# Get PR number
PR_NUMBER=$(gh pr view --json number --jq .number)

# Enable auto-merge with squash
gh pr merge --auto --squash

if [ $? -eq 0 ]; then
  echo "✓ Auto-merge enabled (squash)"
else
  echo "⚠ Auto-merge failed (may require branch protection updates)"
  echo "  PR will need manual merge after approval"
fi
```

### 10. Request Appropriate Reviewers

```bash
echo ""
echo "Adding reviewers..."

# Get changed files
CHANGED_FILES=$(git diff --name-only main...HEAD)

REVIEWERS=()

# Add reviewers based on file patterns
if echo "$CHANGED_FILES" | grep -q "prisma/\|lib/.*\.ts"; then
  REVIEWERS+=("backend-reviewer")
fi

if echo "$CHANGED_FILES" | grep -q "components/\|app/"; then
  REVIEWERS+=("frontend-reviewer")
fi

if echo "$CHANGED_FILES" | grep -q "docs/specs/"; then
  REVIEWERS+=("spec-reviewer")
fi

# Request reviews
if [ ${#REVIEWERS[@]} -gt 0 ]; then
  for REVIEWER in "${REVIEWERS[@]}"; do
    gh pr edit --add-reviewer "$REVIEWER" 2>/dev/null && echo "  Added: $REVIEWER"
  done
else
  echo "  No automatic reviewers determined"
  echo "  Add reviewers manually on GitHub"
fi
```

### 11. Open PR in Browser

```bash
echo ""
echo "Opening PR in browser..."
gh pr view --web

echo ""
echo "✓ PR ready for review!"
```

### 12. Update TODO.md

Move issue from "In Progress" to "In Review":

```markdown
## In Review

- [ ] #201 - Curriculum Framework
  - **PR**: #456 - https://github.com/org/repo/pull/456
  - **Status**: In Review
  - **Submitted**: 2025-10-22
  - **Auto-merge**: Enabled
  - **Reviewers**: @backend-reviewer, @spec-reviewer
```

Remove from "In Progress" section.

### 13. Update Sprint File

```markdown
## Curriculum Framework

**Status**: PR Created ✓
**Branch**: feat/201-curriculum-framework
**Started**: 2025-10-21
**Issue**: #201
**PR**: #456 - https://github.com/org/repo/pull/456
**Submitted**: 2025-10-22
**Reviewers**: @backend-reviewer, @spec-reviewer
**Auto-merge**: Enabled

**Test Results**:
- All tests passing ✅
- Coverage: 92%

**Ready for Review**: Yes
```

### 14. Provide Summary

```
✓ Pull Request Created Successfully!

Issue: #201 - Curriculum Framework
PR: #456 - https://github.com/org/repo/pull/456
Branch: feat/201-curriculum-framework

Status:
  ✓ Code pushed
  ✓ PR created
  ✓ Auto-merge enabled
  ✓ Reviewers requested
  ✓ Tests passing

Spec Changes:
  - Updated: docs/specs/curriculum-management/spec.md
  - Change Type: ADDED Requirements

Next steps:
  1. PR will auto-merge after approval
  2. Watch for review comments
  3. Use 'update-issue' if changes requested
  4. Use 'close-issue' after merge completes

PR is now open in your browser.
```

## PR Body Format

### Complete Example

```markdown
## Summary

Implements: Curriculum Framework

## Spec Changes

Updated: `docs/specs/curriculum-management/spec.md`

Change Type: **ADDED** Requirements

### Spec Deltas

#### ADDED Requirements

##### Requirement: Course Hierarchy Management

The system SHALL support multi-level course hierarchies (courses > modules > lessons).

###### Scenario: Create Course Structure

- **WHEN** educator creates course with modules
- **THEN** hierarchy is created and maintained
- **AND** navigation reflects structure

## Implementation Details

- feat: add curriculum framework models
- feat: implement course hierarchy API
- feat: add curriculum management UI
- test: add curriculum framework tests
- docs: update curriculum-management spec

## Testing

- [x] Unit tests passing (92% coverage)
- [x] Integration tests passing
- [x] E2E tests passing
- [x] Linting passing
- [x] Build successful

## Checklist

- [x] Implementation complete
- [x] Tests passing
- [x] Specs updated in docs/specs/
- [x] Acceptance criteria met
- [x] Code reviewed (self-review)

---

Closes #201
```

## Commit Message Format

### Conventional Commits

```
<type>: <description>

[optional body]

Closes #<issue-number>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `chore`: Maintenance, refactoring
- `docs`: Documentation only
- `test`: Adding or fixing tests
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvement
- `style`: Formatting, missing semicolons, etc.

### Examples

```
feat: add two-factor authentication

Implements OTP-based 2FA for user accounts.
Includes email delivery and validation.

Closes #123
```

```
fix: resolve login timeout on slow connections

Increase timeout from 5s to 30s for login API.
Add retry logic for network errors.

Closes #124
```

```
chore: update dependencies to latest versions

Update React 18.2 -> 18.3
Update Next.js 14.0 -> 14.1
No breaking changes.

Closes #125
```

## Error Handling

### Uncommitted Changes

```
⚠ Uncommitted changes detected:
  M src/auth/login.ts
  M src/components/Form.tsx
  ?? src/utils/new-file.ts

Commit these changes? (y/n)

If 'n': Please commit or stash changes manually:
  git add .
  git commit -m "feat: description"
  # Then run 'submit-issue' again
```

### Tests Failing

```
❌ Tests failed during final check

Please fix test failures before submitting:
  npm run test -- --verbose

After fixing, run 'submit-issue' again.

To undo the commit (if created):
  git reset HEAD~1
```

### Push Failure

```
❌ Failed to push to origin

Possible causes:
1. Network connection issue
2. Authentication failure
3. Remote branch conflict

Try:
  git push -u origin $(git branch --show-current)

If conflict, pull and rebase:
  git pull --rebase origin main
  # Resolve conflicts
  git push -u origin $(git branch --show-current)
```

### PR Creation Failure

```
❌ PR creation failed

Possible causes:
1. Branch already has open PR
2. No commits different from main
3. Permission issues

Check existing PRs:
  gh pr list --head $(git branch --show-current)

Try creating manually:
  gh pr create --web
```

### Auto-Merge Failure

```
⚠ Auto-merge could not be enabled

This is usually due to branch protection settings.

The PR was created successfully but will require manual merge after approval.

Check branch protection rules:
  gh api repos/:owner/:repo/branches/main/protection
```

## Advanced: Custom PR Templates

If repository has PR template (`.github/pull_request_template.md`):

```bash
# Read template
if [ -f ".github/pull_request_template.md" ]; then
  TEMPLATE=$(cat .github/pull_request_template.md)

  # Merge template with generated body
  # Replace template placeholders with generated content
fi
```

## File Update Patterns

### TODO.md Update

Before:
```markdown
## In Progress

- [ ] #201 - Curriculum Framework (feat/201-curriculum-framework)
  - **Started**: 2025-10-21
  - **Tests**: ✅ All Passed
```

After:
```markdown
## In Review

- [ ] #201 - Curriculum Framework
  - **PR**: #456
  - **Submitted**: 2025-10-22
  - **Status**: Awaiting Review
  - **Auto-merge**: Enabled
```

### Sprint File Update

Before:
```markdown
## Curriculum Framework

**Status**: In Progress - Testing Complete
**Branch**: feat/201-curriculum-framework
**Issue**: #201
```

After:
```markdown
## Curriculum Framework

**Status**: PR Created ✓
**Branch**: feat/201-curriculum-framework
**Issue**: #201
**PR**: #456 - https://github.com/org/repo/pull/456
**Submitted**: 2025-10-22
**Auto-merge**: Enabled
```

## Notes

- Always run `test-issue` before `submit-issue`
- Use conventional commit format for consistency
- Include spec deltas in PR body for reviewers
- Enable auto-merge for streamlined workflow
- Request appropriate reviewers based on changed files
- Update tracking files immediately after PR creation
- Open PR in browser for easy access
- Verify all acceptance criteria are met
- Include implementation details and testing status
- Link to closing issue with "Closes #N" syntax
