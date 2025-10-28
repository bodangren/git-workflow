# Split Issue Command

Break a large issue into smaller, atomic issues when scope exceeds single-chat capacity (~200K tokens).

## Purpose

Maintain development momentum by ensuring each issue can be completed in a single focused chat session. Prevents context overflow and allows incremental progress on large features.

## When to Use

- Issue estimated to exceed ~200K tokens
- Implementation requires multiple distinct phases
- Testing alone would consume significant tokens
- Issue combines unrelated concerns
- Scope grew during planning or implementation
- LLM indicates it's too large to complete in one session

## Warning Signs an Issue Needs Splitting

- Acceptance criteria has >10 items
- Test plan spans multiple testing types extensively
- Multiple capabilities/specs affected
- Both backend and frontend work in same issue
- Issue description is >500 lines
- Estimated >3 days for single developer
- Implementation requires extensive research first

## Workflow

### 1. Analyze Original Issue

```bash
ORIGINAL_ISSUE=203

# Get full issue details
gh issue view $ORIGINAL_ISSUE

# Review:
# - How many acceptance criteria?
# - How many specs affected?
# - Test complexity?
# - Can it be done in phases?
```

### 2. Identify Split Strategy

**Common split patterns:**

**Pattern A: Backend/Frontend Split**
```
Original: "Add user profile management"
→ Split into:
  - Backend: API endpoints and data models
  - Frontend: UI components and integration
```

**Pattern B: Core/Edge Cases Split**
```
Original: "Implement payment processing"
→ Split into:
  - Core: Happy path (successful payment)
  - Edge cases: Failures, retries, refunds
```

**Pattern C: Implementation/Testing Split**
```
Original: "Add comprehensive test coverage"
→ Split into:
  - Unit tests
  - Integration tests
  - E2E tests
```

**Pattern D: Phase-Based Split**
```
Original: "Build lesson player with video, quiz, and progress tracking"
→ Split into:
  - Phase 1: Video playback
  - Phase 2: Quiz integration
  - Phase 3: Progress tracking
```

**Pattern E: Spec/Implementation Split**
```
Original: "Add new capability (spec + code)"
→ Split into:
  - Spec creation (init-spec)
  - Implementation
```

### 3. Choose Split Approach

Decide whether to use parent/child or sequential approach:

**Parent/Child Approach** (parallel work possible):
```
#203 [PARENT] - Virtual Laboratory System
  ├── #301 - Backend simulation engine
  ├── #302 - Frontend 3D viewer
  └── #303 - Integration and E2E tests
```

**Sequential Approach** (must be done in order):
```
#203 → #301 → #302
Phase 1  Phase 2  Phase 3
```

### 4. Create Parent/Tracking Issue (Parent/Child Approach)

```bash
# Convert original issue to parent tracker
gh issue edit $ORIGINAL_ISSUE \
  --title "[PARENT] Virtual Laboratory System" \
  --add-label "parent-issue"

# Add tracking comment
TRACKING_COMMENT=$(cat <<EOF
## Split into Subtasks

This issue is too large for single implementation. Split into:

**Subtasks:**
- [ ] #301 - Backend simulation engine (core functionality)
- [ ] #302 - Frontend 3D viewer (UI components)
- [ ] #303 - Integration and E2E tests (comprehensive testing)

**Completion Criteria:**
All subtasks must be completed and merged before closing this parent issue.

**Progress:** 0/3 subtasks complete

---

*Original issue body preserved below for reference*
EOF
)

gh issue comment $ORIGINAL_ISSUE --body "$TRACKING_COMMENT"
```

### 5. Create Child Issues

For each subtask:

```bash
# Define subtasks
SUBTASKS=(
  "Backend simulation engine:type:feature,area:backend,priority:P1"
  "Frontend 3D viewer:type:feature,area:frontend,priority:P1"
  "Integration and E2E tests:type:test,area:testing,priority:P2"
)

MILESTONE=$(gh issue view $ORIGINAL_ISSUE --json milestone --jq .milestone.title)

for SUBTASK in "${SUBTASKS[@]}"; do
  IFS=':' read -r TITLE LABELS <<< "$SUBTASK"

  # Create child issue
  CHILD_NUM=$(gh issue create \
    --title "$TITLE" \
    --body "## Part of Parent Issue

**Parent**: #${ORIGINAL_ISSUE} - Virtual Laboratory System

## Scope

This issue handles: ${TITLE}

[Add specific details for this subtask]

## Acceptance Criteria

[Subset of parent criteria relevant to this subtask]

## Test Plan

[Subset of parent test plan relevant to this subtask]

## Implementation Checklist

- [ ] Implementation complete
- [ ] Tests passing
- [ ] Specs updated (if applicable)
- [ ] Parent issue updated

## Notes

This is part ${SUBTASK_INDEX} of 3 in the overall implementation." \
    --label "$LABELS" \
    --milestone "$MILESTONE" \
    --assignee "@me" \
    --json number --jq .number)

  echo "✓ Created child issue #$CHILD_NUM: $TITLE"
done
```

### 6. Link Issues in Parent

Update parent tracking comment with created child issue numbers:

```bash
# Update parent with actual issue numbers
gh issue comment $ORIGINAL_ISSUE --body "## Subtasks Created

- [ ] #301 - Backend simulation engine
- [ ] #302 - Frontend 3D viewer
- [ ] #303 - Integration and E2E tests

Work will proceed on child issues. This parent tracks overall progress."
```

### 7. Close or Keep Open Parent

**Option A: Close parent, track via children**
```bash
gh issue close $ORIGINAL_ISSUE --comment "Split into subtasks #301, #302, #303.
Tracking completion there. Will reopen if needed for integration issues."
```

**Option B: Keep parent open for tracking**
```bash
# Just add comment, leave open
gh issue comment $ORIGINAL_ISSUE --body "Parent issue remains open to track completion of all subtasks."
```

### 8. Update Sprint File

```markdown
## Virtual Laboratory System

**Status**: Split into subtasks
**Original Issue**: #203 (now parent/closed)
**Subtasks**:
- [ ] #301 - Backend simulation engine (P1)
- [ ] #302 - Frontend 3D viewer (P1)
- [ ] #303 - Integration and E2E tests (P2)

**Strategy**: Implement backend first, then frontend, then comprehensive tests

**Progress**: 0/3 complete
```

### 9. Update TODO.md

```markdown
## Sprint S2 - Virtual Laboratory (Split)

**Original**: #203 (too large, split into phases)

**Phase 1 - Backend** (Ready):
- [ ] #301 - Backend simulation engine
  - Estimated: 150K tokens
  - Priority: P1

**Phase 2 - Frontend** (Blocked by #301):
- [ ] #302 - Frontend 3D viewer
  - Estimated: 150K tokens
  - Priority: P1
  - Dependencies: #301

**Phase 3 - Testing** (Blocked by #301, #302):
- [ ] #303 - Integration and E2E tests
  - Estimated: 100K tokens
  - Priority: P2
  - Dependencies: #301, #302

**Total estimated**: ~400K tokens → split into 3 manageable issues
```

### 10. Proceed with First Child Issue

```bash
# Start work on first subtask
run: next-issue

# Select #301 (Backend simulation engine)
# This is now sized appropriately for single chat session
```

## Sequential Split Approach

For issues that must be done in order:

```bash
# Don't create parent - just create sequence
ORIGINAL_ISSUE=203

# Create Phase 1
PHASE1=$(gh issue create \
  --title "Virtual Lab - Phase 1: Backend simulation engine" \
  --body "First phase of #${ORIGINAL_ISSUE}.

Implements core backend functionality. Must complete before Phase 2.

**Next**: #TBD (Phase 2 - Frontend will be created after this completes)" \
  --label "type:feature,area:backend,priority:P1,phase:1" \
  --milestone "$MILESTONE")

# Close original with reference
gh issue close $ORIGINAL_ISSUE --comment "Split into phases.
Starting with Phase 1: #${PHASE1}
Phase 2 will be created after Phase 1 completes."

# Work on Phase 1
run: next-issue → select Phase 1

# After Phase 1 completes, create Phase 2 with reference to Phase 1
```

## Split Decision Matrix

| Characteristic | Don't Split | Split | How to Split |
|----------------|-------------|-------|--------------|
| Token estimate | <150K | >200K | By phase or component |
| Acceptance criteria | <5 items | >10 items | Group related criteria |
| Specs affected | 1 spec | 3+ specs | By spec/capability |
| Backend + Frontend | Small feature | Large feature | Backend/Frontend |
| Testing scope | Unit only | Unit+Integration+E2E | By test type |
| Dependencies | None | Complex tree | By dependency layer |
| Implementation phases | Single pass | Multiple phases | By phase |

## Best Practices

1. **Split early**: Better to split during planning than mid-implementation
2. **Clear boundaries**: Each child should be independently testable
3. **Size consistently**: Aim for 100-150K tokens per child issue
4. **Maintain context**: Link children to parent, document relationships
5. **Sequence dependencies**: Mark which children block others
6. **Update parent**: Keep parent issue updated as children complete
7. **Test integration**: Consider final integration/E2E issue after children
8. **Learn from splits**: Note in retrospective when issues were too large

## Anti-Patterns to Avoid

❌ **Arbitrary splitting**: Don't split just to hit token count without logical boundaries
```
Bad: "Implement feature - Part 1", "Implement feature - Part 2" (no clear distinction)
```

❌ **Too granular**: Don't split into trivially small issues
```
Bad: One issue per function (too much overhead)
```

❌ **Forgetting integration**: Don't assume split issues will work together without testing
```
Missing: Integration test issue after backend/frontend split
```

❌ **Unclear dependencies**: Don't leave unclear which order children should be done
```
Bad: Three parallel issues that actually depend on each other
```

## Example: Large Feature Split

**Original Issue: #203** (Estimated 400K tokens)
```
Title: Implement Virtual Laboratory System

Acceptance Criteria:
- [ ] 3D simulation engine running
- [ ] WebGL-based 3D viewer
- [ ] Physics calculations accurate
- [ ] User interactions (pan, zoom, rotate)
- [ ] Preset scenarios loadable
- [ ] Results exportable
- [ ] Performance <60fps
- [ ] Mobile responsive
- [ ] Integration with curriculum
- [ ] Comprehensive test coverage

Too large! Needs splitting.
```

**After Split:**

**#301 - Backend Simulation Engine** (Est. 150K)
```
Acceptance Criteria:
- [ ] Physics calculations accurate
- [ ] Simulation state management
- [ ] API endpoints for simulation control
- [ ] Preset scenarios loadable
- [ ] Unit tests for physics engine
```

**#302 - Frontend 3D Viewer** (Est. 150K)
```
Dependencies: #301
Acceptance Criteria:
- [ ] WebGL-based 3D viewer
- [ ] User interactions (pan, zoom, rotate)
- [ ] Connect to backend API
- [ ] Performance <60fps
- [ ] Mobile responsive
- [ ] Component tests
```

**#303 - Integration & Polish** (Est. 100K)
```
Dependencies: #301, #302
Acceptance Criteria:
- [ ] Integration with curriculum system
- [ ] Results exportable
- [ ] E2E tests for full workflow
- [ ] Performance testing
- [ ] Documentation
```

Each child is now manageable in single chat session!

## Notes

- Splitting is a normal part of agile workflow - not a failure
- Better to split proactively than get stuck mid-implementation
- Document split reasoning in retrospective for future planning
- Update story point estimates if you use them
- PM should review large issues during planning to catch split candidates early
- Each child issue should be independently valuable if possible
- Consider "walking skeleton" approach: implement thin vertical slice first, then expand
