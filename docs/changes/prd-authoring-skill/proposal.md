# Proposal: PRD Authoring Skill

## Problem Statement

SynthesisFlow currently has strong support for mid-stage development workflows (spec-authoring, sprint-planner, issue-executor), but lacks guidance for **early-stage project inception activities**. Teams need support for:

- Creating Product Requirements Documents (PRDs) from initial ideas
- Conducting market research and competitive analysis
- Generating formal product briefs from vague concepts
- Translating business needs into actionable technical specifications
- Validating requirements before entering the spec-driven development workflow

Without this skill, teams must manually handle the critical transition from "project idea" to "ready for spec-authoring," which can lead to:
- Poorly defined requirements entering the spec workflow
- Missing stakeholder alignment on project goals
- Lack of market research backing decisions
- Unclear success criteria and acceptance criteria

## Proposed Solution

Create a **prd-authoring** skill that incorporates workflows from BMAD's Product Manager (PM) and Business Analyst agents to guide users through:

1. **Discovery Phase** (Analyst-driven):
   - Project readiness assessment via workflow status checks
   - Structured brainstorming sessions
   - Product brief generation from initial concepts
   - Market research and competitive analysis

2. **Requirements Definition Phase** (PM-driven):
   - PRD creation with clear objectives and success criteria
   - PRD validation against quality standards
   - Epic and story decomposition
   - Tech spec development for foundational projects

3. **Transition to Development**:
   - Bridge to existing spec-authoring workflow
   - Ensure PRD aligns with SynthesisFlow's spec structure
   - Generate initial change proposals from approved PRDs

## Benefits

- **Structured inception**: Systematic approach to starting new projects
- **Better requirements**: Data-driven PRDs with clear success criteria
- **Reduced rework**: Catch alignment issues before development starts
- **Complete workflow**: End-to-end coverage from idea to implementation
- **BMAD methodology integration**: Leverage proven PM and BA workflows
- **Seamless handoff**: PRDs naturally flow into spec-authoring process

## Success Criteria

1. Skill successfully guides users from vague project idea to detailed PRD
2. Generated PRDs contain all necessary sections (objectives, success criteria, requirements, etc.)
3. PRD validation workflow catches common quality issues
4. Clear integration path from PRD to spec-authoring workflow
5. Documentation includes examples of PRD creation for different project types
6. Helper scripts automate PRD structure creation and validation
7. Skill is usable by both technical and non-technical stakeholders
