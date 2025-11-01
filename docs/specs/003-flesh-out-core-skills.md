# Spec: Flesh out Core Skill Implementations

## Proposal

This proposal covers the work to flesh out the core logic of the SynthesisFlow skill scripts created in Sprint 2. This will involve replacing placeholder logic with functional code that can execute the defined workflows.

---

## Spec Delta

This body of work continues the implementation of the approved specification defined in `docs/specs/002-implement-core-skills.md`. No new specifications are introduced. This proposal focuses on adding detailed, robust logic to the existing skill scripts.

---

## Tasks

- [ ] **Flesh out `project-init`:** Add argument parsing and error handling.
- [ ] **Flesh out `doc-indexer`:** Improve parsing robustness and add JSON output option.
- [ ] **Flesh out `spec-authoring`:** Implement the `update` subcommand logic to fetch PR comments.
- [ ] **Flesh out `sprint-planner`:** Implement JSON parsing of the project board, user selection loop, and dynamic issue creation.
- [ ] **Flesh out `change-integrator`:** Replace placeholder variables with dynamic arguments and add robust error checking.
- [ ] **Flesh out `agent-integrator`:** Add more sophisticated logic to handle different `AGENTS.md` file edge cases.
- [ ] **Flesh out `issue-executor`:** Replace placeholder logic with dynamic context fetching and branch name generation.
