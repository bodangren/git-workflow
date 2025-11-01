---
name: issue-executor
description: Use this skill to start work on an assigned GitHub issue. This is the core implementation loop of the SynthesisFlow methodology. The skill guides the AI to load the full context for the issue (specs, plans, retrospective), create a feature branch, and begin the implementation process.
---

# Issue Executor

This skill handles the core development phase for a single, atomic GitHub issue within the SynthesisFlow methodology.

## Overview

Once an issue has been planned into a sprint by the `sprint-planner` skill, the `issue-executor` takes over. Its sole responsibility is to guide an AI agent through the process of understanding the task, setting up the development environment, and implementing the required code changes.

**Key Principles:**
- **Context is King**: The skill must load all relevant context before any code is written.
- **Isolation**: All work is done on a dedicated feature branch to protect the main branch.
- **Atomic Work**: The scope of the skill is limited to a single, well-defined issue.

## The `work-on-issue` Command

This is the primary command for this skill, replacing the old `next-issue` command.

**Purpose**: Select a specific issue from the current sprint and begin implementation.

**When to use**:
- At the beginning of a work session.
- When you are ready to start coding for a planned issue.

**Key Actions**:
1.  **Identify Issue**: The user specifies which issue to work on (e.g., `#3`).
2.  **Verify Clean State**: Checks that the git working directory is clean.
3.  **Load Context**:
    - Reads the content of the specified GitHub issue.
    - Reads the parent Epic and its associated specification from the `docs/` folder.
    - Reads the `RETROSPECTIVE.md` to learn from past work.
    - Runs the `doc-indexer` skill to get a map of all project documentation.
4.  **Create Branch**: Creates a new feature branch named after the issue (e.g., `feat/3-restructure-skill`).
5.  **Begin Implementation**: The AI now has all the context and a dedicated branch, and is ready to start writing code, running tests, and committing work.

**Details**: See `references/work-on-issue.md`