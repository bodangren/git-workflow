# Work on Issue Workflow

Select and start work on a specific issue from assigned GitHub issues.

## Purpose

Load full context for an issue and create a feature branch to begin implementation. Ensures clean workflow start with all necessary context loaded before any code is written.

## When to Use

Use this workflow when:
- Starting work on a new issue
- Switching between issues
- After completing previous issue
- Beginning work session

## Workflow

### 1. Verify Clean Working State

```bash
# Check current branch is clean
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "⚠ Currently on branch: $CURRENT_BRANCH"
  echo "Finish current work or switch to main first."
  exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠ Uncommitted changes detected"
  git status
  echo "Commit or stash changes before starting new issue."
  exit 1
fi
```

### 2. Get Current User's Assigned Issues

```bash
# Get all open issues assigned to current user
gh issue list \
  --assignee @me \
  --state open \
  --json number,title,labels,milestone,createdAt \
  --limit 50 | jq '.'
```

### 3. Get Milestone Details for Context

```bash
# Get current sprint milestones
gh api repos/:owner/:repo/milestones \
  --jq '.[] | select(.state == "open") | {number, title, state, dueOn}' \
  | jq -s 'sort_by(.dueOn)'
```

### 4. Check for Spec Conflicts

For each candidate issue, verify no conflicting work in progress:

```bash
# Extract affected specs from issue body
ISSUE_NUM=123
AFFECTED_SPECS=$(gh issue view $ISSUE_NUM --json body --jq .body \
  | rg "Affected Specs.*" -A 5 \
  | rg "docs/specs/([^/]+)" -o -r '$1')

# Check if any other open issues affect same specs
for SPEC in $AFFECTED_SPECS; do
  CONFLICTS=$(gh issue list \
    --assignee @me \
    --state open \
    --search "docs/specs/$SPEC in:body" \
    --json number,title)

  if [ $(echo "$CONFLICTS" | jq 'length') -gt 1 ]; then
    echo "⚠ Conflict detected: Multiple issues affect $SPEC"
    echo "$CONFLICTS" | jq -r '.[] | "#\(.number) - \(.title)"'
  fi
done
```

### 5. Analyze and Recommend Issues

Sort and prioritize issues by:

1. **Priority**: P0 > P1 > P2 > P3
2. **Sprint alignment**: Current milestone first
3. **Spec readiness**: Issues with existing specs
4. **Dependencies**: Non-blocked issues first

```bash
# Parse priorities from labels
P0_ISSUES=$(gh issue list --assignee @me --state open --label "priority:P0" --json number,title,milestone)
P1_ISSUES=$(gh issue list --assignee @me --state open --label "priority:P1" --json number,title,milestone)
P2_ISSUES=$(gh issue list --assignee @me --state open --label "priority:P2" --json number,title,milestone)

# Show recommendations
echo "=== Recommended Issues ==="
echo ""
echo "Priority P0 (Critical):"
echo "$P0_ISSUES" | jq -r '.[] | "  #\(.number) - \(.title) [\(.milestone.title)]"'
echo ""
echo "Priority P1 (High):"
echo "$P1_ISSUES" | jq -r '.[] | "  #\(.number) - \(.title) [\(.milestone.title)]"'
echo ""
echo "Priority P2 (Medium):"
echo "$P2_ISSUES" | jq -r '.[] | "  #\(.number) - \(.title) [\(.milestone.title)]"'
```

Present top 3-5 recommendations:
```
Top recommendations:

1. #201 - Curriculum Framework (P1, S2) ✓ Specs ready
2. #202 - Lesson Player (P1, S2) ✓ Specs ready
3. #203 - Virtual Laboratory System (P2, S2) ⚠ Depends on #201

Which issue would you like to start? (Enter number)
```

### 6. Read Full Issue Details

After user selects issue:

```bash
ISSUE_NUMBER=201

# Read complete issue
gh issue view $ISSUE_NUMBER

# Read ALL comments (including review suggestions)
gh issue view $ISSUE_NUMBER --comments
```

**IMPORTANT**: Pay special attention to review comments posted by `review-sprint`. These may include:
- Architecture compliance suggestions
- Wording and clarity improvements
- Planning enhancements
- Spec change recommendations

Consider these suggestions during implementation but use your judgment on how to apply them.

### 7. Extract and Validate Spec References

```bash
# Get issue body
ISSUE_BODY=$(gh issue view $ISSUE_NUMBER --json body --jq .body)

# Extract affected specs
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/[^)]+")

# Verify each spec exists
echo "Validating spec references..."
for SPEC_PATH in $AFFECTED_SPECS; do
  if [ -f "$SPEC_PATH" ]; then
    echo "✓ Found: $SPEC_PATH"
  else
    echo "✗ Missing: $SPEC_PATH"
    echo ""
    echo "⚠ Spec not found. Run 'init-spec' to create it first."
    exit 1
  fi
done
```

### 8. Check Related Issues and Dependencies

```bash
# Look for "Related Issues" section in issue body
RELATED_ISSUES=$(echo "$ISSUE_BODY" | rg "Related Issues" -A 5 | rg "#[0-9]+" -o)

if [ -n "$RELATED_ISSUES" ]; then
  echo "=== Related Issues ==="
  for RELATED in $RELATED_ISSUES; do
    RELATED_NUM=$(echo "$RELATED" | tr -d '#')
    RELATED_STATE=$(gh issue view $RELATED_NUM --json state --jq .state)
    RELATED_TITLE=$(gh issue view $RELATED_NUM --json title --jq .title)

    if [ "$RELATED_STATE" = "OPEN" ]; then
      echo "⚠ $RELATED - $RELATED_TITLE (OPEN - may be dependency)"
    else
      echo "✓ $RELATED - $RELATED_TITLE (CLOSED)"
    fi
  done
fi

# Check for blocking issues
BLOCKING=$(echo "$ISSUE_BODY" | rg -i "blocked by|depends on" -A 2)
if [ -n "$BLOCKING" ]; then
  echo ""
  echo "⚠ Warning: This issue may have dependencies:"
  echo "$BLOCKING"
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Select a different issue."
    exit 1
  fi
fi
```

### 9. Read Affected Specs

```bash
echo "=== Reading Affected Specs ==="
for SPEC_PATH in $AFFECTED_SPECS; do
  echo ""
  echo "--- $SPEC_PATH ---"
  cat "$SPEC_PATH"
  echo ""
done

# If spec has design.md, read it too
for SPEC_PATH in $AFFECTED_SPECS; do
  SPEC_DIR=$(dirname "$SPEC_PATH")
  DESIGN_PATH="$SPEC_DIR/design.md"

  if [ -f "$DESIGN_PATH" ]; then
    echo "--- $DESIGN_PATH ---"
    cat "$DESIGN_PATH"
    echo ""
  fi
done
```

### 10. Read Development Retrospective

Read accumulated learnings to inform implementation:

```bash
if [ -f "RETROSPECTIVE.md" ]; then
  echo ""
  echo "=== Development Retrospective ==="
  cat RETROSPECTIVE.md
  echo ""
  echo "Consider these learnings during implementation:"
  echo "  - Apply success patterns from recent issues"
  echo "  - Avoid known friction points"
  echo "  - Reference well-specified capabilities"
  echo "  - Follow active improvement initiatives"
  echo ""
elif [ -f "docs/RETROSPECTIVE.md" ]; then
  echo ""
  echo "=== Development Retrospective ==="
  cat docs/RETROSPECTIVE.md
  echo ""
  echo "Consider these learnings during implementation."
  echo ""
else
  echo ""
  echo "ℹ No RETROSPECTIVE.md found (this is normal for first few issues)"
  echo ""
fi
```

**Purpose**: The retrospective captures:
- **Recent patterns**: What worked/didn't work in last 3-5 issues
- **Historical wisdom**: Compressed learnings from earlier issues
- **Spec quality**: Which specs are good references vs need improvement
- **Active improvements**: Current process improvements being tracked

This context helps avoid repeating past mistakes and apply proven patterns.

### 11. Create Feature Branch

```bash
# Extract title and create kebab-case branch name
TITLE=$(gh issue view $ISSUE_NUMBER --json title --jq .title)
KEBAB_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;s/^-|-$//g' | cut -c1-40)

# Determine branch prefix from change type
CHANGE_TYPE=$(echo "$ISSUE_BODY" | rg "\[x\] (ADDED|MODIFIED|REMOVED)" -o -r '$1')

case "$CHANGE_TYPE" in
  "ADDED")
    PREFIX="feat"
    ;;
  "MODIFIED")
    PREFIX="feat"  # or "refactor" depending on scope
    ;;
  "REMOVED")
    PREFIX="refactor"
    ;;
  *)
    # Infer from labels
    if echo "$ISSUE_BODY" | rg -q "type:bug"; then
      PREFIX="fix"
    elif echo "$ISSUE_BODY" | rg -q "type:chore"; then
      PREFIX="chore"
    else
      PREFIX="feat"
    fi
    ;;
esac

BRANCH_NAME="${PREFIX}/${ISSUE_NUMBER}-${KEBAB_TITLE}"

# Create and switch to branch
git switch -c "$BRANCH_NAME"

echo "✓ Created and switched to: $BRANCH_NAME"
```

### 12. Initial Setup

Check if any setup is needed:

```bash
# Check if package.json changed recently (might need npm install)
MAIN_PACKAGE_DATE=$(git log -1 --format="%ai" main -- package.json 2>/dev/null)
if [ -n "$MAIN_PACKAGE_DATE" ]; then
  echo "Note: package.json was updated recently ($MAIN_PACKAGE_DATE)"
  echo "Running npm install..."
  npm install
fi

# Check if Prisma schema exists (might need generate)
if [ -f "prisma/schema.prisma" ]; then
  echo "Note: Prisma schema detected"
  echo "Running npx prisma generate..."
  npx prisma generate
fi

# Check for other setup scripts
if [ -f "scripts/setup.sh" ]; then
  echo "Note: Found setup script"
  echo "Running scripts/setup.sh..."
  bash scripts/setup.sh
fi
```

### 13. Update TODO.md

Add issue to "In Progress" section:

```markdown
## In Progress

- [ ] #201 - Curriculum Framework (feat/201-curriculum-framework)
  - **Started**: 2025-10-21
  - **Branch**: feat/201-curriculum-framework
  - **Specs**: docs/specs/curriculum-management/spec.md
  - **Priority**: P1
  - **Milestone**: S2
```

If TODO.md doesn't have "In Progress" section, create it:

```bash
# Check if section exists
if ! grep -q "## In Progress" TODO.md; then
  # Add section after sprint section
  sed -i '/^## Phase/a \\n## In Progress\n' TODO.md
fi

# Add issue entry
cat >> TODO.md << EOF

- [ ] #${ISSUE_NUMBER} - ${TITLE} (${BRANCH_NAME})
  - **Started**: $(date +%Y-%m-%d)
  - **Branch**: ${BRANCH_NAME}
  - **Specs**: ${AFFECTED_SPECS}
  - **Priority**: ${PRIORITY}
  - **Milestone**: ${MILESTONE}
EOF
```

### 14. Update Sprint File

Find the relevant sprint file and update story status:

```bash
# Find sprint file (match milestone to sprint file)
MILESTONE=$(gh issue view $ISSUE_NUMBER --json milestone --jq .milestone.title)
SPRINT_NUM=$(echo "$MILESTONE" | rg "S([0-9]+)" -o -r '$1')
SPRINT_FILE="docs/sprint/S${SPRINT_NUM}.md"

if [ -f "$SPRINT_FILE" ]; then
  # Find the story section and update status
  # This is complex; in practice, manually update the file
  echo "Update $SPRINT_FILE:"
  echo "  - Find story section for: $TITLE"
  echo "  - Add: **Status**: In Progress"
  echo "  - Add: **Branch**: $BRANCH_NAME"
  echo "  - Add: **Started**: $(date +%Y-%m-%d)"
fi
```

Example sprint file update:

```markdown
## Curriculum Framework

**User Story**: As an educator...

**Status**: In Progress
**Branch**: feat/201-curriculum-framework
**Started**: 2025-10-21
**Issue**: #201
```

### 15. Provide Summary

```
✓ Started work on issue #201

Issue: Curriculum Framework
Branch: feat/201-curriculum-framework
Priority: P1
Milestone: S2

Affected specs:
  - docs/specs/curriculum-management/spec.md

Review comments: 1 comment (review suggestions available)

Next steps:
  1. Review issue comments and review suggestions
  2. Review spec requirements and scenarios
  3. Implement according to acceptance criteria (considering review feedback)
  4. Write tests per test plan
  5. Run 'test-issue' before submitting
  6. Run 'submit-issue' when ready for PR

Dependencies to watch:
  - None identified

Happy coding! 🚀
```

## Priority Order

Issues are recommended in this order:

1. **P0 - Critical**: Blocking bugs, production issues
2. **P1 - High**: Important features, high-value work
3. **P2 - Medium**: Standard features, improvements
4. **P3 - Low**: Nice-to-have, technical debt

Within same priority:
- Current sprint milestone before future sprints
- Issues with ready specs before those needing spec work
- Non-blocked issues before those with dependencies

## Dependency Checking

### Types of Dependencies

1. **Hard dependencies**: "Blocked by #123", "Depends on #123"
   - Must be completed first
   - Halt if not complete

2. **Soft dependencies**: "Related to #123", "See also #123"
   - Provide context but not blocking
   - Read for additional information

3. **Spec dependencies**: One spec depends on another
   - Check if dependency specs exist
   - Verify dependency requirements are clear

### Handling Blocked Issues

If selected issue is blocked:

```
⚠ Issue #203 is blocked by #201 (Curriculum Framework)

#201 status: In Progress (50% complete)

Options:
1. Wait for #201 to complete
2. Select different issue
3. Proceed with risk (may need rework)

Recommendation: Select different issue and return to #203 later.
```

## Spec Readiness Validation

Before starting work, ensure:

- [ ] All referenced specs exist in `docs/specs/`
- [ ] Specs have clear requirements
- [ ] Each requirement has scenarios
- [ ] Dependencies between specs are documented
- [ ] Design docs exist for complex changes

If spec is incomplete:
1. Consider running `init-spec` to complete it
2. Or flag issue for spec refinement before starting

## File Update Patterns

### TODO.md Format

```markdown
## In Progress

- [ ] #201 - Curriculum Framework (feat/201-curriculum-framework)
  - **Started**: 2025-10-21
  - **Branch**: feat/201-curriculum-framework
  - **Specs**: docs/specs/curriculum-management/spec.md
  - **Priority**: P1
  - **Milestone**: S2
  - **Dependencies**: None
```

### Sprint File Format

```markdown
## Curriculum Framework

**User Story**: As an educator, I want to define course structures...

**Acceptance Criteria**:
- Course hierarchy supported
- Learning objectives trackable

**Status**: In Progress
**Branch**: feat/201-curriculum-framework
**Started**: 2025-10-21
**Issue**: #201
**Assigned**: @username
```

## Error Handling

### Dirty Working Directory

```
⚠ Error: Uncommitted changes detected

Please commit or stash changes before starting new issue:
  git add .
  git commit -m "wip: save progress"
  # or
  git stash

Then run 'next-issue' again.
```

### Not on Main Branch

```
⚠ Error: Currently on branch: feat/123-old-issue

Please finish current work first:
  1. Complete implementation
  2. Run 'submit-issue' to create PR
  3. Or: git switch main (to abandon work)

Then run 'next-issue' again.
```

### Missing Specs

```
⚠ Error: Spec not found
  docs/specs/curriculum-management/spec.md

Issue #201 references specs that don't exist yet.

Action required:
  1. Run: init-spec curriculum-management
  2. Create spec.md with requirements
  3. Run 'next-issue' again
```

### No Available Issues

```
ℹ No issues assigned to you.

Possible actions:
  1. Check sprint backlog in GitHub
  2. Assign yourself an issue from current sprint
  3. Run 'seed-sprint' to create new issues
  4. Contact Scrum Master for assignment
```

## Advanced: Context Caching

To optimize repeated API calls, consider caching:

```bash
# Cache issue list for 5 minutes
CACHE_FILE="/tmp/gh-issues-cache-$(date +%Y%m%d-%H%M).json"
if [ ! -f "$CACHE_FILE" ]; then
  gh issue list --assignee @me --state open --json number,title,labels,milestone > "$CACHE_FILE"
fi

# Use cached data
ISSUES=$(cat "$CACHE_FILE")
```

## Notes

- Always verify clean state before starting new work
- Read all related issues for full context
- Check spec completeness before implementation
- Update tracking files immediately after branch creation
- Consider dependencies when selecting issues
- Prefer current sprint issues over future work
- Validate specs exist and are complete
- Note any setup requirements (npm install, prisma generate, etc.)
