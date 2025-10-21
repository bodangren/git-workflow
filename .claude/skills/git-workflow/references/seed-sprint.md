# Seed Sprint Command

Create GitHub issues for the next sprint based on sprint markdown files (Scrum Master command).

## Purpose

Transform sprint planning documents into actionable GitHub issues with proper spec references, labels, and tracking.

## When to Use

- Starting a new sprint
- Converting planned stories into tracked issues
- Creating milestone-based work packages
- Seeding backlog with spec-referenced work

## Workflow

### 1. Get All Milestones for Context

```bash
# Get all milestones to understand current and future sprints
gh api repos/:owner/:repo/milestones --json number,title,state,description,dueOn | jq '.'
```

### 2. Analyze Existing Sprint Files

```bash
# List existing sprint files
ls -la docs/sprint/

# Check what's already been processed
rg "Issue.*#[0-9]+" docs/sprint/
```

### 3. Suggest Next Sprint

Analyze existing milestones and sprint files:
- Identify the next sprint number
- Check for corresponding sprint file (e.g., `docs/sprint/S2.md`)
- Recommend sprint file to process
- Ask user to confirm or specify different sprint

Example prompt:
> "I found milestones S0 (closed) and S1 (open). I see sprint file S2.md ready to process. Should I create issues for Sprint S2?"

### 4. Read and Parse Sprint File

```bash
# Read the selected sprint file
SPRINT_FILE="docs/sprint/S2.md"
cat "$SPRINT_FILE"
```

Parse each story looking for:
- **Story Title** (## headers)
- **User Story** section
- **Acceptance Criteria** section
- **Test Plan** section
- **Labels:** line (e.g., `Labels: type:feature,area:frontend,priority:P2`)
- **Agent Assignment:** line
- **Affected Specs:** line (NEW - references to `docs/specs/[capability]`)
- **Change Type:** (NEW - ADDED/MODIFIED/REMOVED)

### 5. Validate Spec References

For each story, verify referenced specs exist:

```bash
# Check if spec exists
SPEC_PATH="docs/specs/authentication/spec.md"
if [ -f "$SPEC_PATH" ]; then
  echo "✓ Spec exists: $SPEC_PATH"
else
  echo "⚠ Spec missing: $SPEC_PATH"
  echo "Run 'init-spec' to create it first"
fi
```

If specs are missing:
1. Halt sprint seeding
2. Recommend running `init-spec` for missing capabilities
3. Wait for user confirmation to proceed

### 6. Create or Verify Milestone

```bash
# Check if milestone exists
MILESTONE_TITLE="S2 – Core Curriculum & Content Management"

# Try to get milestone
MILESTONE_NUM=$(gh api repos/:owner/:repo/milestones \
  --jq ".[] | select(.title == \"$MILESTONE_TITLE\") | .number")

# Create if doesn't exist
if [ -z "$MILESTONE_NUM" ]; then
  MILESTONE_NUM=$(gh api repos/:owner/:repo/milestones \
    --method POST \
    --field title="$MILESTONE_TITLE" \
    --field description="Epic 2: Build curriculum framework, lesson player, virtual labs, bilingual CMS, and assessment engine" \
    --field due_on="2025-11-15T00:00:00Z" \
    --jq .number)
  echo "Created milestone #$MILESTONE_NUM"
else
  echo "Using existing milestone #$MILESTONE_NUM"
fi
```

### 7. Process Each Story

For each story in the sprint file:

```bash
# Extract story details
TITLE="Story Title from ## header"
USER_STORY="Content from User Story section"
ACCEPTANCE_CRITERIA="Content from Acceptance Criteria section"
TEST_PLAN="Content from Test Plan section"
LABELS="type:feature,area:frontend,priority:P2"
ASSIGNEE="@me"
AFFECTED_SPECS="docs/specs/authentication/spec.md, docs/specs/user-profile/spec.md"
CHANGE_TYPE="ADDED"  # or MODIFIED, REMOVED

# Build issue body with spec-driven format
BODY=$(cat <<EOF
## User Story

$USER_STORY

## Affected Specs

$AFFECTED_SPECS

## Change Type

- [$([ "$CHANGE_TYPE" = "ADDED" ] && echo "x" || echo " ")] ADDED Requirements (new capability)
- [$([ "$CHANGE_TYPE" = "MODIFIED" ] && echo "x" || echo " ")] MODIFIED Requirements
- [$([ "$CHANGE_TYPE" = "REMOVED" ] && echo "x" || echo " ")] REMOVED Requirements

## Proposed Spec Changes

### $CHANGE_TYPE Requirements

[Extract from sprint file or note "To be detailed during implementation"]

## Acceptance Criteria

$ACCEPTANCE_CRITERIA

## Test Plan

$TEST_PLAN

## Implementation Checklist

- [ ] Spec updated in docs/specs/
- [ ] Tests written and passing
- [ ] Design doc created (if needed)
- [ ] Code implemented
- [ ] PR created and reviewed
EOF
)

# Create the issue
ISSUE_NUMBER=$(gh issue create \
  --title "$TITLE" \
  --body "$BODY" \
  --label "$LABELS" \
  --milestone "$MILESTONE_TITLE" \
  --assignee "$ASSIGNEE" \
  --json number --jq .number)

echo "✓ Created issue #$ISSUE_NUMBER: $TITLE"
```

### 8. Update TODO.md

Add or update sprint section:

```markdown
## Phase 2: Core Curriculum & Content Management (S2)

### Sprint S2 – Core Curriculum & Content Management

**Started**: 2025-10-21
**Milestone**: S2 – Core Curriculum & Content Management
**Due**: 2025-11-15

**Issues Created**:

- [ ] #201 - Curriculum Framework (P1) - Specs: curriculum-management
- [ ] #202 - Lesson Player (P1) - Specs: content-delivery
- [ ] #203 - Virtual Laboratory System (P2) - Specs: lab-environment
- [ ] #204 - Bilingual CMS (P2) - Specs: content-management
- [ ] #205 - Assessment Engine (P1) - Specs: assessment-system

**Progress**: 0/5 (0%)
```

### 9. Update Sprint File

Add issue metadata to each story:

```markdown
# Sprint S2 – Core Curriculum & Content Management

**Milestone**: S2 – Core Curriculum & Content Management
**Created**: 2025-10-21
**Issues Created**: 5
**Status**: Active

---

## Curriculum Framework

**User Story**: As an educator, I want to define course structures...

**Acceptance Criteria**:
- Course hierarchy supported
- Learning objectives trackable

**Test Plan**:
- Unit tests for course model
- Integration tests for hierarchy

**Labels**: type:feature,area:backend,priority:P1
**Affected Specs**: docs/specs/curriculum-management/spec.md
**Change Type**: ADDED

**Issue**: #201 - Created: 2025-10-21
**Agent Assignment**: dev (James), architect (Winston)
**Status**: Ready

---

## Lesson Player

[Same structure for each story]
```

### 10. Provide Summary

After all issues created:

```
✓ Sprint S2 seeded successfully

Created 5 issues in milestone "S2 – Core Curriculum & Content Management":
  #201 - Curriculum Framework (P1)
  #202 - Lesson Player (P1)
  #203 - Virtual Laboratory System (P2)
  #204 - Bilingual CMS (P2)
  #205 - Assessment Engine (P1)

Updated:
  - TODO.md (Phase 2 section added)
  - docs/sprint/S2.md (Issue numbers added)

Next steps:
  - Review issues in GitHub
  - Run 'next-issue' to start work
  - Ensure all referenced specs exist in docs/specs/
```

## Sprint File Format

### Minimal Sprint File Template

```markdown
# Sprint S2 – Sprint Title

**Epic**: Epic description
**Goal**: Sprint goal statement

---

## Story Title

**User Story**: As a [role], I want [feature] so that [benefit]

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] Criterion 2

**Test Plan**:
- Test scenario 1
- Test scenario 2

**Labels**: type:feature,area:backend,priority:P1
**Affected Specs**: docs/specs/capability-name/spec.md
**Change Type**: ADDED
**Agent Assignment**: dev (James), architect (Winston)

---

## Another Story Title

[Same structure]
```

## Change Type Guidelines

### ADDED
Use when story introduces entirely new capability:
- New feature with no prior existence
- New spec file will be created
- Example: "Add two-factor authentication"

### MODIFIED
Use when story changes existing functionality:
- Modifies existing spec requirements
- Enhances or alters current behavior
- Example: "Update login to support OAuth"

### REMOVED
Use when story removes functionality:
- Deprecates features
- Removes requirements from spec
- Example: "Remove legacy password reset flow"

## Label Patterns

**Type labels:**
- `type:feature` - New features
- `type:enhancement` - Improvements to existing features
- `type:bug` - Bug fixes
- `type:chore` - Maintenance, refactoring
- `type:docs` - Documentation updates
- `type:spec` - Spec-only updates

**Area labels:**
- `area:frontend` - UI/UX changes
- `area:backend` - Server/API changes
- `area:devex` - Developer experience
- `area:infrastructure` - DevOps, CI/CD
- `area:design` - Design system, patterns

**Priority labels:**
- `priority:P0` - Critical, blocking
- `priority:P1` - High priority
- `priority:P2` - Medium priority
- `priority:P3` - Low priority, nice-to-have

**Spec-related labels:**
- `add-capability` - New capability spec
- `modify-spec` - Changes to existing spec
- `remove-feature` - Deprecation

## Agent Assignment Mapping

Standard roles (customize for your team):
- **dev (James)**: Implementation
- **architect (Winston)**: System design, technical decisions
- **qa (Quinn)**: Quality assurance, testing strategy
- **ux-expert (Sally)**: UI/UX design, user research
- **po (Sarah)**: Product ownership, requirements
- **sm (Bob)**: Scrum master, process management

## Error Handling

### Missing Specs
```
⚠ Error: Spec not found: docs/specs/authentication/spec.md

Story "Add Two-Factor Auth" references specs that don't exist.

Action required:
1. Run: init-spec authentication
2. Create spec.md with requirements
3. Re-run: seed-sprint
```

### Milestone Creation Failure
```bash
# Check permissions
gh auth status

# Verify repository access
gh api repos/:owner/:repo/milestones --method GET
```

### Issue Creation Failure
Common causes:
- Invalid assignee (user not in org)
- Label doesn't exist (create first)
- Milestone not found (check title match)
- Permissions insufficient

### File Update Conflicts
If TODO.md or sprint file has uncommitted changes:
1. Stash or commit current changes
2. Re-run seed-sprint
3. Review and merge updates

## Validation Checklist

Before seeding sprint:
- [ ] Sprint file exists and is properly formatted
- [ ] All referenced specs exist in docs/specs/
- [ ] Milestone name is clear and unique
- [ ] Labels are defined in repository
- [ ] Assignees are valid GitHub users
- [ ] Story titles are descriptive and unique
- [ ] Each story has acceptance criteria and test plan
- [ ] Change types are specified (ADDED/MODIFIED/REMOVED)

After seeding sprint:
- [ ] All issues created successfully
- [ ] Issue numbers recorded in sprint file
- [ ] TODO.md updated with sprint section
- [ ] Milestone shows correct issue count
- [ ] Labels applied correctly
- [ ] Assignees set properly

## Advanced: Dry Run Mode

Before creating issues, do a dry run:

```bash
# Parse sprint file and show what would be created
echo "=== DRY RUN: Sprint S2 ==="
echo ""
echo "Would create 5 issues:"
echo "  1. Curriculum Framework (P1) → docs/specs/curriculum-management"
echo "  2. Lesson Player (P1) → docs/specs/content-delivery"
echo "  3. Virtual Laboratory System (P2) → docs/specs/lab-environment"
echo "  4. Bilingual CMS (P2) → docs/specs/content-management"
echo "  5. Assessment Engine (P1) → docs/specs/assessment-system"
echo ""
echo "Milestone: S2 – Core Curriculum & Content Management"
echo "Due: 2025-11-15"
echo ""
read -p "Proceed with issue creation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi
```

## Notes

- Always confirm sprint selection before creating issues
- Validate all spec references exist
- Update both TODO.md and sprint file atomically
- Include proper agent assignments for team coordination
- Use consistent label patterns across all issues
- Provide clear issue numbers for tracking
- Consider using issue templates for consistency
