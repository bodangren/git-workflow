<!-- SYNTHESIS_FLOW_START -->
# SynthesisFlow Agent Guide

This project uses SynthesisFlow, a modular, spec-driven development methodology. The workflow is broken down into several discrete skills located in the `.claude/skills/` directory.

## Core Philosophy
1.  **Specs as Code:** All specification changes are proposed and approved via Pull Requests.
2.  **Just-in-Time Context:** Use the `doc-indexer` skill to get a real-time map of all project documentation.
3.  **Sprint-Based:** Work is organized into GitHub Milestones and planned via the `sprint-planner` skill.
4.  **Atomic Issues:** Implementation is done via atomic GitHub Issues, which are executed by the `issue-executor` skill.

## Available Skillsets
- **`.claude/skills/project-init/`**: For initial project scaffolding.
- **`.claude/skills/doc-indexer/`**: For real-time documentation discovery.
- **`.claude/skills/spec-authoring/`**: For proposing and refining new specifications.
- **`.claude/skills/sprint-planner/`**: For creating GitHub issues from approved specs.
- **`.claude/skills/issue-executor/`**: For implementing code for a single issue.
- **`.claude/skills/change-integrator/`**: For finalizing and archiving a completed change.
- **`.claude/skills/agent-integrator/`**: For creating or updating this guide in `AGENTS.md`.

To begin, always assess the current state by checking the git branch and running the `doc-indexer`.
<!-- SYNTHESIS_FLOW_END -->