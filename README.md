# Git Workflow - Spec-Driven Development Plugin

A comprehensive Claude Code plugin for spec-driven development using GitHub issues, pull requests, and sprint management.

## Overview

Transform your development workflow with a structured, specification-driven approach that integrates seamlessly with GitHub. This plugin provides 9 workflow commands covering everything from brownfield project migration to sprint analytics.

**Key Features:**
- 🔄 **Brownfield Migration** - Migrate existing projects to spec-driven workflow
- 📝 **Spec-First Development** - Specifications as source of truth
- 🎯 **Issue-Driven** - GitHub issues track all proposed changes
- 🔀 **PR-Tracked** - Pull requests implement and update specs
- 📊 **Sprint-Organized** - Work organized into sprint milestones
- 📈 **Analytics** - Velocity tracking and burndown metrics

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

The plugin provides 9 comprehensive workflow commands:

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

### 3. next-issue
**Select and start work on next available issue**

- Verifies clean working state
- Recommends issues by priority
- Checks for spec conflicts
- Creates feature branch
- Updates tracking files

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
**Clean up after PR merge**

- Verifies PR merged
- Deletes feature branches
- Closes GitHub issue
- Updates all tracking files
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

This plugin creates and uses the following structure:

```
project/
├── docs/
│   ├── project-brief.md      # Vision and goals
│   ├── prd.md                # Product requirements
│   ├── specs/                # Technical specifications (source of truth)
│   │   └── [capability]/
│   │       ├── spec.md       # Requirements and scenarios
│   │       └── design.md     # Architecture (optional)
│   └── sprint/               # Sprint planning
│       ├── S1.md            # Sprint files
│       ├── S2.md
│       └── epics/
│           └── E1.md
├── TODO.md                   # Project tracking
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

**Type**: `type:feature`, `type:bug`, `type:chore`, `type:spec`
**Priority**: `priority:P0` (critical) through `priority:P3` (low)
**Spec**: `add-capability`, `modify-spec`, `remove-feature`
**Status**: `blocked`, `in-progress`
**Area**: `area:frontend`, `area:backend`, `area:devex`

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
4. next-issue                      → Start work
5. [implement according to spec]
6. test-issue                      → Validate quality
7. submit-issue                    → Create PR
8. update-issue (if needed)        → Address feedback
9. close-issue                     → Complete after merge
10. sprint-status                  → Track progress
```

## Best Practices

### Spec Management
- Keep specs focused (single capability per spec)
- Every requirement must have scenarios
- Use SHALL/MUST for normative requirements
- Update specs before implementation

### Issue Management
- Reference affected specs in all issues
- Mark change type (ADDED/MODIFIED/REMOVED)
- Include acceptance criteria
- Document dependencies

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
  - `next-issue.md` - Issue selection
  - `test-issue.md` - Testing
  - `submit-issue.md` - PR creation
  - `update-issue.md` - Review handling
  - `close-issue.md` - Completion
  - `sprint-status.md` - Analytics

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
