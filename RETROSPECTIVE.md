# Development Retrospective

This file captures learnings from completed tasks to inform and improve future development work.

## Historical Learnings (Sprints 1-3)

**Key Patterns Established:**
- Auto-merge workflow (`gh pr merge --auto --squash --delete-branch`) streamlines PR process
- Git doesn't track empty directories - use `.gitkeep` files
- `skills/` is source-of-truth for development; `.claude/skills/` is for installed version
- Idempotent scripts are crucial for reliable automation
- Shell scripts with case statements work well for multi-function skills
- Providing both human-readable and JSON output modes adds flexibility
- Parameterizing scripts from the start makes them reusable
- Structured data (JSON) + parsing tools (`jq`) more reliable than placeholder logic
- `gh project` command flags are inconsistent (--owner sometimes required/unsupported)

**Spec-Driven Workflow:**
- `propose-change` → Spec PR → approval → `plan-sprint` cycle is effective
- Spec PRs provide clear review points before implementation
- Breaking work into atomic issues improves focus and tracking

---

## Summarized Sprints (via Gemini)

### #45 - TASK: Restructure doc-indexer skill
- **Lesson:** The SynthesisFlow philosophy is not about replacing scripts with AI, but about AI executing workflow steps with strategic reasoning, using scripts as context-efficient helpers for complex automation. Dogfooding the workflow on itself was critical for uncovering this misunderstanding and other bugs. A key process gap was forgetting to update `RETROSPECTIVE.md` after closing an issue, which is a required step.

### #46 - TASK: Restructure project-init skill
- **Lesson:** Establishing a clear, repeatable pattern for restructuring skills (move script, expand SKILL.md, test, follow PR workflow) significantly accelerated the process. The template approach was validated.

### #47 - TASK: Restructure spec-authoring skill
- **Lesson:** Complex skills with multiple sub-commands require more comprehensive documentation in `SKILL.md` to explain the strategic intent and usage of each command, justifying a longer file.

### #49 - TASK: Restructure issue-executor skill
- **Lesson:** The existing structure of this skill, which combined a `SKILL.md` overview with a detailed `references/work-on-issue.md` document, is a good pattern for other complex workflow skills. Restructuring also uncovered and fixed a critical syntax error.

### #48 - TASK: Restructure sprint-planner skill
- **Lesson:** After five restructurings, the pattern is solid and execution is fast. For skills that require user configuration, documenting common error scenarios and providing clear setup guidance is essential.

### #50 - TASK: Restructure change-integrator skill
- **Lesson:** For skills that automate a process, documenting both the automated script usage and a manual step-by-step alternative provides valuable flexibility for users.

### #51 - TASK: Restructure agent-integrator skill
- **Lesson:** Documentation depth should match skill complexity. Simpler, infrequently used maintenance skills can have more concise documentation. This completed the restructuring of all 7 core skills, validating the template approach across different skill types.

### #52 - TASK: Create skill validation script
- **Lesson:** An automated validation script provides objective, repeatable quality assurance and is invaluable for maintaining consistency across a suite of skills, making it perfect for CI/CD pipelines. The script achieved 96.8% compliance, validating the restructuring effort.

### #53 - TASK: Update AGENTS.md with new structure
- **Lesson:** Project documentation like `AGENTS.md` is a living artifact. It should evolve with the codebase to accurately reflect the current architecture and provide a clear entry point for agents, including core philosophical principles.

### #54 - TASK: Update README with restructuring notes
- **Lesson:** The main `README.md` is the most critical entry point for human contributors. It must clearly document the project's core design philosophy (e.g., the Hybrid Architecture) to orient new contributors quickly.

### #67 - TASK: Create Skill Structure (project-migrate)
- **Lesson:** A critical gap was identified in the `issue-executor` skill: it lacked the final steps of the development workflow (auto-merge, verify, cleanup). The complete end-to-end workflow, from starting work to closing the issue and cleaning up the branch, must be documented.

### #68 - TASK: Implement Discovery Phase (project-migrate)
- **Lesson:** A critical error was made by creating files in the wrong directory (`.claude/skills/` instead of `skills/`), violating a pattern documented in a previous retrospective. **Always** follow established project patterns and refer to previous retrospectives and existing code as the source of truth.

### #69 - TASK: Implement Analysis Phase (project-migrate)
- **Lesson:** Real-world testing is essential for discovering edge cases, such as path normalization issues (`./file` vs `file`) and name collisions. A three-state conflict detection system ("false", "in_place", "true") provides a much better user experience than a binary one.

### #70 - TASK: Implement Planning Phase (project-migrate)
- **Lesson:** For interactive CLI workflows, providing a multi-option approval flow (e.g., approve, modify, save, cancel) gives users more control and confidence than a simple yes/no prompt. A dry-run mode is critical for validating UX and logic before execution.

### #71 - TASK: Implement Backup Phase (project-migrate)
- **Lesson:** Safety features like backups must be fail-safe, aborting the entire operation on failure. A rollback script is not complete without a clear, interactive confirmation prompt and comprehensive README documentation covering both automated and manual restoration.

### #72 - TASK: Implement Migration Phase (project-migrate)
- **Lesson:** To preserve file history, `git mv` should be the primary tool for moving files, with a graceful fallback to a standard `mv` for untracked files. Building stub functions for future phases is a clean way to prepare the architecture for upcoming features.

### #73 - TASK: Implement Link Update Logic (project-migrate)
- **Lesson:** In Bash, complex regex patterns should be stored in variables to avoid escaping issues within conditional expressions. For path calculations, array-based manipulation is more reliable than string manipulation, especially for paths that don't exist yet.

### #74 - TASK: Implement Validation Phase (project-migrate)
- **Lesson:** A robust validation phase builds user confidence. It's crucial to distinguish between blocking `Errors` (e.g., missing files) and non-blocking `Warnings` (e.g., broken links) and to provide actionable suggestions for every issue found, including pointing to the rollback command on failure.

### #75 - TASK: Implement Frontmatter Generation (project-migrate)
- **Lesson:** Interactive review UIs should offer powerful options like "edit" and "batch apply to all" to improve efficiency. For safety, auto-approve modes should skip sensitive operations like frontmatter generation, which require human review. Integrating with existing tools (like `doc-indexer`) is a great way to validate a new feature's output.

### #76 - TASK: Implement Interactive Modes (project-migrate)
- **Lesson:** Good CLI UX means users always know what's happening and what will happen next. Use progressive disclosure, explaining each phase before it runs, and provide clear visual separators and progress indicators.

### #77 - TASK: Write SKILL.md Documentation (project-migrate)
- **Lesson:** Documentation is best refined *after* implementation is complete to ensure it's accurate. Focus on consolidating redundant information rather than just cutting content to meet an arbitrary line count.

### #78 - TASK: Create Rollback Mechanism (project-migrate)
- **Lesson:** A truly safe rollback mechanism must prioritize data preservation above all else. It should create a "safety backup" of the current state *before* attempting to roll back and use conditional logic to avoid deleting user-created content that wasn't part of the original migration.

### #79 - TASK: Integration Testing (project-migrate)
- **Lesson:** Comprehensive integration testing in isolated, realistic environments (`/tmp/`) is the ultimate validation of a skill's quality. Documenting test results in a structured report serves as both evidence of thoroughness and a valuable artifact for future reference.

### #80 - TASK: Update project-init Integration (project-migrate)
- **Lesson:** Skills should work together as a cohesive system. Improve user experience by detecting context (like existing documentation) and suggesting the correct tool for the job, creating a smooth handoff between skills.

### #81 - TASK: Register with agent-integrator (project-migrate)
- **Lesson:** If a helper script is buggy, completing the task manually is an acceptable workaround. The end goal (registering the skill in `AGENTS.md`) is more important than the method. This task completed the 15-issue sprint for the `project-migrate` skill.

### #99 - #108: `prd-authoring` Skill Sprint
- **Lesson:** This 10-task sprint established a new, complex skill for strategic planning. Key learnings include:
    - **Strategy vs. Tactics:** PRDs define the "What/Why" before specs define the "How." This separation is critical.
    - **Validation as a Quality Gate:** Automated validation for vague language, unmeasurable criteria, and missing sections prevents downstream problems.
    - **Templates with Guidance:** Embedding templates with inline comments into the script itself simplifies maintenance and dramatically improves the first-time user experience.
    - **Status Command is Key:** A `status` command that assesses the current state and recommends the next actionable step is the most important entry point for a complex, multi-phase workflow.
    - **Traceability is Everything:** The workflow must bridge the gap from strategy to execution, creating a clear chain: **PRD → Epic → Spec → Issues → Code**. This was achieved via the `generate-spec` command.
    - **Realistic Examples Teach Quality:** A detailed example (like the payment gateway case study) is the best way to show users what a high-quality output looks like.

### #117 - feat/116-integrate-gemini-cli-for-large-context-analysis-in-synthesisflow-skills

- **Went well:** Successfully integrated Gemini CLI into six core SynthesisFlow skills, replacing brittle parsing/templating with AI-powered content generation and analysis. Enhanced RETROSPECTIVE.md summarization, issue-executor planning, prd-authoring drafting, project-migrate categorization/frontmatter, sprint-planner task decomposition, and spec-authoring drafting/feedback analysis. Followed SynthesisFlow methodology for implementation, testing, and documentation updates for each skill.
- **Lesson:** The gh CLI commands for project items can be tricky to navigate, requiring careful use of project list and item-list with jq to extract the correct IDs. Integrating AI into existing shell scripts requires careful prompt engineering and robust parsing of AI output. Parallel execution of AI calls (& and wait) can significantly speed up content generation. Updating SKILL.md documentation is crucial to reflect new AI capabilities and prerequisites.

