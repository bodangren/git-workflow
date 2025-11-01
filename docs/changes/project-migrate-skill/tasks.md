# Tasks: Project Migrate Skill

## Task 1: Create Skill Structure

Create the basic directory structure and skeleton files for the project-migrate skill.

**Subtasks**:
- [ ] Create `.claude/skills/project-migrate/` directory
- [ ] Create `SKILL.md` with YAML frontmatter
- [ ] Create `scripts/` subdirectory
- [ ] Create initial `scripts/project-migrate.sh` script

**Acceptance Criteria**:
- Directory structure matches SynthesisFlow conventions
- SKILL.md has proper frontmatter with name and description
- Scripts directory exists and is executable
- Skill is discoverable by Claude Code

## Task 2: Implement Discovery Phase

Build the discovery logic that finds and catalogs existing documentation.

**Subtasks**:
- [ ] Scan for markdown files in common locations (docs/, documentation/, wiki/, root)
- [ ] Detect documentation types using pattern matching
- [ ] Build inventory data structure (JSON or associative array)
- [ ] Output human-readable inventory summary

**Acceptance Criteria**:
- Discovers all .md files in project
- Correctly identifies file types (spec, ADR, design doc, proposal)
- Handles nested directory structures
- Outputs structured inventory
- No false negatives (misses no relevant files)

## Task 3: Implement Analysis Phase

Categorize discovered content and generate migration suggestions.

**Subtasks**:
- [ ] Implement categorization rules (specs ’ docs/specs/, proposals ’ docs/changes/)
- [ ] Handle special cases (ADRs, READMEs, root-level docs)
- [ ] Detect conflicts (existing content in target directories)
- [ ] Generate target path for each discovered file

**Acceptance Criteria**:
- Each file has suggested target location
- Categorization rules correctly applied
- Conflicts detected and reported
- Handles edge cases (duplicate names, nested structures)
- Rationale provided for each categorization

## Task 4: Implement Planning Phase

Create migration plan that can be reviewed and approved.

**Subtasks**:
- [ ] Generate structured migration plan (JSON/YAML)
- [ ] Create human-readable plan summary
- [ ] Implement plan review prompt (show plan, ask for approval)
- [ ] Support plan modifications (interactive adjustment of target paths)
- [ ] Save plan to manifest file

**Acceptance Criteria**:
- Migration plan clearly shows source ’ target mappings
- User can review complete plan before execution
- Plan is saved for rollback reference
- Interactive review is intuitive
- Plan includes conflict resolution strategy

## Task 5: Implement Backup Phase

Create safe backup mechanism before any modifications.

**Subtasks**:
- [ ] Generate timestamped backup directory name
- [ ] Copy existing docs/ directory to backup location
- [ ] Store migration manifest in backup directory
- [ ] Create backup README with restoration instructions
- [ ] Generate rollback script

**Acceptance Criteria**:
- Complete backup created before any changes
- Backup location clearly communicated to user
- Backup includes all necessary restoration data
- Rollback script is functional
- README documents restoration procedure

## Task 6: Implement Migration Phase

Execute the actual file movements and transformations.

**Subtasks**:
- [ ] Create SynthesisFlow directory structure (docs/specs/, docs/changes/)
- [ ] Move/copy files according to migration plan using `git mv` when possible
- [ ] Handle conflicts (create subdirectories, ask for resolution)
- [ ] Update relative links in markdown files
- [ ] Validate each file operation

**Acceptance Criteria**:
- All files successfully moved to target locations
- Git history preserved where applicable
- No data loss during migration
- Relative links updated correctly
- Conflicts resolved safely
- Progress reported for each file

## Task 7: Implement Link Update Logic

Update relative links in markdown files to reflect new locations.

**Subtasks**:
- [ ] Parse markdown files for link patterns `[text](path)` and `![alt](path)`
- [ ] Calculate new relative paths based on file's new location
- [ ] Update link references in file content
- [ ] Validate updated links point to existing files
- [ ] Report link update statistics

**Acceptance Criteria**:
- All relative links correctly updated
- No broken links after migration
- Image links and document links both handled
- Link validation confirms integrity
- Report shows number of links updated

## Task 8: Implement Validation Phase

Verify migration completed successfully and report results.

**Subtasks**:
- [ ] Check all source files are in target locations
- [ ] Validate link integrity (no broken links)
- [ ] Confirm SynthesisFlow structure exists
- [ ] Compare file counts (discovered vs migrated)
- [ ] Generate validation report

**Acceptance Criteria**:
- All discovered files accounted for
- No broken links detected
- Required directories exist (docs/specs/, docs/changes/)
- Validation report is comprehensive
- Issues clearly reported with suggestions

## Task 9: Implement Interactive Modes

Support different execution modes (interactive, auto-approve, dry-run).

**Subtasks**:
- [ ] Implement interactive mode with phase-by-phase approval
- [ ] Implement `--auto-approve` flag for non-interactive execution
- [ ] Implement `--dry-run` flag to show plan without execution
- [ ] Add clear progress indicators
- [ ] Implement helpful prompts and confirmations

**Acceptance Criteria**:
- Default interactive mode works smoothly
- Auto-approve mode skips prompts appropriately
- Dry-run shows plan without making changes
- Progress is visible during long operations
- User always knows what's happening

## Task 10: Write SKILL.md Documentation

Create comprehensive workflow documentation for the skill.

**Subtasks**:
- [ ] Write "Purpose" section
- [ ] Write "When to Use" section
- [ ] Document workflow steps (discovery ’ validation)
- [ ] Add usage examples for each mode
- [ ] Document error handling scenarios
- [ ] Add notes and best practices

**Acceptance Criteria**:
- SKILL.md is 50-200 lines
- Clear workflow instructions for LLM
- Examples show common usage patterns
- Error scenarios documented with solutions
- Follows SynthesisFlow skill template
- Links to helper script appropriately

## Task 11: Create Rollback Mechanism

Implement safe rollback to pre-migration state.

**Subtasks**:
- [ ] Generate rollback.sh script in backup directory
- [ ] Implement restoration logic (copy backup back)
- [ ] Remove SynthesisFlow directories if empty after rollback
- [ ] Create rollback instructions in backup README
- [ ] Test rollback on various scenarios

**Acceptance Criteria**:
- Rollback script successfully restores original state
- SynthesisFlow additions removed appropriately
- Rollback instructions are clear
- Works with partial migrations
- Safe guards against data loss

## Task 12: Integration Testing

Test the skill with various project scenarios.

**Subtasks**:
- [ ] Test with empty project (no docs/)
- [ ] Test with simple docs directory (few markdown files)
- [ ] Test with complex structure (nested, ADRs, multiple types)
- [ ] Test with existing docs/specs/ (conflict scenario)
- [ ] Test link updates across various structures
- [ ] Test rollback functionality
- [ ] Test all execution modes (interactive, auto-approve, dry-run)

**Acceptance Criteria**:
- All test scenarios pass
- No data loss in any scenario
- Conflicts handled gracefully
- Links remain valid after migration
- Rollback works in all scenarios
- Each mode behaves as expected

## Task 13: Update project-init Integration

Enhance project-init to detect existing docs and suggest project-migrate.

**Subtasks**:
- [ ] Add detection logic in project-init for existing docs/
- [ ] Display suggestion to use project-migrate instead
- [ ] Update project-init SKILL.md with migration guidance
- [ ] Ensure smooth handoff between skills

**Acceptance Criteria**:
- project-init detects existing documentation
- Clear suggestion provided to use project-migrate
- Documentation explains when to use each skill
- No confusion about which skill to use

## Task 14: Register with agent-integrator

Ensure project-migrate is discoverable by AI agents.

**Subtasks**:
- [ ] Run agent-integrator skill to update AGENTS.md
- [ ] Verify project-migrate appears in skill registry
- [ ] Test skill discovery by Claude Code

**Acceptance Criteria**:
- project-migrate listed in AGENTS.md
- Skill is discoverable by Claude Code
- Description accurately reflects functionality
- Trigger keywords are appropriate
