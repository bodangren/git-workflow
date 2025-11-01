# Spec: Implement Core SynthesisFlow Skills

## Proposal

This proposal covers the work to implement the core logic for the foundational SynthesisFlow skills scaffolded in Sprint 1. This will involve writing the initial scripts and logic for each modular skill.

---

## Spec Delta

This body of work implements the approved specification defined in `docs/specs/001-synthesis-flow.md`. No new specifications are introduced; this proposal is purely for the implementation of that approved design.

---

## Tasks

- [ ] **Implement `project-init` skill:** Write the script to scaffold the `docs/specs` and `docs/changes` directories.
- [ ] **Implement `doc-indexer` skill:** Write the script that scans `docs/` and returns a YAML/JSON object of all frontmatter.
- [ ] **Implement `spec-authoring` skill:** Write the logic for the `propose-change` and `update-proposal` commands.
- [ ] **Implement `sprint-planner` skill:** Write the logic to query the project board and create issues.
- [ ] **Implement `change-integrator` skill:** Write the script to merge specs and clean up branches post-merge.
- [ ] **Implement `agent-integrator` skill:** Write the script to idempotently update `AGENTS.md`.
- [ ] **Refactor `issue-executor`:** Ensure the `work-on-issue` command properly loads context and creates branches.
