# Migrate Project Command

Migrate an existing brownfield project to the spec-driven git workflow.

## Purpose

Transform an existing project with scattered documentation and ad-hoc workflows into a structured, spec-driven development environment. Sets up directory structure, organizes documentation, and creates team guidance files.

## When to Use

- Adopting spec-driven workflow in existing project
- Organizing scattered documentation
- Standardizing team workflow practices
- Onboarding AI assistants to project structure
- Starting fresh after initial development phase

## Prerequisites

- Project has git repository
- GitHub CLI authenticated (`gh auth status`)
- Existing documentation to migrate (README, docs, etc.)
- Backup or commit current state before migration

## Workflow

### Phase 1: Discovery & Analysis

#### 1. Scan for Existing Documentation

```bash
echo "=== Scanning Project Documentation ==="

# Find all markdown files
echo "Markdown files found:"
find . -name "*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  | sort

# Check for common documentation files
echo ""
echo "Common documentation files:"
for FILE in README.md CONTRIBUTING.md DEVELOPMENT.md CLAUDE.md AGENTS.md CHANGELOG.md; do
  if [ -f "$FILE" ]; then
    echo "  ✓ Found: $FILE ($(wc -l < "$FILE") lines)"
  else
    echo "  - Missing: $FILE"
  fi
done

# Check docs directory
if [ -d "docs" ]; then
  echo ""
  echo "docs/ directory structure:"
  tree docs/ -L 2 2>/dev/null || find docs/ -type f -name "*.md"
else
  echo ""
  echo "No docs/ directory found"
fi
```

#### 2. Analyze README Structure

```bash
echo ""
echo "=== Analyzing README.md ==="

if [ -f "README.md" ]; then
  echo "README sections found:"
  grep "^##" README.md | sed 's/^/  /'

  # Check for specific sections that should be extracted
  echo ""
  echo "Sections to potentially extract:"

  if grep -qi "API\|Endpoint" README.md; then
    echo "  - API Documentation → docs/specs/[capability]/spec.md"
  fi

  if grep -qi "Architecture\|Design" README.md; then
    echo "  - Architecture → docs/specs/[capability]/design.md"
  fi

  if grep -qi "Feature\|Roadmap" README.md; then
    echo "  - Features/Roadmap → docs/prd.md"
  fi

  if grep -qi "Vision\|Goal" README.md; then
    echo "  - Vision/Goals → docs/project-brief.md"
  fi
else
  echo "No README.md found"
fi
```

#### 3. Check GitHub State

```bash
echo ""
echo "=== Analyzing GitHub State ==="

# Check issues
TOTAL_ISSUES=$(gh issue list --state all --limit 1000 --json number | jq 'length')
OPEN_ISSUES=$(gh issue list --state open --limit 1000 --json number | jq 'length')
CLOSED_ISSUES=$((TOTAL_ISSUES - OPEN_ISSUES))

echo "Issues:"
echo "  Total: $TOTAL_ISSUES"
echo "  Open: $OPEN_ISSUES"
echo "  Closed: $CLOSED_ISSUES"

# Check milestones
echo ""
echo "Milestones:"
gh api repos/:owner/:repo/milestones --jq '.[] | "  \(.state | ascii_upcase): \(.title) (\(.open_issues)/\(.open_issues + .closed_issues) issues)"'

# Check labels
echo ""
echo "Existing labels:"
gh label list --limit 100 --json name | jq -r '.[].name | "  - \(.)"'

# Check PRs
TOTAL_PRS=$(gh pr list --state all --limit 1000 --json number | jq 'length')
echo ""
echo "Pull Requests: $TOTAL_PRS total"
```

#### 4. Detect Workflow Patterns

```bash
echo ""
echo "=== Detecting Workflow Patterns ==="

# Check for conventional commits
RECENT_COMMITS=$(git log --oneline -20)
if echo "$RECENT_COMMITS" | grep -qE "^[a-f0-9]+ (feat|fix|chore|docs|test|refactor):"; then
  echo "✓ Using Conventional Commits"
else
  echo "- Not using Conventional Commits (will introduce)"
fi

# Check branch naming
BRANCHES=$(git branch -r | grep -v HEAD | sed 's|origin/||')
if echo "$BRANCHES" | grep -qE "(feature|feat|fix|chore)/"; then
  echo "✓ Using structured branch names"
else
  echo "- No structured branch naming detected"
fi

# Check for existing workflow files
if [ -f ".github/workflows/ci.yml" ] || [ -f ".github/workflows/test.yml" ]; then
  echo "✓ GitHub Actions configured"
fi

if [ -f ".github/ISSUE_TEMPLATE" ] || [ -d ".github/ISSUE_TEMPLATE" ]; then
  echo "✓ Issue templates exist"
fi

if [ -f ".github/pull_request_template.md" ]; then
  echo "✓ PR template exists"
fi
```

#### 5. Generate Discovery Report

Create comprehensive report:

```
================================================================================
                    PROJECT MIGRATION DISCOVERY REPORT
================================================================================

Project: [Project Name]
Date: 2025-10-21

DOCUMENTATION INVENTORY
-----------------------
Found Files:
  ✓ README.md (245 lines)
  ✓ CONTRIBUTING.md (89 lines)
  ✓ docs/api.md (156 lines)
  ✓ docs/architecture.md (234 lines)
  - No CLAUDE.md or AGENTS.md

README Sections:
  ## Features
  ## Installation
  ## API Documentation
  ## Architecture
  ## Contributing

GITHUB STATE
-------------
Issues: 47 total (23 open, 24 closed)
Milestones: 3 (v1.0, v2.0, backlog)
PRs: 35 total
Labels: 15 existing

WORKFLOW PATTERNS
-----------------
✓ Conventional Commits detected
- No structured branch naming
✓ GitHub Actions configured
- No issue templates
- No PR template

MIGRATION COMPLEXITY: Medium

Estimated effort:
  - Documentation migration: 2-3 hours
  - Spec creation: 4-6 hours (3-4 capabilities identified)
  - Team onboarding: 1 hour

================================================================================
```

### Phase 2: Interactive Planning

Ask user for preferences:

#### 1. README Handling

```
Found README.md with multiple sections.

How should we handle it?

1. Keep existing README, extract sections to new docs
2. Create new focused README (setup only), move everything else
3. Keep as-is, only add references to new structure

Recommendation: Option 2 (clean separation)

Your choice (1-3):
```

#### 2. Team Guidance File

```
Which AI assistant guidance file should we create?

1. CLAUDE.md (for Claude Code and similar AI assistants)
2. AGENTS.md (for multi-agent systems with defined roles)
3. Both CLAUDE.md and AGENTS.md
4. Neither (manual setup)

Recommendation: Option 1 (CLAUDE.md for most projects)

Your choice (1-4):
```

#### 3. Existing Documentation

```
Found existing documentation in docs/:
  - docs/api.md
  - docs/architecture.md
  - docs/contributing.md

How should we handle these?

1. Archive in docs/archive/ (preserve but don't use)
2. Integrate into new structure (extract to specs)
3. Leave as-is alongside new structure
4. Delete (⚠ destructive)

Recommendation: Option 2 (integrate)

Your choice (1-4):
```

#### 4. Existing Issues

```
Found 23 open issues and 3 milestones.

How should we handle existing issues?

1. Leave as-is, start fresh with Sprint S1
2. Migrate to new format gradually (as you work on them)
3. Bulk update with spec references (recommended for <50 issues)
4. Close all, recreate from scratch (⚠ loses history)

Recommendation: Option 1 or 2 (depends on issue count)

Your choice (1-4):
```

#### 5. Capabilities Identification

```
Analyzing documentation for capabilities...

Identified potential capabilities:
  1. user-authentication (from README API section)
  2. data-export (from docs/api.md)
  3. notification-system (from issues #12, #15, #23)
  4. payment-processing (from docs/architecture.md)

Should we create spec files for these now?

1. Yes, create all specs now (guided)
2. Create specs for specific capabilities only (select)
3. Skip for now, create manually later

Recommendation: Option 2 (create critical specs first)

Your choice (1-3):
```

### Phase 3: Execution

#### 1. Create Directory Structure

```bash
echo ""
echo "=== Creating Directory Structure ==="

# Create core directories
mkdir -p docs/specs
mkdir -p docs/sprint
mkdir -p docs/epics
mkdir -p docs/archive

# Create GitHub template directories
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p .github/PULL_REQUEST_TEMPLATE

echo "✓ Created docs/specs/"
echo "✓ Created docs/sprint/"
echo "✓ Created docs/epics/"
echo "✓ Created docs/archive/"
echo "✓ Created .github/ISSUE_TEMPLATE/"
echo "✓ Created .github/PULL_REQUEST_TEMPLATE/"
```

#### 2. Migrate Documentation Files

**2a. Archive Original Files**

```bash
echo ""
echo "=== Archiving Original Files ==="

# Archive README
if [ -f "README.md" ]; then
  cp README.md docs/archive/README-original.md
  echo "✓ Archived README.md → docs/archive/README-original.md"
fi

# Archive CONTRIBUTING if exists
if [ -f "CONTRIBUTING.md" ]; then
  cp CONTRIBUTING.md docs/archive/CONTRIBUTING-original.md
  echo "✓ Archived CONTRIBUTING.md → docs/archive/CONTRIBUTING-original.md"
fi

# Archive docs/ contents if exist
if [ -d "docs" ]; then
  for file in docs/*.md; do
    if [ -f "$file" ]; then
      cp "$file" "docs/archive/$(basename "$file")"
      echo "✓ Archived $file → docs/archive/$(basename "$file")"
    fi
  done
fi
```

**2b. Extract and Create project-brief.md**

```bash
cat > docs/project-brief.md << 'EOF'
# [Project Name] - Project Brief

## Vision

[Extracted from README introduction or manually filled]

## Goals

[Key objectives - extracted or manually filled]

## Core Capabilities

[List main features/capabilities identified]

1. **User Authentication**
   - Secure login/logout
   - Session management
   - Password reset

2. **Data Export**
   - Multiple format support
   - Scheduled exports
   - API access

3. **Notification System**
   - Email notifications
   - In-app alerts
   - Preferences management

## Stakeholders

- **Users**: [Target audience]
- **Team**: [Development team]
- **Business**: [Business stakeholders]

## Success Metrics

- [Metric 1]
- [Metric 2]
- [Metric 3]

## Constraints

- [Technical constraints]
- [Business constraints]
- [Timeline constraints]

## References

- Original README: `docs/archive/README-original.md`
- Architecture docs: `docs/archive/architecture.md`

---

*Migrated to spec-driven workflow: 2025-10-21*
EOF

echo "✓ Created docs/project-brief.md"
```

**2c. Create prd.md**

```bash
cat > docs/prd.md << 'EOF'
# Product Requirements Document

## Overview

[Product description - 2-3 paragraphs]

## Core Capabilities

### User Authentication

**Status**: ✅ Implemented

- Secure login/logout
- Password reset flow
- Session management
- Two-factor authentication (planned)

**Spec**: `docs/specs/user-authentication/spec.md` (to be created)

### Data Export

**Status**: ✅ Implemented

- CSV export
- JSON export
- PDF reports
- Scheduled exports

**Spec**: `docs/specs/data-export/spec.md` (to be created)

### Notification System

**Status**: 🚧 Partial Implementation

- Email notifications ✅
- In-app alerts (planned)
- SMS notifications (planned)
- Notification preferences ✅

**Spec**: `docs/specs/notification-system/spec.md` (to be created)

### Payment Processing

**Status**: 📋 Planned

- Credit card processing
- Subscription management
- Invoice generation

**Spec**: `docs/specs/payment-processing/spec.md` (to be created)

## Roadmap

### Phase 1: Foundation (Completed)
- ✅ User Authentication
- ✅ Basic Data Export
- ✅ Email Notifications

### Phase 2: Enhancement (Current)
- 🚧 Advanced Export Features
- 📋 In-app Notifications
- 📋 Two-factor Authentication

### Phase 3: Growth (Planned)
- 📋 Payment Processing
- 📋 Subscription Management
- 📋 Advanced Analytics

## Migration Notes

This PRD was created during migration to spec-driven workflow.

Status indicators:
- ✅ Implemented and stable
- 🚧 Partially implemented or in progress
- 📋 Planned for future development

Each capability should have a corresponding spec in `docs/specs/[capability]/spec.md`

---

*Migrated: 2025-10-21*
*Last Updated: 2025-10-21*
EOF

echo "✓ Created docs/prd.md"
```

**2d. Create TODO.md from Existing Issues**

```bash
echo ""
echo "=== Creating TODO.md from GitHub Issues ==="

cat > TODO.md << 'EOF'
# Project TODO

## Migration Notes

**Migration Date**: 2025-10-21

This TODO was generated during migration to spec-driven workflow.
Pre-migration issues are listed below. New workflow starts with Sprint S1.

---

## Pre-Migration Issues (Retrospective)

### Completed Issues

EOF

# Add closed issues
gh issue list --state closed --limit 50 --json number,title,closedAt \
  --jq '.[] | "- [x] #\(.number) - \(.title) - Closed: \(.closedAt | split("T")[0])"' \
  >> TODO.md

cat >> TODO.md << 'EOF'

### Open Issues (Pre-Migration)

EOF

# Add open issues
gh issue list --state open --limit 100 --json number,title,labels,milestone \
  --jq '.[] | "- [ ] #\(.number) - \(.title)\n  - Labels: \(.labels | map(.name) | join(", "))\n  - Milestone: \(.milestone.title // "None")"' \
  >> TODO.md

cat >> TODO.md << 'EOF'

---

## Current Sprint: S1 (New Workflow)

**Started**: TBD
**Status**: Planning

**Sprint Goals**:
- Set up spec-driven workflow
- Create initial specs for core capabilities
- Migrate critical open issues to new format

**Sprint Backlog**:

(Will be populated via `seed-sprint` command)

---

## Backlog

### Specs to Create

Based on migration analysis, the following specs should be created:

- [ ] Run `init-spec user-authentication`
- [ ] Run `init-spec data-export`
- [ ] Run `init-spec notification-system`
- [ ] Run `init-spec payment-processing`

### Future Enhancements

(To be added to sprint files as planned)

---

*Note: For new development, use git-workflow skill commands*
*See CLAUDE.md for workflow guide*
EOF

echo "✓ Created TODO.md with $(gh issue list --state all | wc -l) issues"
```

**2e. Create New Focused README.md**

```bash
# Backup current README
mv README.md docs/archive/README-original.md

cat > README.md << 'EOF'
# [Project Name]

[One-line project description]

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- GitHub CLI (for development workflow)

### Installation

```bash
# Clone repository
git clone https://github.com/org/repo.git
cd repo

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
npm run db:migrate

# Start development server
npm run dev
```

### First-Time Setup

```bash
# Authenticate with GitHub
gh auth login

# Verify setup
npm run test
```

## Documentation

- **Project Overview**: See `docs/project-brief.md`
- **Product Requirements**: See `docs/prd.md`
- **Technical Specifications**: See `docs/specs/`
- **Development Workflow**: See `CLAUDE.md`
- **Current Sprint**: See `TODO.md`

## Development Workflow

This project uses a spec-driven development workflow. For AI assistants (Claude Code, etc.), see `CLAUDE.md` for detailed workflow guidance.

Key documents:
- `TODO.md` - Current sprint and priorities
- `docs/specs/` - Technical specifications
- `docs/sprint/` - Sprint planning
- `.claude/skills/git-workflow/` - Workflow automation

## Contributing

We follow a spec-driven development workflow:

1. Check `TODO.md` for current priorities
2. Read relevant specs in `docs/specs/`
3. Create feature branch: `feat/123-description`
4. Implement according to spec
5. Run tests: `npm test`
6. Create pull request

See `CLAUDE.md` for detailed workflow including the 8 workflow commands.

## Testing

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run e2e tests
npm run test:e2e
```

## Deployment

[Deployment instructions]

## License

[License information]

## Support

- **Issues**: GitHub Issues
- **Documentation**: See `docs/`
- **Team Guide**: See `CLAUDE.md`

---

**Note**: This project was migrated to spec-driven workflow on 2025-10-21.
Original README preserved in `docs/archive/README-original.md`
EOF

echo "✓ Created new README.md (setup-focused)"
echo "  Original preserved in docs/archive/README-original.md"
```

#### 3. Create CLAUDE.md

```bash
echo ""
echo "=== Creating CLAUDE.md ==="
```

(Use the CLAUDE.md template from the planning section above - full content)

#### 4. Create GitHub Templates

**Issue Template**:

```bash
cat > .github/ISSUE_TEMPLATE/feature.md << 'EOF'
---
name: Feature Request
about: Propose a new feature with spec references
title: '[FEATURE] '
labels: type:feature
assignees: ''
---

## User Story

As a [role], I want [feature] so that [benefit]

## Affected Specs

- docs/specs/[capability]/spec.md

## Change Type

- [ ] ADDED Requirements (new capability)
- [ ] MODIFIED Requirements
- [ ] REMOVED Requirements

## Proposed Spec Changes

### [ADDED/MODIFIED/REMOVED] Requirements

[Describe spec changes or note "To be detailed during implementation"]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Test Plan

- Test scenario 1
- Test scenario 2

## Implementation Checklist

- [ ] Spec updated in docs/specs/
- [ ] Tests written and passing
- [ ] Design doc created (if needed)
- [ ] Code implemented
- [ ] PR created and reviewed
EOF

echo "✓ Created .github/ISSUE_TEMPLATE/feature.md"
```

**Bug Template**:

```bash
cat > .github/ISSUE_TEMPLATE/bug.md << 'EOF'
---
name: Bug Report
about: Report a bug that violates spec behavior
title: '[BUG] '
labels: type:bug
assignees: ''
---

## Description

[Clear description of the bug]

## Affected Spec

- docs/specs/[capability]/spec.md
- Violated requirement: [Requirement name]
- Violated scenario: [Scenario name]

## Steps to Reproduce

1. Step 1
2. Step 2
3. Step 3

## Expected Behavior

[What should happen according to spec]

## Actual Behavior

[What actually happens]

## Environment

- OS: [e.g., Ubuntu 22.04]
- Node: [e.g., 18.17.0]
- Branch: [e.g., main]

## Additional Context

[Screenshots, logs, etc.]
EOF

echo "✓ Created .github/ISSUE_TEMPLATE/bug.md"
```

**PR Template**:

```bash
cat > .github/pull_request_template.md << 'EOF'
## Summary

Implements: [Issue title]

## Spec Changes

Updated: `docs/specs/[capability]/spec.md`
Change Type: **[ADDED/MODIFIED/REMOVED]** Requirements

### Spec Deltas

[Detailed spec changes]

## Implementation Details

[Brief description of implementation approach]

## Testing

- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] E2E tests passing
- [ ] Linting passing
- [ ] Build successful

## Checklist

- [ ] Implementation complete
- [ ] Tests passing
- [ ] Specs updated in docs/specs/
- [ ] Acceptance criteria met
- [ ] Code reviewed (self-review)
- [ ] Breaking changes documented

## Breaking Changes

[List any breaking changes or note "None"]

## Migration Guide

[If breaking changes, provide migration guide]

---

Closes #[issue-number]
EOF

echo "✓ Created .github/pull_request_template.md"
```

### Phase 4: Analysis & Recommendations

#### 1. Identify Capabilities Needing Specs

```bash
echo ""
echo "=== Identifying Capabilities ==="

# Create list based on:
# - README sections
# - Existing docs
# - Closed issues (implemented features)
# - Open issues (planned features)

CAPABILITIES=(
  "user-authentication:Found in README API section:P1:IMPLEMENTED"
  "data-export:Found in docs/api.md:P2:IMPLEMENTED"
  "notification-system:Found in issues #12, #15, #23:P2:PARTIAL"
  "payment-processing:Found in docs/architecture.md:P3:PLANNED"
)

echo "Capabilities identified:"
for CAP in "${CAPABILITIES[@]}"; do
  IFS=':' read -r NAME SOURCE PRIORITY STATUS <<< "$CAP"
  echo ""
  echo "  Capability: $NAME"
  echo "    Source: $SOURCE"
  echo "    Priority: $PRIORITY"
  echo "    Status: $STATUS"
  echo "    Action: Run 'init-spec $NAME'"
done
```

#### 2. Analyze GitHub Configuration Gaps

```bash
echo ""
echo "=== GitHub Configuration Gaps ==="

# Check for standard labels
STANDARD_LABELS=(
  "type:feature"
  "type:bug"
  "type:chore"
  "priority:P0"
  "priority:P1"
  "priority:P2"
  "priority:P3"
  "add-capability"
  "modify-spec"
  "remove-feature"
  "blocked"
  "in-progress"
)

EXISTING_LABELS=$(gh label list --json name --jq '.[].name')

echo "Missing standard labels:"
for LABEL in "${STANDARD_LABELS[@]}"; do
  if ! echo "$EXISTING_LABELS" | grep -q "^$LABEL$"; then
    echo "  - $LABEL"
  fi
done
```

#### 3. Generate Label Creation Commands

```bash
echo ""
echo "=== Label Creation Commands ==="
echo ""
echo "Run these commands to create standard labels:"
echo ""

cat << 'EOF'
# Type labels
gh label create "type:feature" --description "New feature" --color "0e8a16"
gh label create "type:bug" --description "Bug fix" --color "d73a4a"
gh label create "type:chore" --description "Maintenance" --color "fef2c0"
gh label create "type:spec" --description "Spec update" --color "1d76db"
gh label create "type:docs" --description "Documentation" --color "0075ca"

# Priority labels
gh label create "priority:P0" --description "Critical" --color "b60205"
gh label create "priority:P1" --description "High" --color "d93f0b"
gh label create "priority:P2" --description "Medium" --color "fbca04"
gh label create "priority:P3" --description "Low" --color "0e8a16"

# Spec labels
gh label create "add-capability" --description "New capability" --color "1d76db"
gh label create "modify-spec" --description "Modify existing spec" --color "5319e7"
gh label create "remove-feature" --description "Deprecation" --color "e99695"

# Status labels
gh label create "blocked" --description "Cannot proceed" --color "d93f0b"
gh label create "in-progress" --description "Being worked on" --color "0e8a16"

# Area labels (customize for your project)
gh label create "area:frontend" --description "UI/UX" --color "d4c5f9"
gh label create "area:backend" --description "Server/API" --color "c5def5"
gh label create "area:devex" --description "Developer experience" --color "bfdadc"
EOF
```

### Phase 5: Generate Migration Report

Create comprehensive report documenting everything done:

(Use the Migration Report template from planning section - save to `MIGRATION-REPORT.md`)

```bash
cat > MIGRATION-REPORT.md << 'EOF'
[Full migration report content as planned above]
EOF

echo "✓ Created MIGRATION-REPORT.md"
```

### Phase 6: Next Steps Guidance

```bash
echo ""
echo "========================================="
echo "     MIGRATION COMPLETE!"
echo "========================================="
echo ""
echo "Files Created:"
echo "  ✓ docs/project-brief.md"
echo "  ✓ docs/prd.md"
echo "  ✓ TODO.md"
echo "  ✓ CLAUDE.md"
echo "  ✓ README.md (new, setup-focused)"
echo "  ✓ .github/ISSUE_TEMPLATE/feature.md"
echo "  ✓ .github/ISSUE_TEMPLATE/bug.md"
echo "  ✓ .github/pull_request_template.md"
echo "  ✓ MIGRATION-REPORT.md"
echo ""
echo "Directory Structure:"
echo "  ✓ docs/specs/ (ready for spec files)"
echo "  ✓ docs/sprint/ (ready for sprint files)"
echo "  ✓ docs/epics/ (ready for epic files)"
echo "  ✓ docs/archive/ (original docs preserved)"
echo ""
echo "========================================="
echo "     IMMEDIATE NEXT STEPS"
echo "========================================="
echo ""
echo "1. Review MIGRATION-REPORT.md for full details"
echo ""
echo "2. Create standard GitHub labels:"
echo "   See label commands in MIGRATION-REPORT.md"
echo "   Or run: bash -c '[label creation commands]'"
echo ""
echo "3. Create spec files for identified capabilities:"
echo "   - Run: init-spec user-authentication"
echo "   - Run: init-spec data-export"
echo "   - Run: init-spec notification-system"
echo "   - Run: init-spec payment-processing"
echo ""
echo "4. Create first sprint file:"
echo "   - Create: docs/sprint/S1.md"
echo "   - Add initial stories"
echo "   - Run: seed-sprint docs/sprint/S1.md"
echo ""
echo "5. Update team:"
echo "   - Share CLAUDE.md with team"
echo "   - Review new README.md"
echo "   - Demonstrate workflow with example"
echo ""
echo "========================================="
echo "     VALIDATION"
echo "========================================="
echo ""
echo "Verify migration:"
echo "  [ ] docs/specs/ exists"
echo "  [ ] docs/sprint/ exists"
echo "  [ ] CLAUDE.md exists"
echo "  [ ] TODO.md has current state"
echo "  [ ] GitHub templates created"
echo "  [ ] Original docs archived"
echo "  [ ] MIGRATION-REPORT.md reviewed"
echo ""
echo "========================================="
echo ""
echo "Ready to start spec-driven development!"
echo ""
echo "Next: Create your first spec with 'init-spec [capability]'"
echo ""
```

## Migration Patterns

### Pattern 1: Small Project (< 50 issues)

**Characteristics:**
- Simple documentation
- Few open issues
- Single developer or small team

**Approach:**
1. Quick migration (1-2 hours)
2. Create 1-2 core specs immediately
3. Start fresh with Sprint S1
4. Leave old issues as reference

### Pattern 2: Medium Project (50-200 issues)

**Characteristics:**
- Moderate documentation
- Active development
- Multiple contributors

**Approach:**
1. Phased migration (2-3 days)
2. Create specs for active areas first
3. Gradually migrate open issues
4. Run both workflows in parallel temporarily

### Pattern 3: Large Project (200+ issues)

**Characteristics:**
- Extensive documentation
- Long history
- Large team

**Approach:**
1. Careful migration (1-2 weeks)
2. Pilot with single team/area first
3. Create migration guide for team
4. Gradual rollout across teams/areas

## Validation Checklist

After migration, verify:

### Directory Structure
- [ ] `docs/specs/` exists and is empty (ready for specs)
- [ ] `docs/sprint/` exists and is empty (ready for sprints)
- [ ] `docs/epics/` exists (if using epics)
- [ ] `docs/archive/` contains original documentation
- [ ] `.github/ISSUE_TEMPLATE/` has feature and bug templates
- [ ] `.github/pull_request_template.md` exists

### Documentation Files
- [ ] `docs/project-brief.md` exists with vision and goals
- [ ] `docs/prd.md` exists with capabilities list
- [ ] `TODO.md` exists with migrated issues
- [ ] `CLAUDE.md` exists with workflow guide
- [ ] `README.md` focused on setup (not encyclopedia)
- [ ] `MIGRATION-REPORT.md` documents migration

### GitHub Configuration
- [ ] Standard labels identified (creation commands ready)
- [ ] Issue templates functional
- [ ] PR template functional
- [ ] Existing issues analyzed
- [ ] Milestones reviewed

### Team Readiness
- [ ] CLAUDE.md reviewed and customized
- [ ] Team aware of new workflow
- [ ] Example spec identified for demonstration
- [ ] First sprint file ready to create

## Common Migration Issues

### Issue: Too Much Documentation

**Problem**: Project has 50+ documentation files

**Solution**:
- Archive all in `docs/archive/`
- Extract only critical specs
- Create index in `docs/archive/README.md`
- Gradually integrate as needed

### Issue: Conflicting Workflows

**Problem**: Team has existing workflow they like

**Solution**:
- Adapt workflow to fit team (don't force)
- Keep what works, add spec-driven parts
- Pilot with one feature first
- Get team buy-in through demonstration

### Issue: No Clear Capabilities

**Problem**: Can't identify distinct capabilities

**Solution**:
- Start with 1-2 obvious ones
- Create broader specs initially
- Split as they grow too large
- Use existing code modules as guide

### Issue: Massive Issue Backlog

**Problem**: 500+ open issues, overwhelming

**Solution**:
- Don't migrate all issues
- Close stale issues (>6 months inactive)
- Keep top 20-30 priorities
- Archive rest with note in TODO.md
- Start fresh from current state

## Notes

- **Take backups**: Commit current state before migration
- **Iterate**: Migration doesn't have to be perfect first try
- **Team input**: Get team feedback on CLAUDE.md
- **Gradual adoption**: Don't force everything at once
- **Preserve history**: Archive, don't delete
- **Stay flexible**: Adapt workflow to team needs
- **Document decisions**: Note why things were migrated certain ways
- **Celebrate**: Migration is progress, acknowledge the effort

## Post-Migration Workflow

After migration:

1. **Week 1**: Create 2-3 critical specs
2. **Week 2**: Create first sprint (S1) with 3-5 issues
3. **Week 3**: Run complete workflow cycle (seed → next → test → submit → close)
4. **Week 4**: Review and adjust based on team feedback

Then continue with normal spec-driven workflow using the 8 commands.
