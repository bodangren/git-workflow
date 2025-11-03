---
title: Project Migrate Skill
type: proposal
status: approved
created: 2024-03-01
description: Intelligent migration tool for adding SynthesisFlow to existing projects with established documentation
---

# Proposal: Project Migrate Skill

## Problem Statement

The current `project-init` skill works well for greenfield projects but lacks the sophistication needed for brownfield/existing projects. When adding SynthesisFlow to an established codebase with existing documentation, teams face several challenges:

1. **Content Loss Risk**: Simply creating new directories doesn't preserve existing documentation
2. **No Discovery**: No automated way to find and catalog existing docs, specs, or design documents
3. **Manual Migration**: Users must manually decide what content belongs where
4. **Structural Conflicts**: Existing `docs/` directories may have different organization
5. **No Safety Net**: No backup mechanism before structural changes
6. **Missing Guidance**: No clear path for integrating existing documentation workflows

Projects with established documentation need a migration path that:
- Preserves all existing content
- Analyzes and categorizes current documentation
- Provides intelligent suggestions for content placement
- Creates backups before making changes
- Maintains git history

## Proposed Solution

Create a new `project-migrate` skill that intelligently migrates existing projects to the SynthesisFlow structure while preserving all existing documentation and providing guided migration.

### Core Capabilities

1. **Discovery Phase**: Scan project for existing documentation
   - Find all markdown files
   - Identify documentation directories
   - Detect existing specs, design docs, ADRs
   - Catalog project structure

2. **Analysis Phase**: Categorize discovered content
   - Identify specs vs proposals
   - Find approved vs draft documentation
   - Detect architectural decision records
   - Map existing structure to SynthesisFlow conventions

3. **Planning Phase**: Generate migration plan
   - Suggest target locations for each file
   - Identify conflicts and duplications
   - Propose directory structure
   - Create actionable migration tasks

4. **Backup Phase**: Preserve existing state
   - Create timestamped backup of docs/
   - Store migration manifest
   - Enable rollback capability

5. **Migration Phase**: Execute the migration
   - Create SynthesisFlow directory structure
   - Move/copy files to target locations
   - Update internal links and references
   - Preserve git history where possible

6. **Validation Phase**: Verify migration success
   - Confirm all files migrated
   - Check link integrity
   - Validate structure compliance
   - Report any issues

### User Experience

```bash
# Interactive migration with discovery and planning
bash scripts/project-migrate.sh

# Non-interactive with auto-approval
bash scripts/project-migrate.sh --auto-approve

# Dry run to see migration plan only
bash scripts/project-migrate.sh --dry-run
```

## Benefits

1. **Safe Migration**: Automatic backups prevent content loss
2. **Intelligent Categorization**: Automated analysis reduces manual decision-making
3. **Preserves History**: Git-aware migration maintains file history
4. **Clear Guidance**: Interactive prompts help users understand SynthesisFlow structure
5. **Rollback Support**: Easy restoration if migration needs adjustment
6. **Adoption Enablement**: Lowers barrier to adopting SynthesisFlow methodology

## Success Criteria

- Successfully migrates projects with existing `docs/` directories
- Creates backups before any modifications
- Preserves all existing documentation without loss
- Provides clear migration plan before execution
- Handles common documentation structures (READMEs, wikis, design docs, ADRs)
- Updates relative links to reflect new locations
- Completes migration without breaking existing references
- Enables rollback to pre-migration state
- Works on variety of project types (mono-repos, microservices, libraries)
