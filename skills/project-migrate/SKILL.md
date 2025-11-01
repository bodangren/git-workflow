---
name: project-migrate
description: Use this skill to migrate existing (brownfield) projects with established documentation to the SynthesisFlow structure. Intelligently discovers, categorizes, and migrates documentation while preserving content, adding frontmatter, and maintaining git history.
---

# Project Migrate Skill

## Purpose

Intelligently migrate existing projects (brownfield) to the SynthesisFlow directory structure while preserving all existing documentation. This skill provides safe, guided migration with discovery, analysis, backup, and validation phases to ensure zero data loss.

## When to Use

Use this skill in the following situations:

- Adding SynthesisFlow to an existing project with established documentation
- Migrating docs from ad-hoc structure to SynthesisFlow conventions
- Projects with existing specs, ADRs, design docs, or other markdown files
- Need to preserve documentation while adopting SynthesisFlow methodology
- Want safe migration with backups and rollback capability

## Prerequisites

- Project with existing documentation (docs/, documentation/, wiki/, or markdown files)
- Git repository initialized
- Write permissions to project directory
- `doc-indexer` skill available for frontmatter compliance checking

## Workflow

### Step 1: Assess Current State

Before migration, understand what exists:
- Check for existing docs/ directory
- Identify markdown files throughout the project
- Note any existing organizational structure

### Step 2: Run the Migration Script

Execute the helper script to start the migration process:

**Interactive mode (default)**:
```bash
bash scripts/project-migrate.sh
```

**Auto-approve mode (skip prompts)**:
```bash
bash scripts/project-migrate.sh --auto-approve
```

**Dry-run mode (see plan without executing)**:
```bash
bash scripts/project-migrate.sh --dry-run
```

### Step 3: Review Discovery Results

The script scans the project and displays:
- All markdown files found
- Categorization of files (spec, ADR, design doc, proposal, etc.)
- Proposed target locations in SynthesisFlow structure

Review the inventory and confirm to continue.

### Step 4: Approve Migration Plan

The script generates a migration plan showing:
- Source file → Target location mappings
- Conflict detection (existing files in target locations)
- Rationale for each categorization

Review the plan carefully and approve or request modifications.

### Step 5: Backup Creation

Before any changes, the script:
- Creates timestamped backup directory (`.synthesisflow-backup-YYYYMMDD-HHMMSS/`)
- Copies all existing docs/ content
- Stores migration manifest for rollback
- Generates rollback script and instructions

Note the backup location for safety.

### Step 6: Execute Migration

The script performs the migration:
- Creates SynthesisFlow directory structure (docs/specs/, docs/changes/)
- Moves files to target locations using `git mv` when possible
- Updates relative links in markdown files
- Handles conflicts safely
- Reports progress for each file

### Step 7: Frontmatter Generation (Optional)

For doc-indexer compliance, the script:
- Scans migrated files for missing frontmatter
- Extracts title from headings or filename
- Detects file type (spec, proposal, design, adr, etc.)
- Generates suggested frontmatter
- Prompts for review/customization
- Inserts frontmatter while preserving content

You can accept, edit, skip, or batch-apply suggestions.

### Step 8: Validation

The script verifies migration success:
- All discovered files accounted for
- No broken links detected
- SynthesisFlow structure exists
- Doc-indexer compliance check
- Validation report generated

Review the report for any issues.

### Step 9: Next Steps

After successful migration:
- Run `doc-indexer` to catalog the new structure
- Begin using SynthesisFlow workflow (spec-authoring, sprint-planner, etc.)
- Commit the migration to git
- Delete backup if satisfied with results

## Error Handling

### Permission Denied

**Symptom**: Cannot create directories or move files

**Solution**:
- Verify write permissions to project directory
- Check parent directory exists
- Run with appropriate permissions if necessary

### Conflicts Detected

**Symptom**: Target location already has files

**Solution**:
- Review conflict resolution options in plan
- Choose to merge, create subdirectory, or skip
- Script defaults to safe option (create subdirectory)

### Broken Links After Migration

**Symptom**: Validation reports broken links

**Solution**:
- Check link update logic worked correctly
- Manually fix any complex link patterns
- Re-run validation after fixes

### Frontmatter Generation Failed

**Symptom**: Cannot extract title or detect file type

**Solution**:
- Manually add frontmatter to problematic files
- Skip frontmatter generation and add later
- Check file has proper markdown structure

### Need to Rollback

**Symptom**: Migration didn't work as expected

**Solution**:
- Navigate to backup directory
- Run the generated rollback script
- Review rollback instructions
- Restore to pre-migration state

## Migration Phases Explained

### Discovery Phase

Scans project for markdown files in:
- docs/ directory
- documentation/ directory
- wiki/ directory
- Root-level README files
- Any *.md files

### Analysis Phase

Categorizes files by detecting patterns:
- **Specs**: Files with "spec", "specification", "requirements" in name/path → docs/specs/
- **Proposals**: Files with "proposal", "rfc", "draft" in name/path → docs/changes/
- **ADRs**: Files matching `ADR-*` or in `decisions/` → docs/specs/decisions/
- **Design**: Files with "design", "architecture" in name/path → docs/specs/
- **READMEs**: Kept in place (preserve project structure)

### Backup Phase

Creates comprehensive backup:
- Full copy of docs/ directory
- Migration manifest (JSON) with all mappings
- Rollback script for restoration
- README with instructions

### Migration Phase

Executes file movements:
- Uses `git mv` to preserve history when possible
- Copies files not in git tracking
- Updates relative links `[text](../path)` to reflect new locations
- Validates each operation

### Frontmatter Generation Phase

Ensures doc-indexer compliance:
- Detects files without YAML frontmatter
- Generates suggestions based on file analysis
- Allows interactive review and editing
- Inserts frontmatter at top of file
- Validates YAML syntax

## Notes

- **Safe by default**: Backup created before any changes
- **Git-aware**: Preserves file history when possible
- **Interactive**: Review plan before execution
- **Rollback support**: Easy restoration if needed
- **Doc-indexer integration**: Ensures frontmatter compliance
- **Conflict handling**: Never overwrites existing files
- **Link integrity**: Automatically updates relative links
- **Progress reporting**: Visibility into each step

