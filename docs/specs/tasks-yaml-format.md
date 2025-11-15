---
title: Tasks YAML Format Specification
type: spec
status: approved
created: 2024-03-01
description: Machine-readable format for sprint task definitions in SynthesisFlow
---

# Spec: Tasks YAML Format Specification

## Overview

This specification defines the `tasks.yml` format, a machine-readable replacement for the prose-based `tasks.md` files used in the SynthesisFlow framework. The YAML format enables direct automation, reduces parsing errors, and provides a structured approach to defining sprint tasks.

## Purpose

The `tasks.yml` file serves as the single source of truth for task definitions within a sprint or feature proposal. It replaces `tasks.md` to enable:

- Automated task creation via YAML parsing instead of LLM prose parsing
- Consistent task structure and labeling
- Direct integration with GitHub issue creation workflows
- Reduced ambiguity in task definitions

## File Structure

### Root Level

The `tasks.yml` file must contain exactly two root-level keys:

```yaml
epic: <string>
tasks: <array>
```

- `epic`: A string that identifies the parent epic or sprint name
- `tasks`: An array of task objects

### Task Object Structure

Each object in the `tasks` array must contain the following required fields:

```yaml
title: <string>
description: <string>
labels: <object>
```

#### Required Fields

- **title** (string): The task title. Should follow the pattern "Task: [Action] [Component/System]"
- **description** (string): Detailed description of what needs to be accomplished, including acceptance criteria if applicable
- **labels** (object): A nested object containing classification labels

#### Labels Object

The `labels` object must contain these required fields:

```yaml
type: <string>
component: <string>
```

And may optionally contain:

```yaml
priority: <string>
```

### Label Values

#### type (Required)

Must be one of the following values:

- `feature`: New functionality or user-facing features
- `bug`: Bug fixes or error corrections
- `refactor`: Code restructuring without functional changes
- `chore`: Maintenance tasks, dependencies, or other non-functional work
- `docs`: Documentation changes or additions
- `test`: Test-related work, including new tests or test improvements
- `enhancement`: Improvements to existing functionality
- `docs`: Documentation-specific tasks (allowed alternative for consistency)

#### component (Required)

Should identify the system component being worked on. Common values include:

**For SynthesisFlow Framework:**
- Specific skill names (e.g., `issue-executor`, `sprint-planner`, `spec-authoring`)
- `framework`: Core framework changes affecting multiple skills
- `ci-cd`: Continuous integration or deployment changes

**For General Projects:**
- `frontend`: Frontend/UI components
- `backend`: Backend services and APIs
- `api`: API-specific changes
- `database`: Database schema or migrations
- `auth`: Authentication and authorization
- `ui`: User interface components
- `data-pipeline`: Data processing pipelines

#### priority (Optional)

Must be one of the following values:

- `P0`: Critical priority, blocking other work
- `P1`: High priority, important for current sprint goals
- `P2`: Normal priority, can be deferred if needed

## Example

```yaml
epic: "Sprint 1: Framework Improvements"
tasks:
  - title: "Task: Define tasks.yml format"
    description: "Create a formal specification or documentation for the new machine-readable tasks.yml format, including required and optional fields and labels."
    labels:
      type: "docs"
      component: "framework"
      priority: "P0"

  - title: "Task: Refactor sprint-planner to parse tasks.yml"
    description: "Remove the LLM call from create-sprint-issues.sh and replace it with a YAML parser to read tasks.yml directly and create issues automatically."
    labels:
      type: "refactor"
      component: "sprint-planner"
      priority: "P0"

  - title: "Task: Update spec-authoring to generate tasks.yml"
    description: "Update skills/spec-authoring/scripts/spec-authoring.sh to generate a tasks.yml file with the new YAML structure instead of a tasks.md file."
    labels:
      type: "enhancement"
      component: "spec-authoring"
      priority: "P1"
```

## Migration from tasks.md

When converting from `tasks.md` to `tasks.yml`:

1. Preserve all task information from the original markdown
2. Map task categories to the `labels.type` enumeration
3. Identify components for each task and set `labels.component`
4. Assign priorities based on task importance and dependencies
5. Maintain the same epic/sprint grouping in the root `epic` field

## Validation Rules

Implementations should validate `tasks.yml` files against these rules:

1. **Root structure**: Must contain `epic` (string) and `tasks` (array)
2. **Task requirements**: Each task must have `title`, `description`, and `labels`
3. **Label requirements**: Each `labels` object must have `type` and `component`
4. **Enum validation**: `type` and `priority` must be from allowed values
5. **String validation**: All string fields must be non-empty

## Integration Notes

### For sprint-planner Skill

The `create-sprint-issues.sh` script should:

1. Parse the `tasks.yml` file using a YAML parser
2. Create a parent Epic issue using the `epic` field
3. Iterate through the `tasks` array, creating one GitHub issue per task
4. Apply labels to each issue based on the `labels` object
5. Set issue priorities based on the `labels.priority` field (if present)

### For spec-authoring Skill

The proposal generation functions should:

1. Generate a `tasks.yml` template instead of `tasks.md`
2. Pre-populate common `labels.component` values based on the project context
3. Suggest appropriate `labels.type` values for different kinds of work
4. Include comments in the YAML to guide human users