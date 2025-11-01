# Tasks: Claude Code Skill Compliance Restructuring

This document breaks down the restructuring work into atomic, implementable tasks.

## Task 1: Restructure doc-indexer skill

**Priority**: High (foundational skill used by others)

**Subtasks**:
- [ ] Fix syntax error in run.sh (missing `do` keywords on lines 13 and 30)
- [ ] Move `run.sh` ’ `scripts/scan-docs.sh`
- [ ] Expand SKILL.md to 50-100 lines following template
- [ ] Document when to use the skill
- [ ] Explain how to interpret script output
- [ ] Add error handling guidance

**Acceptance Criteria**:
- Script runs without syntax errors
- SKILL.md clearly explains purpose and workflow
- Helper script usage is documented with examples

---

## Task 2: Restructure project-init skill

**Priority**: High (initialization skill)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/init-project.sh`
- [ ] Expand SKILL.md to 50-100 lines following template
- [ ] Document when to initialize SynthesisFlow
- [ ] Explain directory structure created
- [ ] Add guidance on next steps after init

**Acceptance Criteria**:
- SKILL.md clearly explains initialization workflow
- Helper script usage is documented
- Next steps are clear for new projects

---

## Task 3: Restructure spec-authoring skill

**Priority**: High (core workflow skill)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/spec-authoring.sh`
- [ ] Expand SKILL.md to 100-150 lines following template
- [ ] Document `propose` subcommand workflow
- [ ] Document `update` subcommand workflow
- [ ] Explain Spec PR philosophy and process
- [ ] Add guidance on populating proposal files

**Acceptance Criteria**:
- SKILL.md explains both subcommands clearly
- Workflow steps are actionable
- Spec PR process is well-documented

---

## Task 4: Restructure sprint-planner skill

**Priority**: High (core workflow skill)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/create-sprint-issues.sh`
- [ ] Expand SKILL.md to 100-150 lines following template
- [ ] Document sprint planning workflow
- [ ] Explain spec selection process
- [ ] Document milestone and issue creation
- [ ] Add guidance on project board integration

**Acceptance Criteria**:
- SKILL.md clearly explains sprint planning process
- Helper script usage is well-documented
- Selection and creation workflows are clear

---

## Task 5: Restructure issue-executor skill

**Priority**: High (core development skill)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/work-on-issue.sh`
- [ ] Refine SKILL.md (already ~40 lines, expand to 80-120)
- [ ] Convert references/work-on-issue.md to imperative form
- [ ] Align terminology (remove "Next Issue Command" references)
- [ ] Clarify when to use helper script vs manual steps

**Acceptance Criteria**:
- SKILL.md workflow is clear and complete
- Reference doc uses consistent imperative form
- Terminology is aligned throughout

---

## Task 6: Restructure change-integrator skill

**Priority**: Medium (post-merge workflow)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/integrate-change.sh`
- [ ] Expand SKILL.md to 80-120 lines following template
- [ ] Document post-merge integration workflow
- [ ] Explain spec-delta ’ specs/ merging process
- [ ] Document retrospective update process
- [ ] Add guidance on branch cleanup

**Acceptance Criteria**:
- SKILL.md clearly explains integration workflow
- Timing of when to run is documented
- All integration steps are covered

---

## Task 7: Restructure agent-integrator skill

**Priority**: Low (setup/maintenance skill)

**Subtasks**:
- [ ] Move `run.sh` ’ `scripts/update-agents-file.sh`
- [ ] Expand SKILL.md to 50-80 lines following template
- [ ] Document when to register/update SynthesisFlow
- [ ] Explain AGENTS.md purpose and structure
- [ ] Document idempotent update strategy

**Acceptance Criteria**:
- SKILL.md explains registration workflow
- Purpose of AGENTS.md is clear
- Helper script usage is documented

---

## Task 8: Create skill restructuring validation script

**Priority**: Medium (quality assurance)

**Subtasks**:
- [ ] Create `scripts/validate-skills.sh` script
- [ ] Check SKILL.md exists and has proper frontmatter
- [ ] Check SKILL.md length (50-200 lines)
- [ ] Check scripts/ directory exists
- [ ] Verify no run.sh files remain in skill root
- [ ] Check for imperative form usage (basic heuristics)

**Acceptance Criteria**:
- Script can validate all skill directories
- Reports clear pass/fail for each check
- Can be run as part of CI/CD

---

## Task 9: Update AGENTS.md with new structure

**Priority**: Low (documentation)

**Subtasks**:
- [ ] Update AGENTS.md to reflect scripts/ directory
- [ ] Update skill descriptions if needed
- [ ] Ensure all 7 skills are listed

**Acceptance Criteria**:
- AGENTS.md accurately reflects new structure
- No broken references to run.sh files

---

## Task 10: Update README with restructuring notes

**Priority**: Low (documentation)

**Subtasks**:
- [ ] Add section on skill structure
- [ ] Document helper script philosophy
- [ ] Update any examples that reference run.sh

**Acceptance Criteria**:
- README reflects new skill architecture
- Philosophy is clearly communicated

---

## Implementation Order

Recommended sequence:
1. Task 1 (doc-indexer) - Fix bugs and establish pattern
2. Task 2 (project-init) - Simple skill, good second example
3. Task 3 (spec-authoring) - Important workflow skill
4. Task 4 (sprint-planner) - Important workflow skill
5. Task 5 (issue-executor) - Core development skill
6. Task 6 (change-integrator) - Post-merge workflow
7. Task 7 (agent-integrator) - Setup skill
8. Task 8 (validation script) - Quality assurance
9. Task 9 (AGENTS.md update) - Documentation
10. Task 10 (README update) - Documentation

## Estimated Effort

- Tasks 1-7: ~1-2 hours each (skill restructuring)
- Task 8: ~1 hour (validation script)
- Tasks 9-10: ~30 minutes each (documentation)

**Total**: ~10-15 hours of implementation work
