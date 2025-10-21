# Init Spec Command

Create or update specification files before creating issues.

## Purpose

Establish or update specs in `docs/specs/` to serve as the source of truth for what is built. This is the foundation for spec-driven development.

## When to Use

- Creating a new capability or feature area
- Documenting existing functionality that lacks specs
- Major architectural changes requiring design documentation
- Before seeding a sprint with new capabilities

## Workflow

### 1. Check Existing Specs

```bash
# List existing capabilities
ls -la docs/specs/

# Search for related specs
rg "capability-name" docs/specs/
```

### 2. Determine Scope

Ask clarifying questions:
- Is this a new capability or modification of existing one?
- What requirements and scenarios need documentation?
- Does this need a design.md (architecture/patterns)?
- What's the single-focus purpose (can explain in 10 minutes)?

### 3. Create Capability Directory

```bash
# Choose kebab-case name (verb-noun preferred)
CAPABILITY="user-authentication"  # or "payment-processing", "data-export"

# Create directory structure
mkdir -p docs/specs/$CAPABILITY
```

### 4. Create spec.md

```bash
cat > docs/specs/$CAPABILITY/spec.md << 'EOF'
# [Capability Name]

## Overview

[1-2 sentence description of what this capability does]

## Requirements

### Requirement: [Requirement Name]

[Description using SHALL/MUST for normative requirements]

#### Scenario: [Scenario Name]

- **WHEN** [condition or action]
- **THEN** [expected result]
- **AND** [additional expectations, if any]

#### Scenario: [Another Scenario]

- **WHEN** [different condition]
- **THEN** [expected result]

### Requirement: [Another Requirement]

[Description]

#### Scenario: [Success Case]

- **WHEN** [condition]
- **THEN** [result]

#### Scenario: [Error Case]

- **WHEN** [error condition]
- **THEN** [error handling]

## API Contracts (if applicable)

### Endpoint: [Method] /api/path

**Request:**
```json
{
  "field": "value"
}
```

**Response:**
```json
{
  "result": "value"
}
```

## Data Models (if applicable)

### Model: [ModelName]

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | string | Yes | Unique identifier |
| name | string | Yes | Display name |

## Dependencies

- Depends on: [other-capability]
- Used by: [dependent-capability]

EOF
```

### 5. Create design.md (if needed)

Only create `design.md` if the capability involves:
- Cross-cutting changes (multiple services/modules)
- New architectural patterns
- External dependencies or significant data model changes
- Security, performance, or migration complexity
- Technical decisions that need documentation

```bash
cat > docs/specs/$CAPABILITY/design.md << 'EOF'
# [Capability Name] - Design

## Context

[Background information, constraints, stakeholders]

## Goals / Non-Goals

**Goals:**
- [What this design aims to achieve]
- [Key objectives]

**Non-Goals:**
- [What this explicitly does NOT cover]
- [Out of scope items]

## Technical Decisions

### Decision: [Decision Name]

**Choice:** [What was decided]

**Rationale:** [Why this was chosen]

**Alternatives Considered:**
- [Option 1] - [Why rejected]
- [Option 2] - [Why rejected]

### Decision: [Another Decision]

[Same structure]

## Architecture

[Diagrams, component descriptions, data flow]

## Implementation Patterns

[Code patterns, conventions, examples]

## Risks / Trade-offs

- **Risk:** [Potential issue]
  - **Mitigation:** [How to address]

## Migration Plan (if applicable)

**Steps:**
1. [Migration step]
2. [Migration step]

**Rollback:**
- [How to undo changes if needed]

## Open Questions

- [Unresolved question 1]
- [Unresolved question 2]

EOF
```

### 6. Validate Spec Structure

Check that spec.md includes:
- [ ] Clear overview
- [ ] At least one requirement
- [ ] Each requirement has at least one scenario
- [ ] Scenarios use proper format: `#### Scenario: Name`
- [ ] Scenarios use WHEN/THEN structure
- [ ] Requirements use SHALL/MUST language

### 7. Review with Stakeholders

Before committing:
1. Review spec completeness
2. Validate scenarios cover happy path and error cases
3. Confirm dependencies are documented
4. Ensure design decisions are captured (if design.md exists)

### 8. Commit Spec Files

```bash
# Create spec branch
git checkout -b spec/$CAPABILITY

# Add files
git add docs/specs/$CAPABILITY/

# Commit with descriptive message
git commit -m "spec: add $CAPABILITY capability

- Add spec.md with requirements and scenarios
- Add design.md with architectural decisions
- Document API contracts and data models"

# Push for review
git push -u origin spec/$CAPABILITY
```

### 9. Create PR for Spec Review

```bash
# Create PR for spec review
gh pr create \
  --title "spec: Add $CAPABILITY capability" \
  --body "## Purpose

Documenting the $CAPABILITY capability before implementation.

## Contents

- \`spec.md\`: Requirements and scenarios
- \`design.md\`: Architectural decisions

## Next Steps

After approval, this spec will be used to create implementation issues.

## Checklist

- [ ] Overview clearly explains capability
- [ ] All requirements have scenarios
- [ ] Dependencies documented
- [ ] API contracts defined (if applicable)
- [ ] Design decisions captured (if applicable)" \
  --label "type:spec,area:documentation"

# Get PR URL
gh pr view --web
```

### 10. Update Project Documentation

After spec PR is merged, update:

**docs/prd.md:**
- Add capability to product roadmap
- Link to spec file

**docs/project-brief.md:**
- Update if this represents new strategic direction
- Add to capability list

## Spec Naming Conventions

**Good names** (single-focus, verb-noun):
- `user-authentication`
- `payment-processing`
- `data-export`
- `notification-delivery`
- `content-moderation`

**Avoid** (too broad or vague):
- `users` (what about users?)
- `backend` (not specific)
- `features` (not focused)
- `api` (too general)

## Requirement Writing Guidelines

**Good requirement:**
```markdown
### Requirement: Email Validation

The system SHALL validate email addresses before account creation.

#### Scenario: Valid Email

- **WHEN** user provides "user@example.com"
- **THEN** validation passes
- **AND** account creation proceeds

#### Scenario: Invalid Email

- **WHEN** user provides "invalid-email"
- **THEN** validation fails
- **AND** error message displays
```

**Poor requirement:**
```markdown
### Requirement: Emails

The system should handle emails properly.

- Users can enter emails
- Emails are checked
```

## Common Pitfalls

1. **Too broad**: Capability covers multiple unrelated concerns
   - **Fix**: Split into separate capabilities

2. **Missing scenarios**: Requirements without concrete examples
   - **Fix**: Add at least one scenario per requirement

3. **Vague language**: "Should", "might", "could"
   - **Fix**: Use SHALL/MUST for requirements

4. **No dependencies**: Spec exists in isolation
   - **Fix**: Document relationships with other capabilities

5. **Skipping design.md**: Complex changes without architectural documentation
   - **Fix**: Create design.md when needed (see criteria above)

## Examples

### Example 1: Simple Capability (spec.md only)

**Capability**: `email-validation`

**Files**: `spec.md` only (no design.md needed - straightforward)

### Example 2: Complex Capability (both files)

**Capability**: `payment-processing`

**Files**:
- `spec.md` - Requirements and scenarios
- `design.md` - PCI compliance, external API integration, state machine

### Example 3: Multi-Spec Change

When a feature affects multiple capabilities:
- Update each affected spec separately
- Document dependencies between them
- Consider if this should be a new capability instead

## Notes

- Specs are living documents - update as system evolves
- Small, focused capabilities are better than large, monolithic ones
- Every requirement must have testable scenarios
- Design.md is optional but valuable for complex changes
- Specs should be reviewed before creating implementation issues
