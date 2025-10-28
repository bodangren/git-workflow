# Git Workflow - Spec-Driven Development Skill

A comprehensive Claude Code skill for spec-driven development using GitHub issues, pull requests, and sprint management with continuous improvement.

## Overview

Transform your development workflow with a structured, specification-driven approach that integrates seamlessly with GitHub. This skill provides 12 workflow commands covering everything from brownfield project migration to sprint analytics, with built-in continuous improvement through retrospectives.

**Key Features:**
- 🔄 **Brownfield Migration** - Migrate existing projects to spec-driven workflow
- 📝 **Spec-First Development** - Specifications as source of truth
- 🎯 **Issue-Driven** - GitHub issues track all proposed changes
- 🔀 **PR-Tracked** - Pull requests implement and update specs
- 📊 **Sprint-Organized** - Work organized into sprint milestones
- 🔍 **AI Quality Review** - Automated issue review for architecture compliance
- 🚫 **Blocking Support** - Handle external dependencies gracefully
- ✂️ **Issue Splitting** - Keep work scoped for single chat sessions
- 🔄 **Continuous Improvement** - Living retrospective feeds learnings into future work

## Installation

### From Claude Code Marketplace

```bash
# Install via Claude Code CLI
claude-code plugin install git-workflow
```

### From GitHub

```bash
# Clone or download this repository
git clone https://github.com/daniel-bo/git-workflow.git

# Install locally
cd git-workflow
claude-code plugin install .
```

## Quick Start

### For New Projects (Greenfield)

```bash
# 1. Create initial specs
# Use the git-workflow skill and run: init-spec [capability]

# 2. Create first sprint file
# Create: docs/sprint/S1.md with your stories

# 3. Generate issues from sprint
# Run: seed-sprint

# 4. Start development
# Run: next-issue
```

### For Existing Projects (Brownfield)

```bash
# 1. Backup your current state
git commit -am "Pre-migration backup"

# 2. Run migration
# Use the git-workflow skill and run: migrate-project

# 3. Review migration report
cat MIGRATION-REPORT.md

# 4. Create standard labels
# Follow instructions in migration report

# 5. Create initial specs
# Run: init-spec [capability] for each identified capability

# 6. Start fresh sprint
# Create docs/sprint/S1.md and run: seed-sprint
```

## Workflow Commands

The skill provides 12 comprehensive workflow commands:

### 0. migrate-project
**Migrate existing brownfield projects to spec-driven workflow**

- Discovers existing documentation
- Creates proper directory structure
- Generates CLAUDE.md team guide
- Creates GitHub templates
- Provides migration report with next steps

### 1. init-spec
**Create or update specification files**

- Creates `docs/specs/[capability]/spec.md`
- Optionally creates `design.md` for complex changes
- Validates spec structure
- Creates spec PR for review

### 2. seed-sprint
**Create GitHub issues from sprint markdown files**

- Reads sprint file (e.g., `docs/sprint/S2.md`)
- Validates referenced specs exist
- Creates issues with spec references
- Updates TODO.md and sprint file

### 2.5. review-sprint
**AI-powered quality review of sprint issues**

- Reviews all issues in current sprint
- Checks architecture compliance
- Validates wording and clarity
- Suggests planning improvements
- Posts constructive review comments

### 3. next-issue
**Select and start work on next available issue**

- Verifies clean working state
- Recommends issues by priority
- Checks for spec conflicts
- **Reads development retrospective (learnings from past issues)**
- Reads all issue comments (including review suggestions)
- Creates feature branch
- Updates tracking files

### 3.5. block-issue
**Mark issue as blocked when dependencies prevent progress**

- Adds blocked label to issue
- Documents blocker with expected resolution
- Updates TODO.md and sprint tracking
- Pauses work cleanly (commits WIP)
- Notifies PM of blocker

### 3.6. split-issue
**Break large issues into smaller, atomic issues**

- Analyzes issue scope (~200K token limit per chat)
- Identifies split strategy (backend/frontend, phases, etc.)
- Creates parent/child or sequential issues
- Links relationships and dependencies
- Maintains manageable scope per issue

### 4. test-issue
**Run comprehensive testing before submission**

- Runs linting, unit, integration, e2e tests
- Validates type checking and builds
- Reports test coverage
- Updates tracking with test status

### 5. submit-issue
**Create pull request with spec deltas**

- Verifies spec updates
- Creates PR with conventional commits
- Includes spec deltas in PR body
- Enables auto-merge
- Requests appropriate reviewers

### 6. update-issue
**Handle review feedback and PR updates**

- Addresses review comments
- Updates specs if needed
- Re-runs tests
- Re-requests review
- Tracks update history

### 7. close-issue
**Clean up after PR merge and capture learnings**

- Verifies PR merged
- Deletes feature branches
- Closes GitHub issue
- Updates all tracking files
- **Updates RETROSPECTIVE.md with learnings**
- Calculates sprint progress

### 8. sprint-status
**Provide sprint progress and analytics**

- Calculates completion percentage
- Analyzes by priority
- Identifies blocked issues
- Calculates velocity
- Generates burndown data
- Assesses risks and provides recommendations

## Directory Structure

This skill creates and uses the following structure:

```
project/
├── docs/
│   ├── project-brief.md      # Vision and goals
│   ├── prd.md                # Product requirements
│   ├── specs/                # Technical specifications (source of truth)
│   │   └── [capability]/
│   │       ├── spec.md       # Requirements and scenarios
│   │       └── design.md     # Architecture (optional)
│   ├── sprint/               # Sprint planning
│   │   ├── S1.md            # Sprint files
│   │   └── S2.md
│   ├── epics/                # Epic tracking (optional)
│   │   └── E1-epic-name.md
│   └── releases/             # Release planning (optional)
│       └── v1.0.md
├── TODO.md                   # Project tracking
├── RETROSPECTIVE.md          # Living retrospective (~100 lines)
├── CLAUDE.md                 # Workflow guide (created by migrate-project)
├── .github/
│   ├── ISSUE_TEMPLATE/       # Issue templates (created by migrate-project)
│   └── pull_request_template.md
└── [source code]
```

## Spec Format

Specifications follow this structure:

```markdown
# Capability Name

## Overview
[1-2 sentence description]

## Requirements

### Requirement: Requirement Name
The system SHALL [normative statement using SHALL/MUST]

#### Scenario: Success Case
- **WHEN** [condition or action]
- **THEN** [expected result]

#### Scenario: Error Case
- **WHEN** [error condition]
- **THEN** [error handling]

## API Contracts (optional)
## Data Models (optional)
## Dependencies
```

## GitHub Conventions

### Labels

The workflow uses standardized labels:

**Type**: `type:feature`, `type:bug`, `type:chore`, `type:spec`, `type:test`, `type:spike`
**Priority**: `priority:P0` (critical) through `priority:P3` (low)
**Spec**: `add-capability`, `modify-spec`, `remove-feature`
**Status**: `blocked`, `in-progress`, `parent-issue`
**Area**: `area:frontend`, `area:backend`, `area:devex`, `area:testing`

### Commit Messages

Uses Conventional Commits:

```
<type>: <description>

[optional body]

Closes #<issue-number>
```

**Types**: feat, fix, chore, docs, test, refactor, perf, style

### Branch Names

Format: `<type>/<issue>-<description>`

Examples:
- `feat/123-add-2fa`
- `fix/456-login-timeout`
- `chore/789-update-deps`

## Workflow Lifecycle

### Complete Development Cycle

```
1. migrate-project (if brownfield) → Setup structure
2. init-spec                       → Create capability spec
3. seed-sprint                     → Create issues from sprint
3.5. review-sprint                 → AI review issues for quality
4. next-issue                      → Start work (reads retrospective)
   4.5. block-issue (optional)     → Mark blocked if dependencies
   4.6. split-issue (optional)     → Split if too large (~200K tokens)
5. [implement according to spec]
6. test-issue                      → Validate quality
7. submit-issue                    → Create PR
8. update-issue (if needed)        → Address feedback
9. close-issue                     → Complete after merge (updates retrospective)
   └─→ Learnings feed back into next-issue ← FEEDBACK LOOP
10. sprint-status                  → Track progress
```

## Continuous Improvement

### Development Retrospective

The skill maintains a living **RETROSPECTIVE.md** file (~100 lines) that captures learnings from each issue:

**Structure:**
- **Recent Issues** (50%): Detailed learnings from last 3-5 issues
- **Historical Patterns** (40%): Compressed wisdom from earlier issues
- **Spec Quality Trends** (10%): Which specs are good references vs need work

**Feedback Loop:**
- `close-issue` adds new learnings and compresses old entries
- `next-issue` reads retrospective to apply proven patterns and avoid past mistakes

**Example Entry:**
```markdown
### #201 - Curriculum Framework (2025-10-22, 2 days, 1 PR update)
**Went well**: Spec was complete with clear scenarios
**Friction**: Missed error handling in initial spec
**Applied**: Added error scenarios after PR feedback
**Lesson**: Always include error scenarios in spec.md from the start
```

This creates a **self-improving system** where each issue benefits from the accumulated wisdom of previous work.

## Best Practices

### Spec Management
- Keep specs focused (single capability per spec)
- Every requirement must have scenarios
- Use SHALL/MUST for normative requirements
- Update specs before implementation
- Track spec debt in TODO.md

### Issue Management
- Reference affected specs in all issues
- Mark change type (ADDED/MODIFIED/REMOVED)
- Include acceptance criteria
- Document dependencies
- **Keep issues sized for single chat (~150-200K tokens)**
- **Block issues immediately when dependencies arise**
- **Split large issues proactively during planning**

### Testing
- Test locally before pushing
- Run full test suite
- Fix all linting errors
- Meet coverage requirements

### Tracking
- Update TODO.md and sprint files
- Track progress regularly
- Identify blockers early
- Monitor velocity
- **Review retrospective before starting each issue**

## Examples

### Creating a New Feature

```bash
# 1. Create spec (if new capability)
# Run: init-spec user-authentication

# 2. Add to sprint file
# Edit: docs/sprint/S2.md, add user authentication story

# 3. Create issues
# Run: seed-sprint

# 4. Start work
# Run: next-issue
# Select #201 - User Authentication

# 5. Implement
# ... write code according to spec ...

# 6. Test
# Run: test-issue

# 7. Submit
# Run: submit-issue

# 8. After review/merge
# Run: close-issue
```

### Checking Sprint Status

```bash
# Run: sprint-status

# Output:
# Sprint S2: 60% complete
# Velocity: 0.75 issues/day
# Projected completion: On track
# Blockers: None
```

## Configuration

### Team Guidance

After migration or initial setup, customize `CLAUDE.md` for your team:

```markdown
# Claude Code Workflow Guide

## Overview
[Your project-specific overview]

## Workflow Commands
[8 commands available via git-workflow skill]

## Development Workflow
[Your team's specific processes]

## Spec Format
[Your spec conventions]
```

### GitHub Setup

Create standard labels using the migration report or manually:

```bash
# Type labels
gh label create "type:feature" --description "New feature" --color "0e8a16"
gh label create "type:bug" --description "Bug fix" --color "d73a4a"

# Priority labels
gh label create "priority:P0" --description "Critical" --color "b60205"
gh label create "priority:P1" --description "High" --color "d93f0b"

# ... (see migration report for complete list)
```

## Troubleshooting

### Common Issues

**Spec Not Found**
```
Issue references spec that doesn't exist.
Solution: Run init-spec [capability-name]
```

**Tests Failing**
```
Cannot submit PR with failing tests.
Solution: Fix issues, run test-issue again
```

**PR Not Merged**
```
Cannot close issue before PR merges.
Solution: Wait for merge, then run close-issue
```

## Documentation

Detailed documentation for each workflow command is available in:

- `skills/git-workflow/SKILL.md` - Complete skill overview
- `skills/git-workflow/references/` - Individual command guides
  - `migrate-project.md` - Brownfield migration
  - `init-spec.md` - Spec creation
  - `seed-sprint.md` - Sprint seeding
  - `review-sprint.md` - AI quality review
  - `next-issue.md` - Issue selection (includes retrospective reading)
  - `block-issue.md` - Blocking issues
  - `split-issue.md` - Splitting large issues
  - `test-issue.md` - Testing
  - `submit-issue.md` - PR creation
  - `update-issue.md` - Review handling
  - `close-issue.md` - Completion (includes retrospective update)
  - `sprint-status.md` - Analytics
- `skills/git-workflow/examples/` - Templates
  - `epic-template.md` - Epic tracking template
  - `release-template.md` - Release planning template

## Requirements

- **Claude Code**: Version 0.1.0 or higher
- **GitHub CLI** (`gh`): For issue and PR management
- **Git**: For version control
- **Node.js** (optional): For npm-based testing

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow the spec-driven workflow (dogfooding!)
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/daniel-bo/git-workflow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/daniel-bo/git-workflow/discussions)
- **Documentation**: See `skills/git-workflow/` directory

## Changelog

### Version 1.1.0 (2025-10-28)

- **Continuous Improvement**: Living RETROSPECTIVE.md with feedback loop
- **New Commands**: block-issue, split-issue, review-sprint
- **Enhanced next-issue**: Reads retrospective before starting work
- **Enhanced close-issue**: Captures learnings for future issues
- **Issue Management**: Better support for dependencies and scope control
- **Templates**: Added epic and release planning templates
- 12 workflow commands total

### Version 1.0.0 (2025-10-21)

- Initial release
- 9 workflow commands
- Brownfield migration support
- Comprehensive spec-driven development workflow
- Sprint management and analytics
- GitHub integration
- Team onboarding materials

---

**Built with ❤️ for spec-driven development**
