# Tasks: PRD Authoring Skill

## Task 1: Create Skill Directory Structure

Create the skill directory and establish the file organization.

**Subtasks**:
- [ ] Create `skills/prd-authoring/` directory
- [ ] Create `skills/prd-authoring/SKILL.md` with YAML frontmatter
- [ ] Create `skills/prd-authoring/scripts/` directory
- [ ] Create `.gitkeep` file for directory persistence

**Acceptance Criteria**:
- Directory structure matches existing skills (spec-authoring, sprint-planner)
- YAML frontmatter includes name, description, triggers
- Follows SynthesisFlow skill conventions

**Estimated Effort**: 15 minutes

---

## Task 2: Write SKILL.md Documentation

Create comprehensive workflow documentation for the skill.

**Subtasks**:
- [ ] Write "Purpose" section describing skill objectives
- [ ] Write "When to Use" section with trigger scenarios
- [ ] Document workflow commands (status, brief, research, create-prd, validate-prd, decompose)
- [ ] Add usage examples for each command
- [ ] Document error handling scenarios
- [ ] Add integration notes for spec-authoring handoff

**Acceptance Criteria**:
- SKILL.md follows established pattern from spec-authoring
- Each command has clear workflow steps
- Examples demonstrate common use cases
- Error scenarios have actionable solutions
- Integration with other skills is documented

**Estimated Effort**: 2-3 hours

---

## Task 3: Create Helper Script (prd-authoring.sh)

Develop the bash script that implements skill commands.

**Subtasks**:
- [ ] Create `scripts/prd-authoring.sh` with command structure
- [ ] Implement `status` command (assess project readiness)
- [ ] Implement `brief` command (create product brief template)
- [ ] Implement `research` command (create research template)
- [ ] Implement `create-prd` command (create PRD from brief/research)
- [ ] Implement `validate-prd` command (check PRD quality)
- [ ] Implement `decompose` command (break PRD into epics)
- [ ] Add error handling and validation
- [ ] Make script executable (chmod +x)

**Acceptance Criteria**:
- All commands create proper directory structure
- Templates include YAML frontmatter
- Script validates inputs and provides helpful errors
- Generated files follow SynthesisFlow conventions
- Script follows bash best practices (set -e, proper quoting)

**Estimated Effort**: 4-5 hours

---

## Task 4: Create Document Templates

Develop markdown templates for each document type.

**Subtasks**:
- [ ] Create product-brief.md template with sections (problem, solution, users, success)
- [ ] Create research.md template with sections (competitors, market, findings)
- [ ] Create prd.md template with sections (objectives, requirements, constraints, assumptions)
- [ ] Create epics.md template for epic decomposition
- [ ] Add YAML frontmatter examples to each template
- [ ] Include inline guidance comments in templates

**Acceptance Criteria**:
- Templates are comprehensive but not overwhelming
- Each section has helpful prompts/questions
- YAML frontmatter includes: title, type, status, created, updated
- Templates demonstrate SynthesisFlow markdown conventions
- Guidance comments explain purpose of each section

**Estimated Effort**: 2 hours

---

## Task 5: Implement Workflow Status Logic

Create the assessment logic for project readiness.

**Subtasks**:
- [ ] Check for existence of docs/prds/ directory
- [ ] Detect existing product brief
- [ ] Detect existing research
- [ ] Detect existing PRD
- [ ] Analyze completeness of existing documents
- [ ] Recommend next workflow step based on findings
- [ ] Output clear status report

**Acceptance Criteria**:
- Correctly identifies project phase (inception, research, prd, ready)
- Recommendations are actionable and specific
- Handles edge cases (partial documents, missing sections)
- Output is human-readable and formatted
- Suggests appropriate command to run next

**Estimated Effort**: 2 hours

---

## Task 6: Implement PRD Validation Logic

Create validation checks for PRD quality.

**Subtasks**:
- [ ] Check for required sections (objectives, success criteria, requirements)
- [ ] Validate requirements are specific and testable
- [ ] Check for YAML frontmatter completeness
- [ ] Identify ambiguous language (should, might, probably)
- [ ] Verify success criteria are measurable
- [ ] Check for missing acceptance criteria
- [ ] Generate validation report with line numbers

**Acceptance Criteria**:
- Catches common PRD quality issues
- Provides specific feedback with file locations
- Validation report is actionable
- Supports both strict and lenient validation modes
- Follows markdown linting best practices

**Estimated Effort**: 3 hours

---

## Task 7: Implement Epic Decomposition Logic

Create logic to break PRD into epics for sprint planning.

**Subtasks**:
- [ ] Parse PRD requirements into logical groupings
- [ ] Generate epic definitions with scope boundaries
- [ ] Identify dependencies between epics
- [ ] Create initial spec proposal structure for each epic
- [ ] Link epics back to PRD requirements (traceability)
- [ ] Output epics.md with structured breakdown

**Acceptance Criteria**:
- Epics are independently deliverable
- Dependencies are clearly documented
- Each epic maps to specific PRD requirements
- Spec proposal structure is ready for spec-authoring
- Traceability is maintained

**Estimated Effort**: 3-4 hours

---

## Task 8: Add Integration with spec-authoring

Ensure smooth handoff from PRD to spec workflow.

**Subtasks**:
- [ ] Create command to generate spec proposals from epics
- [ ] Populate proposal.md with epic scope
- [ ] Populate spec-delta.md with epic requirements
- [ ] Populate tasks.md with initial task breakdown
- [ ] Link generated specs back to PRD
- [ ] Document integration workflow in SKILL.md

**Acceptance Criteria**:
- Generated spec proposals are valid for spec-authoring
- Traceability from spec to PRD is maintained
- Integration is documented with examples
- No manual file manipulation required
- Follows existing spec-authoring conventions

**Estimated Effort**: 2 hours

---

## Task 9: Create Usage Examples and Tests

Develop comprehensive examples and test the workflow.

**Subtasks**:
- [ ] Create example product brief for sample project
- [ ] Create example research document
- [ ] Create example PRD with multiple requirements
- [ ] Test status command on various project states
- [ ] Test validation on good and bad PRDs
- [ ] Test epic decomposition on sample PRD
- [ ] Document examples in SKILL.md
- [ ] Add troubleshooting section

**Acceptance Criteria**:
- Examples cover common project types (feature, system, enhancement)
- All commands tested and working
- Edge cases identified and documented
- Troubleshooting guides added for common errors
- Examples are included in skill documentation

**Estimated Effort**: 2-3 hours

---

## Task 10: Update Project Documentation

Register the skill and update related documentation.

**Subtasks**:
- [ ] Add prd-authoring to skills README
- [ ] Update AGENTS.md if present (agent discovery)
- [ ] Add skill to workflow diagram if exists
- [ ] Create retrospective entry for skill creation
- [ ] Update any integration guides

**Acceptance Criteria**:
- Skill is discoverable through standard channels
- Integration points are documented
- Related documentation is updated
- Retrospective captures learnings from development

**Estimated Effort**: 1 hour

---

## Summary

**Total Estimated Effort**: 22-27 hours

**Milestones**:
1. Foundation (Tasks 1-2): Skill structure and documentation
2. Core Implementation (Tasks 3-7): Commands and logic
3. Integration (Task 8): spec-authoring handoff
4. Validation (Tasks 9-10): Testing and documentation

**Dependencies**:
- Tasks 3-7 depend on Task 1 (directory structure)
- Task 8 depends on Task 7 (epic decomposition)
- Task 9 depends on Tasks 3-7 (core implementation)
- Task 10 depends on Task 9 (testing complete)
