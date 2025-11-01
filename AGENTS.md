# Gemini Skill: Spec-Driven Git Workflow

## Project Overview

This repository defines a "skill" for an AI agent to manage a spec-driven software development workflow. The core of this project is the `git-workflow` skill, which provides a structured set of commands to guide a developer or AI through a complete development lifecycle, from initial project setup to sprint management and issue resolution.

The workflow is built on these key principles:

*   **Spec-First**: Specifications, stored in `docs/specs/`, are the single source of truth for what is being built.
*   **Issue-Driven**: GitHub issues are used to track all proposed changes and work items.
*   **PR-Tracked**: All code changes are implemented and reviewed through pull requests.
*   **Sprint-Organized**: Work is organized into sprints, with issues generated from sprint planning documents.
*   **Continuous Improvement**: A `RETROSPECTIVE.md` file captures learnings from each development cycle, which are then fed back into the process.

## Workflow Commands

The `git-workflow` skill consists of 12 primary commands that represent the stages of the development lifecycle:

1.  `migrate-project`: Migrates an existing (brownfield) project to this spec-driven workflow.
2.  `init-spec`: Creates or updates specification files.
3.  `seed-sprint`: Creates GitHub issues from a sprint planning file.
4.  `review-sprint`: Provides an AI-powered quality review of the issues in the current sprint.
5.  `next-issue`: Selects the next available issue to work on, reading retrospectives and review comments for context.
6.  `block-issue`: Marks an issue as blocked by dependencies.
7.  `split-issue`: Breaks down large issues into smaller, more manageable ones.
8.  `test-issue`: Runs a comprehensive suite of tests against the current implementation.
9.  `submit-issue`: Creates a pull request for a completed issue, including spec deltas.
10. `update-issue`: Handles updates to a PR based on review feedback.
11. `close-issue`: Cleans up after a PR is merged and updates the `RETROSPECTIVE.md`.
12. `sprint-status`: Provides analytics and progress reports for the current sprint.

## Directory Structure

The skill expects and interacts with a specific directory structure within the target project:

```
project/
├── docs/
│   ├── specs/                # Technical specifications (source of truth)
│   ├── sprint/               # Sprint planning files
│   ├── epics/                # Epic tracking files
│   └── releases/             # Release planning files
├── TODO.md                   # Project tracking
├── RETROSPECTIVE.md          # Living retrospective for continuous improvement
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
└── [source code]
```

## Key Files in This Repository

*   `skills/git-workflow/SKILL.md`: The primary and most up-to-date definition of the `git-workflow` skill, its commands, and their usage.
*   `skills/git-workflow/references/`: Contains detailed markdown documentation for each of the 12 workflow commands. This is the best place to find in-depth information about a specific command.
*   `README.md`: Provides a high-level overview of the project, installation instructions, and a quick-start guide.
*   `.claude/skills/git-workflow/SKILL.md`: An older version of the skill definition, likely for a different AI agent (Claude). The version in the root `skills` directory is more current.

## How to Use

The contents of this repository are not meant to be run directly as a standalone application. Instead, they define a skill that should be loaded into an AI agent. The primary interaction is to invoke the 12 workflow commands (e.g., "run `next-issue`") through the AI, which will then follow the procedures outlined in the skill's documentation to manage the development process of a target software project.
