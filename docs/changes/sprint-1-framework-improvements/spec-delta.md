# Spec Delta: Sprint 1 Framework Improvements

## Overview

This specification details the required changes to implement the "Sprint 1: Framework Improvements" proposal. It involves creating two new skills (`skill-lister`, `doc-validator`), significantly refactoring two existing skills (`sprint-planner`, `spec-authoring`), and enhancing several others.

## Key Changes

### 1. New `tasks.yml` Format
-   A new file, `tasks.yml`, will replace `tasks.md`.
-   It will contain a root `epic` key and a `tasks` array.
-   Each task object in the array must contain:
    -   `title` (string)
    -   `description` (string)
    -   `labels` (object)
-   The `labels` object must contain:
    -   `type` (string: `feature`, `bug`, `refactor`, `chore`, `docs`, `test`)
    -   `component` (string: e.g., `frontend`, `backend`, `api`, `database`, `auth`, `ui`, `ci-cd`, `data-pipeline`, or a skill name for this project)
-   The `labels` object may optionally contain:
    -   `priority` (string: `P0`, `P1`, `P2`)

### 2. New Skills
-   **`skill-lister`**: A new skill will be created at `.claude/skills/skill-lister/`. Its script will scan the skills directory and output a list of all available skills, their descriptions, and script paths.
-   **`doc-validator`**: A new skill will be created at `.claude/skills/doc-validator/`. Its script will scan for `.md` files outside of allowed directories and output warnings.

### 3. Major Refactors
-   **`sprint-planner`**: The `create-sprint-issues.sh` script will be refactored to remove its LLM call. It will now parse `tasks.yml` using a YAML parser and create GitHub issues in a loop.
-   **`spec-authoring`**: The `propose` function will be updated to generate a `tasks.yml` template. The `update` function will be refactored to use chained LLM calls for better coherence.

### 4. Enhancements
-   **`issue-executor`**: Will be enhanced to fetch issue comments and parent epic context. It will also be modified to run the `doc-validator`.
-   **`agent-integrator`**: Will be updated to instruct the LLM to run the `skill-lister`.
-   **`change-integrator`**: Will be enhanced to use an LLM for better retrospective entries and to run the `doc-validator`.
-   **`project-migrate`**: The link correction function will be replaced with an LLM-based implementation.
-   **`prd-authoring`**: The validation function will be augmented with an LLM-based quality check.