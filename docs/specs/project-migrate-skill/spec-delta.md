# Spec Delta: Project Migrate Skill

## Overview

Add a new `project-migrate` skill to the SynthesisFlow suite that handles intelligent migration of existing projects to the SynthesisFlow directory structure. This skill complements `project-init` by addressing the specific needs of brownfield projects with established documentation.

## Skill Structure

```
.claude/skills/project-migrate/
 SKILL.md                      # Main workflow documentation (50-200 lines)
 scripts/
     project-migrate.sh        # Migration automation script
```

## Requirements

### R1: Discovery and Analysis

**Requirement**: The skill must discover and analyze existing project documentation.

**Implementation**:
- Scan for all markdown files in common documentation locations
- Look for patterns: `docs/`, `documentation/`, `wiki/`, root-level READMEs
- Detect documentation types: specs, ADRs, design docs, proposals
- Generate structured inventory of discovered content

**Detection Patterns**:
- Specs: Files with "spec", "specification", "requirements" in name/path
- ADRs: Files matching `ADR-*`, `adr-*`, or in `decisions/` directory
- Design Docs: Files with "design", "architecture" in name/path
- Proposals: Files with "proposal", "rfc", "draft" in name/path

### R2: Migration Planning

**Requirement**: Generate a migration plan that maps existing content to SynthesisFlow structure.

**Implementation**:
- Categorize each discovered file into target directory
- Identify potential conflicts (e.g., existing `docs/specs/` content)
- Suggest file placements with rationale
- Allow user review and modification of plan

**Mapping Rules**:
- Approved specs � `docs/specs/`
- Draft/proposal content � `docs/changes/`
- ADRs � `docs/specs/decisions/` (preserve ADR structure)
- General docs � Keep in place or suggest `docs/` root
- READMEs � Keep in place (preserve project structure)

### R3: Safe Backup

**Requirement**: Create complete backup before any migration operations.

**Implementation**:
- Create timestamped backup: `.synthesisflow-backup-YYYYMMDD-HHMMSS/`
- Copy entire `docs/` directory if exists
- Store migration manifest (JSON/YAML) documenting:
  - Timestamp
  - Files discovered
  - Migration plan
  - Original locations
- Log backup location prominently

**Backup Structure**:
```
.synthesisflow-backup-20250102-143022/
 docs/                    # Full copy of original docs/
 migration-manifest.json  # Migration plan and file mapping
 README.md               # Restoration instructions
```

### R4: Intelligent Migration

**Requirement**: Execute migration while preserving content and structure.

**Implementation**:
- Create SynthesisFlow directory structure (docs/specs, docs/changes)
- Move/copy files according to migration plan
- Preserve git history using `git mv` when appropriate
- Update relative links in markdown files
- Handle name conflicts with suffixes or subdirectories

**Link Update Logic**:
- Parse markdown files for relative links: `[text](../../changes/project-migrate-skill/../path/to/file.md)`
- Calculate new relative path based on target location
- Update link references
- Validate updated links point to existing files

### R5: Interactive Guidance

**Requirement**: Provide clear guidance throughout migration process.

**Implementation**:
- Interactive mode (default): Show plan, ask for approval at each phase
- Auto-approve mode: Execute full migration with single confirmation
- Dry-run mode: Show plan without executing
- Clear progress indicators for each phase
- Helpful error messages with recovery suggestions

**User Interactions**:
1. Discovery � Show inventory, ask to continue
2. Planning � Show migration plan, ask to approve/modify
3. Backup � Confirm backup location
4. Migration � Show progress, confirm success
5. Validation � Report results, suggest next steps

### R6: Rollback Capability

**Requirement**: Support rollback to pre-migration state.

**Implementation**:
- Provide rollback script in backup directory
- Document rollback procedure in backup README
- Rollback restores from backup and removes SynthesisFlow additions
- Warn about git history implications

**Rollback Script**:
```bash
# Generated in .synthesisflow-backup-*/rollback.sh
#!/bin/bash
# Restore docs/ from backup
# Remove SynthesisFlow directories if empty
# Show restoration summary
```

### R7: Validation

**Requirement**: Verify migration completed successfully.

**Implementation**:
- Check all source files are in target locations
- Validate link integrity (no broken links)
- Confirm SynthesisFlow structure exists
- Report any issues or warnings
- Suggest next steps (e.g., run doc-indexer)

**Validation Checks**:
- File count: All discovered files accounted for
- Link validation: All markdown links resolve
- Structure: docs/specs and docs/changes exist
- Conflicts: Report any unresolved conflicts

### R8: Frontmatter Generation

**Requirement**: Add YAML frontmatter to migrated files that lack it, ensuring compliance with doc-indexer expectations.

**Implementation**:
- Use doc-indexer's scan script to detect non-compliant files (missing frontmatter)
- For files without frontmatter, generate based on:
  - File type (spec, design, adr, proposal, retrospective, plan)
  - File name and location
  - Content analysis (extract title from first heading)
  - Git metadata (creation date, author)
- Prompt user to review/customize generated frontmatter interactively
- Add frontmatter fields following doc-indexer conventions:
  - `title`: Extracted from filename or first `#` heading
  - `type`: spec | proposal | design | retrospective | plan | adr
  - `status`: draft | in-review | approved | archived
  - `created`: Git file creation date or current date
  - `author`: Git author or prompt user (optional)
  - `description`: Optional summary (can prompt user)

**Detection Logic**:
```bash
# Leverage existing doc-indexer script to find non-compliant files
bash .claude/skills/doc-indexer/scripts/scan-docs.sh | grep "WARNING"
```

**Generated Frontmatter Examples**:

For a spec file:
```yaml
---
title: Authentication System Design
type: spec
status: approved
created: 2024-01-15
description: OAuth2 implementation for user authentication
---
```

For an ADR:
```yaml
---
title: Use PostgreSQL for Primary Database
type: adr
status: approved
created: 2024-02-01
---
```

For a proposal:
```yaml
---
title: Real-time Notifications Feature
type: proposal
status: draft
created: 2025-01-15
---
```

**User Interaction**:
- After migration, scan for non-compliant files
- Show list of files needing frontmatter
- For each file, suggest frontmatter based on analysis
- Allow user to:
  - Accept suggested frontmatter
  - Edit fields interactively
  - Skip (leave file without frontmatter)
  - Apply to all remaining files

**Validation**:
- Run doc-indexer scan after frontmatter generation
- Confirm no non-compliant files remain (or user acknowledged skips)
- Validate frontmatter syntax is correct

## Design Decisions

### Decision 1: Copy vs Move

**Context**: Should migration copy or move files?

**Decision**: Use `git mv` for files within git repository to preserve history. Use copy for files outside git tracking.

**Rationale**:
- Preserves git history when possible
- Safe fallback to copying prevents data loss
- Users can review and clean up after validation

### Decision 2: Conflict Resolution

**Context**: How to handle existing `docs/specs/` content?

**Decision**:
- Detect conflicts during planning phase
- Offer options: merge, create subdirectory, skip
- Default to creating subdirectory for migrated content
- Never overwrite existing files

**Rationale**:
- Preserves all content
- Gives user control
- Safe default prevents data loss

### Decision 3: Link Updates

**Context**: Should we automatically update relative links?

**Decision**: Yes, with validation and dry-run preview.

**Rationale**:
- Broken links defeat purpose of migration
- Automatic update saves significant manual effort
- Validation ensures correctness
- Dry-run lets users review changes

### Decision 4: Interactivity

**Context**: Should migration be interactive or automatic?

**Decision**: Interactive by default, with auto-approve flag available.

**Rationale**:
- First-time users need guidance
- Reviewing plan prevents mistakes
- Power users can skip with flag
- Best of both worlds

### Decision 5: Frontmatter Generation Approach

**Context**: Should frontmatter be generated automatically or require user input?

**Decision**: Semi-automatic with user review. Generate suggested frontmatter, but require user confirmation/editing.

**Rationale**:
- Full automation risks incorrect categorization (draft vs approved, spec vs design)
- User knows the intent and status better than file analysis can determine
- Interactive review ensures quality and accuracy
- Batch operations available for power users ("apply to all")
- Leverages existing doc-indexer script for consistency
- Optional step - users can skip frontmatter generation if preferred

## Migration Path

### For Existing Repositories

Projects already using ad-hoc documentation can adopt SynthesisFlow by:

1. Run `project-migrate` skill
2. Review generated migration plan
3. Approve migration or request adjustments
4. Validate migrated structure
5. Run `doc-indexer` to catalog new structure
6. Begin using SynthesisFlow workflow

### Integration with Existing Skills

- **project-init**: Calls project-migrate if existing docs detected
- **doc-indexer**: Works seamlessly with migrated structure
- **spec-authoring**: Uses migrated specs as source-of-truth
- **agent-integrator**: Registers project-migrate along with other skills

## Testing Strategy

1. **Test with empty project**: Should behave like project-init
2. **Test with simple docs/**: Migrate a few markdown files
3. **Test with complex structure**: Multiple directories, ADRs, nested docs
4. **Test with conflicts**: Existing docs/specs/ directory
5. **Test rollback**: Verify restoration works correctly
6. **Test link updates**: Ensure relative links remain valid
7. **Test dry-run**: Verify no actual changes occur
8. **Test frontmatter generation**:
   - Files without frontmatter get suggestions
   - Frontmatter extraction from headings works
   - Generated frontmatter is valid YAML
   - Doc-indexer scan shows compliance after generation
9. **Test mixed frontmatter**: Some files with, some without frontmatter
10. **Test frontmatter skip**: User can skip frontmatter generation

## Success Metrics

- Zero data loss during migration
- 100% of discovered files migrated successfully
- Link integrity maintained (no broken links)
- Successful rollback when needed
- Clear migration plan generated every time
- Users can complete migration in under 5 minutes
- All migrated files compliant with doc-indexer (or user acknowledged skips)
- Generated frontmatter accurately reflects file type and status
