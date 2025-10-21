---
name: git-workflow
description: Use this skill for spec-driven git workflow with GitHub issues. Provides 10 workflow commands including brownfield project migration, sprint management, AI quality reviews, issue tracking, and PR workflows. Triggers include migrating existing projects, creating sprint issues, reviewing sprint quality, starting work on issues, testing implementations, submitting PRs, handling review feedback, closing completed work, checking sprint progress, or creating/updating specs. Use when the user mentions migration, sprints, reviews, issues, PRs, specs, or wants to track development workflow.
---

# Git Workflow

Spec-driven development workflow using GitHub issues, pull requests, and specifications.

## Overview

This skill implements a comprehensive spec-driven development workflow that integrates specifications, GitHub issues, and pull requests. It provides 10 workflow commands covering brownfield migration, spec creation, sprint management, quality reviews, and the complete development lifecycle through issue closure.

**Key Principles:**
- **Spec-First**: Specifications in `docs/specs/` are the source of truth
- **Issue-Driven**: GitHub issues track proposed changes
- **PR-Tracked**: Pull requests implement and update specs
- **Sprint-Organized**: Work is organized into sprint milestones

## When to Use This Skill

Use this skill when:
- Migrating existing brownfield projects to spec-driven workflow
- Creating sprint issues from planning documents
- Reviewing sprint issues for quality and architecture compliance
- Starting work on assigned issues
- Testing implementation before submission
- Creating pull requests with spec deltas
- Handling review feedback and updates
- Closing completed issues after merge
- Checking sprint progress and analytics
- Creating or updating specification files

## Directory Structure

This workflow assumes the following project structure:

```
project/
├── docs/
│   ├── project-brief.md      # High-level vision, goals
│   ├── prd.md                # Product requirements
│   ├── specs/                # Source of truth - what IS built
│   │   └── [capability]/
│   │       ├── spec.md       # Requirements and scenarios
│   │       └── design.md     # Architecture (optional)
│   └── sprint/               # What SHOULD be built (proposals)
│       ├── S0.md            # Sprint files
│       ├── S1.md
│       └── epics/
│           └── E1.md
├── TODO.md                   # Project tracking
└── [source code]
```

## Workflow Commands

This skill provides 10 commands that form a complete development lifecycle:

### 0. migrate-project (Brownfield Migration)
**Purpose**: Migrate existing project to spec-driven workflow

**When to use**:
- Adopting workflow in existing project
- Organizing scattered documentation
- Onboarding AI assistants to project structure
- Starting fresh after initial development

**Key actions**:
- Discover existing documentation
- Create directory structure
- Migrate and organize docs
- Create CLAUDE.md/AGENTS.md
- Generate GitHub templates
- Create migration report with next steps

**Details**: See `references/migrate-project.md`

---

### 1. init-spec
**Purpose**: Create or update specification files before creating issues

**When to use**:
- Creating a new capability
- Documenting existing functionality
- Major architectural changes

**Key actions**:
- Create `docs/specs/[capability]/spec.md`
- Optionally create `design.md`
- Validate spec structure
- Create spec PR for review

**Details**: See `references/init-spec.md`

---

### 2. seed-sprint
**Purpose**: Create GitHub issues from sprint markdown files

**When to use**:
- Starting a new sprint
- Converting planned stories to tracked issues
- Creating milestone-based work packages

**Key actions**:
- Read sprint file (e.g., `docs/sprint/S2.md`)
- Validate referenced specs exist
- Create issues with spec references
- Update TODO.md and sprint file

**Details**: See `references/seed-sprint.md`

---

### 2.5. review-sprint
**Purpose**: AI-powered quality review of sprint issues for architecture, wording, and planning

**When to use**:
- After running seed-sprint
- Before developers start work with next-issue
- When sprint planning needs quality validation
- To ensure architectural consistency

**Key actions**:
- Review all open issues in sprint milestone
- Check architecture compliance against docs
- Validate wording clarity and planning quality
- Suggest improvements as respectful comments
- Post review comments on each issue

**Details**: See `references/review-sprint.md`

---

### 3. next-issue
**Purpose**: Select and start work on next available issue

**When to use**:
- Starting work on a new issue
- Switching between issues
- Beginning a work session

**Key actions**:
- Verify clean working state
- Get assigned issues with priorities
- Check for spec conflicts
- Read affected specs
- **Read all issue comments (including review suggestions)**
- Create feature branch
- Update TODO.md and sprint file

**Details**: See `references/next-issue.md`

---

### 4. test-issue
**Purpose**: Run comprehensive testing before submission

**When to use**:
- After completing implementation
- Before creating a pull request
- When PR has test failures

**Key actions**:
- Run linting
- Run unit tests
- Run integration tests
- Run e2e tests
- Run type checking and build
- Update TODO.md with test results

**Details**: See `references/test-issue.md`

---

### 5. submit-issue
**Purpose**: Create pull request with spec deltas

**When to use**:
- After implementation complete
- All tests passing
- Ready for code review

**Key actions**:
- Verify spec updates
- Commit changes with conventional format
- Push branch to remote
- Create PR with spec deltas
- Enable auto-merge
- Request reviewers
- Update TODO.md and sprint file

**Details**: See `references/submit-issue.md`

---

### 6. update-issue
**Purpose**: Handle review feedback and PR updates

**When to use**:
- After receiving review comments
- When CI/CD checks fail
- Spec clarifications needed
- Additional implementation required

**Key actions**:
- Get PR status and review comments
- Address feedback
- Update specs if needed
- Commit and push changes
- Re-request review
- Update tracking files

**Details**: See `references/update-issue.md`

---

### 7. close-issue
**Purpose**: Clean up after PR merge

**When to use**:
- After PR is merged
- Completing issue lifecycle
- Cleaning up feature branches

**Key actions**:
- Verify PR merged
- Switch to main and pull
- Delete feature branches
- Close GitHub issue
- Update TODO.md and sprint file
- Update docs/prd.md if major capability

**Details**: See `references/close-issue.md`

---

### 8. sprint-status
**Purpose**: Provide sprint progress and analytics

**When to use**:
- Daily standup preparation
- Sprint planning meetings
- Progress check-ins
- Identifying blockers

**Key actions**:
- Calculate progress percentage
- Analyze by priority
- Identify blocked issues
- Calculate velocity
- Generate burndown data
- Assess risks
- Provide recommendations

**Details**: See `references/sprint-status.md`

---

## Workflow Lifecycle

### Brownfield Project (First Time Setup)

```
0. migrate-project → Migrate existing project to spec-driven workflow
   - Discover documentation
   - Create structure
   - Generate CLAUDE.md
   - Create migration report
```

### Greenfield or Post-Migration

A typical issue follows this lifecycle:

```
1. init-spec      → Create spec for new capability
2. seed-sprint    → Create issue from sprint file
2.5. review-sprint → AI review issues for quality (NEW)
3. next-issue     → Start work on issue (read review comments)
4. test-issue     → Validate implementation
5. submit-issue   → Create pull request
6. update-issue   → Address review feedback (if needed)
7. close-issue    → Clean up after merge
8. sprint-status  → Track overall progress
```

## Spec-Driven Development

### Spec Files (`docs/specs/[capability]/spec.md`)

Each spec file defines a single capability:

```markdown
# Capability Name

## Overview
[1-2 sentence description]

## Requirements

### Requirement: Requirement Name
[SHALL/MUST statement]

#### Scenario: Scenario Name
- **WHEN** [condition]
- **THEN** [expected result]

## API Contracts (if applicable)
## Data Models (if applicable)
## Dependencies
```

### Design Files (`docs/specs/[capability]/design.md`)

Optional design documentation for complex capabilities:

```markdown
# Capability Name - Design

## Context
## Goals / Non-Goals
## Technical Decisions
## Architecture
## Risks / Trade-offs
## Migration Plan
## Open Questions
```

### Sprint Files (`docs/sprint/SN.md`)

Sprint planning documents that become issues:

```markdown
# Sprint S2 – Sprint Title

## Story Title

**User Story**: As a [role], I want [feature] so that [benefit]

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] Criterion 2

**Test Plan**:
- Test scenario 1

**Labels**: type:feature,area:backend,priority:P1
**Affected Specs**: docs/specs/capability-name/spec.md
**Change Type**: ADDED
**Agent Assignment**: dev (Name)
```

## GitHub Issue Format

Issues created by `seed-sprint` include:

```markdown
## User Story
[Story description]

## Affected Specs
- docs/specs/capability/spec.md

## Change Type
- [x] ADDED Requirements (new capability)
- [ ] MODIFIED Requirements
- [ ] REMOVED Requirements

## Proposed Spec Changes
### ADDED Requirements
[Spec deltas]

## Acceptance Criteria
[Criteria list]

## Test Plan
[Testing approach]

## Implementation Checklist
- [ ] Spec updated in docs/specs/
- [ ] Tests written and passing
- [ ] Code implemented
- [ ] PR created and reviewed
```

## Pull Request Format

PRs created by `submit-issue` include:

```markdown
## Summary
Implements: [Issue title]

## Spec Changes
Updated: `docs/specs/capability/spec.md`
Change Type: **ADDED** Requirements

### Spec Deltas
[Detailed spec changes]

## Implementation Details
[Commit list]

## Testing
- [x] Unit tests passing
- [x] Integration tests passing
- [x] E2E tests passing

## Checklist
- [x] Implementation complete
- [x] Tests passing
- [x] Specs updated in docs/specs/
- [x] Acceptance criteria met

Closes #[issue-number]
```

## Label Conventions

**Type labels:**
- `type:feature` - New features
- `type:bug` - Bug fixes
- `type:chore` - Maintenance
- `type:spec` - Spec-only updates

**Area labels:**
- `area:frontend` - UI/UX changes
- `area:backend` - Server/API changes
- `area:devex` - Developer experience

**Priority labels:**
- `priority:P0` - Critical
- `priority:P1` - High priority
- `priority:P2` - Medium priority
- `priority:P3` - Low priority

**Spec labels:**
- `add-capability` - New capability spec
- `modify-spec` - Changes existing spec
- `remove-feature` - Deprecation

**Status labels:**
- `blocked` - Cannot proceed
- `in-progress` - Actively being worked on

## Commit Message Format

Use Conventional Commits:

```
<type>: <description>

[optional body]

Closes #<issue-number>
```

**Types**: feat, fix, chore, docs, test, refactor, perf, style

**Example:**
```
feat: add two-factor authentication

Implements OTP-based 2FA for user accounts.
Includes email delivery and validation.

Closes #123
```

## Change Types

### ADDED
- Introduces entirely new capability
- New spec file will be created
- Example: "Add two-factor authentication"

### MODIFIED
- Changes existing functionality
- Modifies existing spec requirements
- Example: "Update login to support OAuth"

### REMOVED
- Deprecates features
- Removes requirements from spec
- Example: "Remove legacy password reset"

## Best Practices

### Spec Management
- Keep specs focused (single capability per spec)
- Every requirement must have scenarios
- Use SHALL/MUST for requirements
- Update specs before implementation
- Review specs before seeding sprints

### Issue Management
- Reference affected specs in all issues
- Mark change type (ADDED/MODIFIED/REMOVED)
- Include acceptance criteria
- Document dependencies
- Use consistent labels

### Branch Management
- Branch format: `feat/123-description`
- Keep branches short-lived
- Delete after merge
- Stay synced with main

### PR Management
- Include spec deltas in PR body
- Enable auto-merge for efficiency
- Request appropriate reviewers
- Address feedback promptly
- Keep PRs focused

### Testing
- Test locally before pushing
- Run full test suite
- Fix all linting errors
- Meet coverage requirements
- Test edge cases

### Tracking
- Update TODO.md and sprint files
- Track progress regularly
- Identify blockers early
- Monitor velocity
- Communicate risks

## Common Workflows

### Migrating Existing Project (First Time)

```
1. Backup: Commit current state
2. Run: migrate-project
3. Review: MIGRATION-REPORT.md
4. Create: Standard GitHub labels
5. Create: First 2-3 critical specs (init-spec)
6. Create: First sprint file (docs/sprint/S1.md)
7. Run: seed-sprint
8. Onboard: Share CLAUDE.md with team
```

### Starting a New Sprint

```
1. Create sprint file: docs/sprint/S2.md
2. Run: init-spec (for new capabilities)
3. Run: seed-sprint
4. Run: review-sprint (AI quality review)
5. Verify: Sprint issues created and reviewed in GitHub
```

### Daily Development

```
1. Run: next-issue
2. Implement according to specs
3. Run: test-issue
4. Run: submit-issue
5. Wait for review
6. If feedback: Run update-issue
7. After merge: Run close-issue
```

### Sprint Monitoring

```
1. Run: sprint-status
2. Review progress and blockers
3. Adjust priorities if needed
4. Communicate risks
```

### Adding New Capability

```
1. Run: init-spec [capability-name]
2. Write spec.md with requirements
3. Create design.md if complex
4. Create spec PR for review
5. After approval: Add to sprint file
6. Run: seed-sprint
```

## Troubleshooting

### Spec Not Found
```
Issue references spec that doesn't exist.

Solution:
1. Run: init-spec [capability-name]
2. Create spec.md
3. Re-run workflow command
```

### Tests Failing
```
Cannot submit PR with failing tests.

Solution:
1. Review test output
2. Fix issues
3. Run: test-issue again
4. Only proceed when all pass
```

### PR Not Merged
```
Cannot close issue before PR merges.

Solution:
1. Check PR status: gh pr view
2. Address review feedback
3. Wait for merge
4. Run: close-issue after merge
```

### Blocked Issues
```
Issue cannot proceed due to dependencies.

Solution:
1. Identify blocking issue
2. Prioritize blocker
3. Or select different issue
4. Run: next-issue for alternative
```

## Resources

All workflow commands have detailed reference documentation in the `references/` directory:

- `migrate-project.md` - **Brownfield migration** (first-time setup)
- `init-spec.md` - Creating specification files
- `seed-sprint.md` - Creating sprint issues
- `review-sprint.md` - **AI quality review** of sprint issues (NEW)
- `next-issue.md` - Starting work on issues
- `test-issue.md` - Testing implementation
- `submit-issue.md` - Creating pull requests
- `update-issue.md` - Handling review feedback
- `close-issue.md` - Closing completed issues
- `sprint-status.md` - Sprint progress analytics

Refer to these files for complete workflows, examples, and troubleshooting.

## Integration with Tools

This workflow integrates with:
- **GitHub CLI (`gh`)**: Issue and PR management
- **Git**: Branch and commit management
- **npm**: Testing and linting
- **TODO.md**: Project tracking
- **Sprint files**: Planning and documentation

Ensure GitHub CLI is authenticated:
```bash
gh auth status
gh auth login  # if not authenticated
```

## Quick Reference

```bash
# Workflow Commands (conceptual - implement as needed)
migrate-project            # Migrate brownfield project (first time)
init-spec [capability]     # Create spec files
seed-sprint [sprint-file]  # Create sprint issues
review-sprint              # AI review sprint issues (NEW)
next-issue                 # Start next issue (read reviews)
test-issue                 # Run tests
submit-issue               # Create PR
update-issue               # Update PR
close-issue                # Clean up after merge
sprint-status              # Show progress

# Common Git Commands
git switch -c feat/123-description  # Create branch
git add .                           # Stage changes
git commit -m "feat: description"   # Commit
git push origin branch-name         # Push

# Common GitHub CLI Commands
gh issue list --assignee @me       # My issues
gh pr create                       # Create PR
gh pr view                         # View PR details
gh pr merge --auto --squash        # Enable auto-merge
```

## Notes

- This is a guided workflow skill - commands are procedural guides, not automated scripts
- Always run commands in order for best results
- Update tracking files (TODO.md, sprint files) after each step
- Keep specs synchronized with implementation
- Communicate progress and blockers early
- Use sprint-status for visibility and decision-making
