<!-- SYNTHESIS_FLOW_START -->
# SynthesisFlow Agent Guide

This project uses SynthesisFlow, a modular, spec-driven development methodology. The workflow is broken down into several discrete skills located in the `.claude/skills/` directory.

## Core Philosophy
1.  **Specs as Code:** All specification changes are proposed and approved via Pull Requests.
2.  **Just-in-Time Context:** Use the `doc-indexer` skill to get a real-time map of all project documentation.
3.  **Sprint-Based:** Work is organized into GitHub Milestones and planned via the `sprint-planner` skill.
4.  **Atomic Issues:** Implementation is done via atomic GitHub Issues, which are executed by the `issue-executor` skill.
5.  **Hybrid Architecture:** LLM executes workflow steps with strategic reasoning, helper scripts automate repetitive tasks.

## Available Skillsets

Each skill contains comprehensive documentation in `SKILL.md` (50-262 lines) explaining purpose, workflow, and error handling. Helper scripts are located in each skill's `scripts/` directory.

- **`.claude/skills/project-init/`**: Initialize SynthesisFlow directory structure in new projects. Creates docs/specs and docs/changes directories.
- **`.claude/skills/doc-indexer/`**: Scan and index project documentation for just-in-time context discovery. Provides a map of all available docs without loading full content.
- **`.claude/skills/spec-authoring/`**: Create and refine specification proposals via Spec PR workflow. Supports both proposing new specs and updating based on review feedback.
- **`.claude/skills/sprint-planner/`**: Plan sprints by creating GitHub milestones and issues from approved specs. Automates issue creation while LLM guides strategic planning.
- **`.claude/skills/issue-executor/`**: Execute development workflow for a single issue. Loads full context (specs, retrospective, doc index) and creates feature branch.
- **`.claude/skills/change-integrator/`**: Integrate completed changes post-merge. Moves specs to source-of-truth, updates retrospective, and cleans up branches.
- **`.claude/skills/agent-integrator/`**: Create or update this AGENTS.md file. Uses marker-based idempotent updates to register SynthesisFlow capabilities.

## Getting Started

To begin working on this project:
1. Check current git branch and status
2. Run `doc-indexer` skill to get documentation map
3. Review `RETROSPECTIVE.md` for recent learnings
4. Use `issue-executor` skill to start work on assigned issues

Each skill's `SKILL.md` provides detailed workflow instructions and explains when to use the skill.
<!-- SYNTHESIS_FLOW_END -->