# Block Issue Command

Mark an issue as blocked when external dependencies prevent progress.

## Purpose

Document blockers that prevent work from continuing, track resolution timeline, and maintain visibility into impediments. Allows PM to understand what's preventing progress and take action.

## When to Use

- Waiting for external API access or documentation
- Blocked by design decision not yet made
- Dependent on another issue that's delayed
- Waiting for third-party service or approval
- Need clarification from stakeholder
- Technical blocker discovered during implementation

## Workflow

### 1. Identify Current Issue and Blocker

```bash
# If on feature branch, extract issue number
CURRENT_BRANCH=$(git branch --show-current)
ISSUE_NUMBER=$(echo "$CURRENT_BRANCH" | sed -E 's/(feat|fix|chore|refactor)\/([0-9]+).*/\2/')

# Or specify manually
ISSUE_NUMBER=203

echo "Blocking issue: #$ISSUE_NUMBER"
```

### 2. Document the Blocker

Capture key information about what's blocking progress:

```bash
# Get issue details
ISSUE_TITLE=$(gh issue view $ISSUE_NUMBER --json title --jq .title)

echo "Issue: #$ISSUE_NUMBER - $ISSUE_TITLE"
echo ""
echo "What is blocking progress?"
read -p "Blocker reason: " BLOCKER_REASON
read -p "Who/what is blocking: " BLOCKER_SOURCE
read -p "Expected resolution date (YYYY-MM-DD): " EXPECTED_DATE
read -p "Alternative approach (if any): " ALTERNATIVE
```

### 3. Add Blocked Label

```bash
# Add blocked label
gh issue edit $ISSUE_NUMBER --add-label "blocked"

echo "✓ Added 'blocked' label to issue #$ISSUE_NUMBER"
```

### 4. Post Blocking Comment

```bash
# Create blocking comment
BLOCKING_COMMENT=$(cat <<EOF
## 🚫 Issue Blocked

**Blocker**: ${BLOCKER_REASON}

**Source**: ${BLOCKER_SOURCE}

**Expected Resolution**: ${EXPECTED_DATE}

**Alternative Approach**: ${ALTERNATIVE:-None identified}

**Date Blocked**: $(date +%Y-%m-%d)

---

**Action**: ${BLOCKER_SOURCE} follow-up needed. Will resume work once unblocked.
EOF
)

# Post comment
gh issue comment $ISSUE_NUMBER --body "$BLOCKING_COMMENT"

echo "✓ Posted blocking comment to issue #$ISSUE_NUMBER"
```

### 5. Update TODO.md

Move issue to "Blocked" section:

```markdown
## Blocked

- [ ] #203 - Virtual Laboratory System
  - **Blocked**: $(date +%Y-%m-%d)
  - **Reason**: Waiting for 3D rendering API documentation
  - **Source**: External vendor (Acme Corp)
  - **Expected**: 2025-10-25
  - **Branch**: feat/203-virtual-laboratory (paused)
```

If TODO.md doesn't have "Blocked" section, create it:

```bash
# Check if section exists
if ! grep -q "## Blocked" TODO.md; then
  # Add section after "In Progress"
  sed -i '/^## In Progress/a \\n## Blocked\n' TODO.md
fi

# Move issue from "In Progress" to "Blocked"
# (This would be manual or use sed/awk to move the entry)
```

### 6. Update Sprint File

Document blockage in sprint file:

```markdown
## Virtual Laboratory System

**Status**: ⚠️ Blocked
**Branch**: feat/203-virtual-laboratory (paused)
**Started**: 2025-10-21
**Blocked**: 2025-10-22
**Issue**: #203

**Blocker Details**:
- **Reason**: Waiting for 3D rendering API documentation
- **Source**: External vendor (Acme Corp)
- **Expected**: 2025-10-25
- **Alternative**: Could implement with 2D fallback (reduced functionality)

**Action**: PM following up with vendor contact
```

### 7. Pause Current Work

If actively working on the issue:

```bash
# Commit work in progress
git add .
git commit -m "wip: pausing due to blocker

Issue blocked waiting for ${BLOCKER_REASON}.
See issue #${ISSUE_NUMBER} for details."

# Switch back to main
git switch main

echo ""
echo "✓ Work paused and saved on branch: $CURRENT_BRANCH"
echo ""
echo "Next steps:"
echo "  1. PM will follow up on blocker"
echo "  2. Run 'next-issue' to start different issue"
echo "  3. Return to this issue when blocker is resolved"
```

### 8. Notify PM/Scrum Master

```
✓ Issue #203 marked as blocked

Issue: Virtual Laboratory System
Blocker: Waiting for 3D rendering API documentation
Source: External vendor (Acme Corp)
Expected: 2025-10-25

PM action needed:
  - Follow up with Acme Corp contact
  - Escalate if not resolved by expected date
  - Consider alternative approach if delayed

Work paused on: feat/203-virtual-laboratory
Ready to resume once unblocked.
```

## Unblocking an Issue

When blocker is resolved:

### 1. Remove Blocked Label

```bash
ISSUE_NUMBER=203

# Remove blocked label
gh issue edit $ISSUE_NUMBER --remove-label "blocked"

echo "✓ Removed 'blocked' label"
```

### 2. Post Unblocking Comment

```bash
UNBLOCKING_COMMENT=$(cat <<EOF
## ✅ Issue Unblocked

**Resolution**: ${RESOLUTION_DETAILS}

**Date Unblocked**: $(date +%Y-%m-%d)

**Blocked Duration**: ${DAYS_BLOCKED} days

---

**Action**: Ready to resume work. Will run 'next-issue' to continue implementation.
EOF
)

gh issue comment $ISSUE_NUMBER --body "$UNBLOCKING_COMMENT"

echo "✓ Posted unblocking comment"
```

### 3. Update Tracking Files

Move from "Blocked" back to "Ready" or "In Progress":

```markdown
## Ready

- [ ] #203 - Virtual Laboratory System (unblocked 2025-10-25)
  - **Priority**: P2
  - **Milestone**: S2
  - **Branch**: feat/203-virtual-laboratory (ready to resume)
  - **Was blocked**: 3 days (resolved)
```

### 4. Resume Work

```bash
# Run next-issue and select the unblocked issue
run: next-issue

# When prompted, select #203
# Or manually switch to branch:
git switch feat/203-virtual-laboratory

echo "✓ Resuming work on previously blocked issue"
```

## Common Blocker Types

### External Dependency

```markdown
**Blocker**: Waiting for API access credentials
**Source**: External service provider
**Expected**: 2025-10-25
**Alternative**: Use mock data for development, swap in real API later
```

### Design Decision

```markdown
**Blocker**: Awaiting UX decision on navigation pattern
**Source**: Design team review meeting (scheduled 2025-10-24)
**Expected**: 2025-10-24
**Alternative**: Implement with temporary navigation, refactor after decision
```

### Technical Discovery

```markdown
**Blocker**: Performance issue with current approach, researching alternatives
**Source**: Load testing revealed 10s response time (requirement: <2s)
**Expected**: 2025-10-23 (spike investigation complete)
**Alternative**: Fallback to batch processing if real-time not feasible
```

### Dependent Issue

```markdown
**Blocker**: Requires authentication system from issue #201
**Source**: Issue #201 (in progress, 60% complete)
**Expected**: 2025-10-24 (based on current velocity)
**Alternative**: None - hard dependency
```

## Best Practices

1. **Document immediately**: Mark as blocked as soon as you discover the blocker
2. **Be specific**: Clear explanation helps PM take action
3. **Set expectations**: Provide expected resolution date if known
4. **Identify alternatives**: Consider workarounds to maintain progress
5. **Pause work cleanly**: Commit WIP and switch branches
6. **Update tracking**: Ensure TODO.md and sprint file reflect blocked status
7. **Notify PM**: Don't assume they'll see the GitHub label
8. **Follow up**: If blocker not resolved by expected date, escalate

## Error Handling

### Issue Already Closed

```
⚠ Error: Cannot block closed issue #203

Possible actions:
  1. Reopen issue if work is incomplete
  2. Create new issue for remaining work
  3. Document blocker in closed issue comments for reference
```

### No Active Work

```
ℹ Note: Issue #203 is not currently in progress

This is fine - you can block issues in any state:
  - Blocked before starting: Mark as blocked to prevent assignment
  - Blocked during work: Mark when blocker discovered
  - Blocked in review: Mark if PR reveals blocker
```

## Notes

- Blocked issues should not count toward team velocity
- Track blocked time for retrospective analysis
- Some blockers resolve quickly (hours), others take weeks
- Alternative approaches maintain momentum when possible
- PM should review all blocked issues daily
- Consider splitting issue if blocker only affects part of scope
- Update expected resolution date if circumstances change
- Celebrate when blockers are removed!

## Example Workflow

```
Day 1:
  - Start work on #203 (Virtual Lab)
  - Discover need for 3D API documentation (not available)
  - Run: block-issue
  - Mark as blocked, pause work
  - Run: next-issue → Start #204 instead

Day 2-3:
  - PM follows up with vendor
  - Continue work on #204

Day 4:
  - Documentation arrives!
  - Remove blocked label
  - Post unblocking comment
  - Run: next-issue → Resume #203
  - Complete implementation

Retrospective:
  - 3 days blocked, but maintained progress on other work
  - Lesson: Check API documentation availability during planning
  - Action: Add "external dependencies verified" to Definition of Ready
```
