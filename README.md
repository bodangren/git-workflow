# SynthesisFlow - A Spec-Driven AI Development Methodology

This repository contains the tools and documentation for **SynthesisFlow**, a modular, end-to-end methodology for spec-driven software development using AI agents.

## Overview

SynthesisFlow has evolved from the original `git-workflow` skill into a more comprehensive and robust system. It synthesizes the best practices from several modern development methodologies:

- **`spec-kit`**: For a rigorous, multi-stage process of defining a feature before implementation.
- **`OpenSpec`**: For safely managing proposed changes in isolation from the source-of-truth specs.
- **`BMAD`**: For a clean and simple Git branching and merging strategy.
- **`git-workflow`**: For its powerful sprint planning and issue management capabilities.

The result is a highly-structured, portable, and AI-friendly workflow that ensures clarity, quality, and project velocity.

## The SynthesisFlow Lifecycle

Instead of a single, monolithic skill, SynthesisFlow is composed of a suite of modular skills that each handle a specific phase of the development lifecycle. The process is visualized below:

```mermaid
graph TD
    subgraph "Phase 1: Definition"
        A[Start: New Feature Idea] --> B{propose-change};
        B --> C["changes/my-feature/<br>spec-delta.md<br>plan.md<br>tasks.md"];
        C --> D[Open "Spec PR" for review];
        D --> E{Team Review & Approval};
        E -- Merge PR --> F[Spec is now "Approved"];
    end

    subgraph "Phase 2: Sprint Planning"
        F --> G{plan-sprint};
        G --> H["Selects 'Approved' specs for<br>current GitHub Milestone"];
        H --> I["Creates Epic Issue +<br>Atomic Task Issues in Milestone"];
    end

    subgraph "Phase 3: Implementation"
        I --> J{work-on-issue};
        J --> K["Reads Issue, Spec, Plan,<br>Retrospective, & Doc Index"];
        K --> L["Creates Git branch<br>(e.g., feat/issue-123)"];
        L --> M["Writes Code & Tests"];
        M --> N[Opens "Code PR" for review];
    end

    subgraph "Phase 4: Integration"
        N --> O{Code Review & Merge};
        O -- Merge PR --> P{complete-change};
        P --> Q["Merges spec-delta into<br>source-of-truth `specs/` folder"];
        Q --> R["Updates RETROSPECTIVE.md"];
        R --> S["Archives feature branch<br>& closes Epic Issue"];
        S --> T[End: Feature Complete];
    end

    style F fill:#d4edda,stroke:#c3e6cb
    style I fill:#cfe2ff,stroke:#b8daff
    style S fill:#d1ecf1,stroke:#bee5eb
```

### Core Skillsets

- **`project-init`**: Scaffolds new projects.
- **`doc-indexer`**: Provides just-in-time context of all project documentation to the AI.
- **`spec-authoring`**: Manages the creation, refinement, and approval of feature specifications via "Spec PRs".
- **`sprint-planner`**: Organizes approved specs into sprints, creating Epics and atomic Task Issues on a GitHub Project Board.
- **`issue-executor`**: The core AI development loop for implementing a single, atomic issue.
- **`change-integrator`**: Merges completed work back into the source-of-truth and archives work branches.
- **`agent-integrator`**: Registers the SynthesisFlow skills with any project's `AGENTS.md` file.

## Getting Started

> **Note:** This repository is currently undergoing the transition to SynthesisFlow. The proposal to adopt this methodology is the first feature being built with the system itself.

## Contributing

Contributions welcome! Please follow the SynthesisFlow process:

1.  Fork the repository.
2.  Use the `spec-authoring` skill to create a change proposal.
3.  Submit a "Spec PR" for review.
4.  Once approved, the feature can be planned into a sprint.

## License

MIT License - See LICENSE file for details.