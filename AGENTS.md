<!-- SYNTHESIS_FLOW_START -->
# SynthesisFlow Agent Guide

This project uses SynthesisFlow, a modular, spec-driven development methodology. The workflow is broken down into several discrete skills located in the `skills/` and `.claude/skills/` directories.

## Core Philosophy
1.  **Specs as Code:** All specification changes are proposed and approved via Pull Requests.
2.  **Just-in-Time Context:** Use the `doc-indexer` skill to get a real-time map of all project documentation.
3.  **Sprint-Based:** Work is organized into GitHub Milestones and planned via the `sprint-planner` skill.
4.  **Atomic Issues:** Implementation is done via atomic GitHub Issues, which are executed by the `issue-executor` skill.
5.  **Hybrid Architecture:** LLM executes workflow steps with strategic reasoning, helper scripts automate repetitive tasks.

## Available Skillsets

Each skill contains comprehensive documentation in `SKILL.md` (50-262 lines) explaining purpose, workflow, and error handling. Helper scripts are located in each skill's `scripts/` directory.

- **`skills/skill-lister/`**: For listing all available skills and their descriptions.
- **`skills/project-init/`**: Initialize SynthesisFlow directory structure in new projects. Creates docs/specs and docs/changes directories.
- **`skills/project-migrate/`**: Migrate existing (brownfield) projects with established documentation to SynthesisFlow structure. Intelligently discovers, categorizes, and migrates documentation while preserving content, adding frontmatter, and maintaining git history.
- **`skills/prd-authoring/`**: Guide early-stage project planning through Product Requirements Documents (PRDs). Manages the complete workflow from initial product briefs through market research, PRD creation, validation, and epic decomposition. Bridges the gap between project ideas and spec-driven development with data-driven requirements and measurable success criteria.
- **`skills/doc-indexer/`**: Scan and index project documentation for just-in-time context discovery. Provides a map of all available docs without loading full content.
- **`skills/spec-authoring/`**: Create and refine specification proposals via Spec PR workflow. Supports both proposing new specs and updating based on review feedback.
- **`skills/sprint-planner/`**: Plan sprints by creating GitHub milestones and issues from approved specs. Automates issue creation while LLM guides strategic planning.
- **`skills/issue-executor/`**: Execute development workflow for a single issue. Loads full context (specs, retrospective, doc index) and creates feature branch.
- **`skills/change-integrator/`**: Integrate completed changes post-merge. Moves specs to source-of-truth, updates retrospective, and cleans up branches.
- **`skills/doc-validator/`**: Validate that Markdown files are in standard locations. Scans for .md files outside of predefined allowed directories and outputs warnings to prevent documentation sprawl.
- **`skills/agent-integrator/`**: Create or update this AGENTS.md file. Uses marker-based idempotent updates to register SynthesisFlow capabilities.

## Getting Started

To begin working on this project:
1. Check current git branch and status
2. Run `skill-lister` to see the list of available tools and their descriptions
3. Run `doc-indexer` skill to get documentation map
4. Review `RETROSPECTIVE.md` for recent learnings
5. Use `issue-executor` skill to start work on assigned issues

Each skill's `SKILL.md` provides detailed workflow instructions and explains when to use the skill.
<!-- SYNTHESIS_FLOW_END -->