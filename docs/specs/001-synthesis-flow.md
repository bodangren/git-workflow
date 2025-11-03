---
title: SynthesisFlow Methodology
type: spec
status: approved
created: 2024-01-01
description: Modular skill architecture for spec-driven development workflow
---

# Spec Delta: SynthesisFlow Methodology

This document describes the new skills that form the SynthesisFlow methodology.

## New Skill Architecture

The existing `git-workflow` skill will be deprecated and replaced by the following modular skills located in `.claude/skills/`:

1.  **`project-init`**: Scaffolds a new project with the required directory structure (`docs/specs`, `docs/changes`, etc.) and configuration files.

2.  **`doc-indexer`**: A just-in-time tool that scans YAML frontmatter from all `.md` files in the `docs/` directory and returns a structured object summarizing the project's documentation. This serves as a high-density context map for the LLM.

3.  **`spec-authoring`**: Contains the `propose-change` and `update-proposal` skills. It manages the lifecycle of a change proposal within the `docs/changes/` directory, including creating the initial spec files and iterating on them based on PR feedback.

4.  **`sprint-planner`**: Contains the `plan-sprint` skill. It identifies approved specs from the project's GitHub Project board, and from them, creates a GitHub Milestone, a parent Epic Issue, and atomic child Task Issues.

5.  **`issue-executor`**: The core development loop. The `work-on-issue` skill uses the current git branch to identify the active issue, loads all necessary context from the spec files and doc index, and performs the implementation.

6.  **`change-integrator`**: Contains the `complete-change` skill. After a code PR is merged, this skill handles cleanup by merging the spec delta into the source-of-truth `specs/` directory, updating the retrospective, and archiving the feature branch.

7.  **`agent-integrator`**: Contains the `register` skill. This idempotently creates or updates the root `AGENTS.md` file to ensure the SynthesisFlow skills are discoverable by any compatible AI agent.
