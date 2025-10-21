# Review Sprint Command

AI-powered quality review of all issues in the current sprint for architecture compliance, wording, and planning improvements.

## Purpose

Provide constructive feedback on sprint issues before developers start implementation. Reviews check architecture requirements, validates planning quality, and suggests improvements while maintaining respectful, suggestion-based tone.

## When to Use

- After running `seed-sprint` to create sprint issues
- Before developers begin work with `next-issue`
- When sprint planning needs quality validation
- To ensure architectural consistency across sprint

## Workflow

### 1. Identify Current Sprint

```bash
# Get active sprint milestones
gh api repos/:owner/:repo/milestones \
  --jq '.[] | select(.state == "open") | {number, title, due_on, open_issues}' \
  | jq -s 'sort_by(.due_on) | .[0]'

# Store milestone info
MILESTONE_NUM=$(gh api repos/:owner/:repo/milestones \
  --jq '.[] | select(.state == "open") | .number' | head -1)
MILESTONE_TITLE=$(gh api repos/:owner/:repo/milestones/$MILESTONE_NUM --jq .title)

echo "Reviewing sprint: $MILESTONE_TITLE (Milestone #$MILESTONE_NUM)"
```

### 2. Get All Issues in Sprint

```bash
# Get all open issues for the milestone
gh issue list \
  --milestone "$MILESTONE_TITLE" \
  --state open \
  --json number,title,labels,body,assignees \
  --limit 100 > /tmp/sprint-issues.json

# Count issues
ISSUE_COUNT=$(cat /tmp/sprint-issues.json | jq 'length')
echo "Found $ISSUE_COUNT issues to review"
```

### 3. Load Architecture Requirements

For each issue, identify the relevant architecture documentation:

```bash
# Read issue to extract affected specs
ISSUE_NUM=201
ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body --jq .body)

# Extract affected specs
AFFECTED_SPECS=$(echo "$ISSUE_BODY" | rg "Affected Specs" -A 10 | rg "docs/specs/[^)]+")

# For each spec, check for design.md (architecture)
for SPEC_PATH in $AFFECTED_SPECS; do
  SPEC_DIR=$(dirname "$SPEC_PATH")
  DESIGN_PATH="$SPEC_DIR/design.md"

  if [ -f "$DESIGN_PATH" ]; then
    echo "Reading architecture from: $DESIGN_PATH"
    ARCH_CONTEXT=$(cat "$DESIGN_PATH")
  fi

  # Also read the spec for context
  if [ -f "$SPEC_PATH" ]; then
    SPEC_CONTEXT=$(cat "$SPEC_PATH")
  fi
done

# Also check for global architecture docs
GLOBAL_ARCH=""
if [ -f "docs/ARCHITECTURE.md" ]; then
  GLOBAL_ARCH=$(cat "docs/ARCHITECTURE.md")
elif [ -f "ARCHITECTURE.md" ]; then
  GLOBAL_ARCH=$(cat "ARCHITECTURE.md")
elif [ -f "docs/architecture.md" ]; then
  GLOBAL_ARCH=$(cat "docs/architecture.md")
fi

# Check for CLAUDE.md or AGENTS.md
AGENT_CONTEXT=""
if [ -f "CLAUDE.md" ]; then
  AGENT_CONTEXT=$(cat "CLAUDE.md")
elif [ -f "AGENTS.md" ]; then
  AGENT_CONTEXT=$(cat "AGENTS.md")
elif [ -f "docs/CLAUDE.md" ]; then
  AGENT_CONTEXT=$(cat "docs/CLAUDE.md")
fi
```

### 4. Review Each Issue

For each issue, conduct a comprehensive review covering:

#### A. Architecture Compliance

Check against architecture requirements from:
- Global architecture docs (ARCHITECTURE.md)
- Spec-level design docs (docs/specs/[capability]/design.md)
- Agent guidelines (CLAUDE.md, AGENTS.md)

**Review criteria:**
- Does the approach align with documented architecture patterns?
- Are there SOLID principle violations?
- Does it respect existing layering/boundaries?
- Are there security implications not addressed?
- Does it follow established data flow patterns?
- Are API contracts consistent with existing patterns?
- Does it introduce new dependencies appropriately?

#### B. Wording and Clarity

**Review criteria:**
- Is the user story clear and testable?
- Are acceptance criteria specific and measurable?
- Is technical jargon explained or avoided where possible?
- Are requirements unambiguous?
- Does the title accurately reflect the work?
- Is the scope well-defined (not too broad)?

#### C. Planning Quality

**Review criteria:**
- Are acceptance criteria complete and testable?
- Does the test plan cover key scenarios?
- Are edge cases considered?
- Is the change type (ADDED/MODIFIED/REMOVED) accurate?
- Are affected specs correctly identified?
- Are dependencies documented?
- Is the priority justified?
- Are labels appropriate and complete?
- Is the scope reasonable for a single issue?

#### D. Spec Alignment

**Review criteria:**
- Do proposed spec changes align with issue goals?
- Are new requirements properly formatted (SHALL/MUST)?
- Are scenarios provided for new requirements?
- Are API contracts specified for new endpoints?
- Are data models defined for new entities?

### 5. Format Review Comments

Structure each review comment as:

```markdown
**This is [AI Model Name] ([Role])**

I've reviewed this issue and have some suggestions to consider:

## Architecture

[If applicable, architecture-related suggestions]
- Consider [architectural pattern/principle]
- Suggestion: [specific recommendation]
- Reference: [link to architecture doc, if applicable]

## Wording & Clarity

[If applicable, wording improvements]
- The user story could be clearer: [suggestion]
- Acceptance criteria suggestion: [specific improvement]
- Consider rephrasing [section] to: [suggestion]

## Planning

[If applicable, planning improvements]
- Test plan suggestion: [additional test scenarios to consider]
- Consider adding acceptance criterion for: [edge case]
- Scope concern: [if issue seems too large/small]

## Spec Changes

[If applicable, spec-related suggestions]
- Proposed requirement could be more specific: [suggestion]
- Consider adding scenario for: [use case]
- Suggestion for API contract: [recommendation]

## Additional Considerations

[If applicable, other observations]
- Dependency note: [related issues or specs to consider]
- Risk to consider: [potential implementation challenges]
- Documentation note: [areas needing extra documentation]

---

These are suggestions to consider - feel free to discuss or modify as you see fit. Happy to clarify any points!
```

**Tone guidelines:**
- Use "Consider" and "Suggest" language (not "Must" or "Should")
- Frame as questions when appropriate: "Have you considered...?"
- Acknowledge good aspects when present: "The acceptance criteria are well-defined. Additionally, consider..."
- Be specific with examples
- Reference documentation when relevant
- Respect the original author's intent

### 6. Post Review Comments

```bash
# For each issue, post the review comment
ISSUE_NUM=201
REVIEW_COMMENT="[Formatted comment from step 5]"

gh issue comment $ISSUE_NUM --body "$REVIEW_COMMENT"

echo "✓ Posted review on issue #$ISSUE_NUM"
```

### 7. Track Review Progress

Maintain a simple tracking mechanism:

```bash
# Create review log
REVIEW_LOG="docs/sprint/review-log-$(date +%Y%m%d).md"

cat > "$REVIEW_LOG" << EOF
# Sprint Review Log - $(date +%Y-%m-%d)

**Sprint**: $MILESTONE_TITLE
**Reviewer**: [AI Model Name/Role]
**Issues Reviewed**: $ISSUE_COUNT

## Issues

EOF

# For each reviewed issue, add entry
for ISSUE_NUM in $(cat /tmp/sprint-issues.json | jq -r '.[].number'); do
  TITLE=$(gh issue view $ISSUE_NUM --json title --jq .title)
  echo "- [x] #$ISSUE_NUM - $TITLE" >> "$REVIEW_LOG"
done

echo ""
echo "Review Summary"
echo "---" >> "$REVIEW_LOG"
echo "All issues reviewed. Comments posted as suggestions." >> "$REVIEW_LOG"
```

### 8. Provide Summary

After completing all reviews:

```
✓ Sprint review completed

Sprint: S2 – Core Curriculum & Content Management
Issues reviewed: 5
Comments posted: 5

Reviewed issues:
  #201 - Curriculum Framework
  #202 - Lesson Player
  #203 - Virtual Laboratory System
  #204 - Bilingual CMS
  #205 - Assessment Engine

Summary:
  - Architecture concerns: 1
  - Wording improvements: 3
  - Planning suggestions: 4
  - Spec enhancements: 2

Review log: docs/sprint/review-log-20251022.md

Next steps:
  - Developers should read issue + all comments before starting
  - Consider review suggestions during implementation
  - Update issues if significant changes needed
  - Run 'next-issue' when ready to begin work
```

## AI Reviewer Roles

Different AI models can serve different roles:

### Frontend Reviewer
- **Focus**: UI/UX patterns, accessibility, component design
- **Architecture checks**: Component hierarchy, state management, styling patterns
- **Example**: "This is Claude Sonnet (Frontend Reviewer)"

### Backend Reviewer
- **Focus**: API design, data models, business logic
- **Architecture checks**: Service boundaries, database patterns, API contracts
- **Example**: "This is Claude Sonnet (Backend Reviewer)"

### Database Reviewer
- **Focus**: Schema design, migrations, query patterns
- **Architecture checks**: Normalization, indexing, relationships
- **Example**: "This is GPT-4 (Database Reviewer)"

### Security Reviewer
- **Focus**: Authentication, authorization, data protection
- **Architecture checks**: Security patterns, input validation, audit trails
- **Example**: "This is Claude Opus (Security Reviewer)"

### DevEx Reviewer
- **Focus**: Developer experience, tooling, workflows
- **Architecture checks**: Build processes, testing strategies, documentation
- **Example**: "This is Claude Haiku (DevEx Reviewer)"

## Multi-Reviewer Workflow

For comprehensive reviews, use multiple specialized reviewers:

```bash
# Define reviewer roles
REVIEWERS=("frontend" "backend" "database")

for ROLE in "${REVIEWERS[@]}"; do
  echo "Running $ROLE review..."

  # Each role reviews all issues with their specific lens
  # Post comments with role identified in header

  # Example:
  # Frontend reviewer focuses on component structure, accessibility
  # Backend reviewer focuses on API design, data flow
  # Database reviewer focuses on schema, queries
done
```

## Review Criteria Templates

### Architecture Review Template

```markdown
**Architecture Review Checklist**

For each issue, verify:
- [ ] Follows documented architectural patterns
- [ ] Respects service/module boundaries
- [ ] Uses established data flow patterns
- [ ] Maintains API contract consistency
- [ ] Introduces dependencies appropriately
- [ ] Considers scalability implications
- [ ] Addresses security requirements
- [ ] Follows SOLID principles
- [ ] Maintains backward compatibility (if applicable)
```

### Wording Review Template

```markdown
**Wording Review Checklist**

For each issue, verify:
- [ ] User story is clear and testable
- [ ] Acceptance criteria are specific
- [ ] Technical terms are explained
- [ ] Requirements are unambiguous
- [ ] Title accurately reflects work
- [ ] Scope is well-defined
- [ ] Language is inclusive and professional
```

### Planning Review Template

```markdown
**Planning Review Checklist**

For each issue, verify:
- [ ] Acceptance criteria are complete
- [ ] Test plan covers key scenarios
- [ ] Edge cases are considered
- [ ] Change type is accurate
- [ ] Affected specs are identified
- [ ] Dependencies are documented
- [ ] Priority is justified
- [ ] Labels are appropriate
- [ ] Scope is reasonable
- [ ] Effort estimate is realistic (if provided)
```

## Example Review Comments

### Example 1: Architecture Suggestion

```markdown
**This is Claude Sonnet (Backend Reviewer)**

I've reviewed this issue and have some suggestions to consider:

## Architecture

The proposed approach looks solid overall. A few thoughts to consider:

- **Service boundary**: This feature touches both the curriculum and assessment domains. Consider whether the logic should live in a shared service or if we need a facade pattern to coordinate between them.
- **Reference**: See `docs/specs/shared-services/design.md` for our established patterns around cross-domain features.
- **Suggestion**: Consider adding a sequence diagram in the implementation checklist to clarify the interaction flow.

## Planning

The acceptance criteria are well-defined. Additionally, consider:

- Adding a criterion for error handling when the curriculum reference is invalid
- Specifying the expected behavior if assessment rules conflict with curriculum requirements

These are suggestions to consider - feel free to discuss or modify as you see fit!
```

### Example 2: Wording Improvement

```markdown
**This is GPT-4 (Technical Writer)**

I've reviewed this issue and have some suggestions to consider:

## Wording & Clarity

The user story could be more specific:

- **Current**: "As an educator, I want to manage courses"
- **Suggested**: "As an educator, I want to create, edit, and archive course structures so that I can organize learning content into logical units"

## Planning

The acceptance criteria are clear. One additional suggestion:

- Consider adding: "Archiving a course preserves its content but prevents new enrollments"

This helps clarify the expected behavior for the archive operation. Happy to clarify any points!
```

### Example 3: Multi-Concern Review

```markdown
**This is Claude Opus (Architect)**

I've reviewed this issue and have several suggestions to consider:

## Architecture

**Authentication flow**: The proposed changes introduce a new auth method. Consider:
- How this integrates with our existing JWT-based auth (docs/specs/authentication/design.md)
- Whether we need a strategy pattern for multiple auth methods
- Session management implications for the new flow

## Wording & Clarity

The user story is clear. Small suggestion for acceptance criteria:

- **Current**: "User can log in with new method"
- **Suggested**: "User can authenticate using [specific method name], receiving a valid JWT token with appropriate scopes"

## Planning

**Test plan enhancement**: Consider adding:
- Negative test: Invalid credentials handling
- Edge case: Concurrent authentication attempts
- Performance: Authentication latency under load

## Spec Changes

The proposed requirements are well-structured. One addition to consider:

```markdown
### Requirement: Token Expiration
The system SHALL issue tokens with a configurable expiration time.

#### Scenario: Token Expires
- **WHEN** a token's expiration time is reached
- **THEN** the system MUST reject requests using that token
- **AND** return a 401 Unauthorized status
```

## Additional Considerations

**Security**: Ensure the implementation includes:
- Rate limiting for auth attempts (reference: docs/specs/security/rate-limiting.md)
- Audit logging for authentication events
- Secure credential storage

---

These are suggestions to consider based on our architecture docs and security guidelines. Happy to discuss any of these points further!
```

## Integration with next-issue

When developers run `next-issue`, they should:

1. Read the full issue description
2. **Read all comments (especially review comments)**
3. Consider review suggestions during planning
4. Ask questions on unclear suggestions
5. Update specs or implementation approach if needed

Update to `next-issue` workflow (see step 6.5 below).

## Error Handling

### No Open Milestones

```
⚠ No open sprint milestones found

Possible actions:
  1. Check milestone state in GitHub
  2. Create new sprint milestone
  3. Run 'seed-sprint' to create sprint with milestone

Unable to proceed with sprint review.
```

### No Issues in Sprint

```
ℹ No open issues in sprint: S2 – Core Curriculum & Content Management

The sprint milestone exists but has no open issues.

Possible actions:
  1. Run 'seed-sprint' to create issues
  2. Check if issues were already completed
  3. Verify correct milestone selected
```

### Missing Architecture Docs

```
ℹ Note: No global architecture documentation found

Searched for:
  - docs/ARCHITECTURE.md
  - ARCHITECTURE.md
  - docs/architecture.md

Review will proceed but may miss architecture-specific concerns.

Consider:
  - Creating architecture documentation
  - Adding design.md to relevant specs
  - Documenting patterns in CLAUDE.md
```

### Spec Not Found

```
⚠ Warning: Spec reference not found
  Issue #201 references: docs/specs/curriculum-management/spec.md
  File does not exist

Cannot validate spec alignment. Consider:
  1. Running 'init-spec curriculum-management' first
  2. Updating issue to correct spec path
  3. Proceeding with review (architecture and wording only)
```

## Best Practices

### For Reviewers

- **Be specific**: Reference exact sections and provide concrete examples
- **Be kind**: Use collaborative language ("consider", "suggest")
- **Be balanced**: Acknowledge good aspects, not just issues
- **Be helpful**: Explain the "why" behind suggestions
- **Be relevant**: Focus on significant concerns, not nitpicks
- **Be consistent**: Use templates and checklists for thoroughness

### For Sprint Planning

- Run `review-sprint` immediately after `seed-sprint`
- Address critical architecture concerns before devs start
- Use reviews as learning opportunities for team
- Update issues if reviews reveal scope problems
- Consider reviewer suggestions but don't treat as requirements

### For Developers

- Read all review comments before starting implementation
- Ask clarifying questions on unclear suggestions
- Consider suggestions but use judgment
- Document decisions to deviate from suggestions
- Provide feedback on review quality to improve process

## Advanced: Automated Reviews

For automated review workflows:

```bash
#!/bin/bash
# review-sprint-automated.sh

# Configuration
MILESTONE_TITLE="$1"
REVIEWER_MODEL="Claude Sonnet"
REVIEWER_ROLE="Architect"

# Get issues
ISSUES=$(gh issue list --milestone "$MILESTONE_TITLE" --state open --json number,title --jq '.[].number')

# Review each issue
for ISSUE_NUM in $ISSUES; do
  echo "Reviewing issue #$ISSUE_NUM..."

  # Load context (issue, specs, architecture docs)
  # ... (implementation specific to your AI setup)

  # Generate review using AI
  # ... (call to Claude API, GPT API, etc.)

  # Post review comment
  gh issue comment $ISSUE_NUM --body "$REVIEW_COMMENT"

  # Rate limit pause
  sleep 2
done

echo "✓ All issues reviewed"
```

## Notes

- Reviews are suggestions, not requirements
- Developers have final decision on implementation approach
- Multiple reviewers can provide different perspectives
- Review comments should be respectful and collaborative
- Architecture docs should be kept updated for accurate reviews
- Review quality improves with clear architecture documentation
- Consider review feedback in retrospectives to improve quality
- Use review process to align team on standards and patterns
