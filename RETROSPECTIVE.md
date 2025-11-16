# Development Retrospective

This file captures learnings from completed tasks to inform and improve future development work.

## Historical Learnings (Sprints 1-3)

**Core Patterns:**
- Auto-merge workflow (`gh pr merge --auto --squash --delete-branch`) streamlines PR process
- `skills/` is source-of-truth; `.claude/skills/` is installed version
- Idempotent scripts with case statements work well for multi-function skills
- Parameterize scripts from the start; structured data (JSON) + `jq` > placeholder logic
- Spec-driven workflow: `propose-change` → Spec PR → approval → `plan-sprint` → atomic issues

---

### #45 - TASK: Restructure doc-indexer skill
- **Lesson:** The SynthesisFlow philosophy is not about replacing scripts with AI, but about AI executing workflow steps with strategic reasoning, using scripts as context-efficient helpers for complex automation. Dogfooding the workflow on itself was critical for uncovering this misunderstanding and other bugs. A key process gap was forgetting to update `RETROSPECTIVE.md` after closing an issue, which is a required step.

### #45-51 - Core Skills Restructuring Sprint
- **Lesson:** Established restructuring pattern: move script, expand SKILL.md, test, follow PR workflow. Documentation depth should match skill complexity. Combined SKILL.md + reference docs pattern works for complex workflows.

### #52 - TASK: Create skill validation script
- **Lesson:** An automated validation script provides objective, repeatable quality assurance and is invaluable for maintaining consistency across a suite of skills, making it perfect for CI/CD pipelines. The script achieved 96.8% compliance, validating the restructuring effort.

### #53-54 - Documentation Updates
- **Lesson:** Project documentation (AGENTS.md, README.md) is a living artifact that must evolve with the codebase. Core design philosophy should be clearly documented to orient both agents and human contributors.

### #67-81 - project-migrate Skill Sprint
- **Lesson:** Follow established patterns (don't violate retrospectives), use `git mv` for file history, build fail-safe safety features, provide multi-option interactive flows, distinguish errors vs warnings in validation, use variables for complex regex, test in isolated environments, and focus on end goals over script perfection. Complete 15-issue sprint established comprehensive migration capabilities.

### #99-108: `prd-authoring` Skill Sprint
- **Lesson:** PRDs define "What/Why" before specs define "How" - critical separation. Automated validation prevents downstream problems. Status command is key entry point for complex workflows. Templates with guidance improve UX. Traceability chain: PRD → Epic → Spec → Issues → Code.

### #117 - feat/116-integrate-gemini-cli-for-large-context-analysis-in-synthesisflow-skills

- **Went well:** Successfully integrated Gemini CLI into six core SynthesisFlow skills, replacing brittle parsing/templating with AI-powered content generation and analysis. Enhanced RETROSPECTIVE.md summarization, issue-executor planning, prd-authoring drafting, project-migrate categorization/frontmatter, sprint-planner task decomposition, and spec-authoring drafting/feedback analysis. Followed SynthesisFlow methodology for implementation, testing, and documentation updates for each skill.
- **Lesson:** The gh CLI commands for project items can be tricky to navigate, requiring careful use of project list and item-list with jq to extract the correct IDs. Integrating AI into existing shell scripts requires careful prompt engineering and robust parsing of AI output. Parallel execution of AI calls (& and wait) can significantly speed up content generation. Updating SKILL.md documentation is crucial to reflect new AI capabilities and prerequisites.


### #137 - feat/123-enhance-issue-executor-to-fetch-parent-epic-context

- **Went well:** Successfully implemented parent epic context fetching and fixed a grep bug.
- **Lesson:** Always verify assumptions about CLI tool capabilities (e.g., gh issue view JSON fields).

### #124 - feat: Add RETROSPECTIVE.md context and improve sprint-planner flexibility

- **Went well:** Successfully added RETROSPECTIVE.md context loading to sprint-planner while maintaining YAML parsing compliance and improving script flexibility with parameterizable input.
- **Key challenges:** Resolved conflict between original request (add RETROSPECTIVE.md for LLM context) and specification (remove LLM calls) by implementing human-readable context loading instead.
- **Important learnings:** Make scripts parameterizable from the start rather than hardcoding file paths. Design for flexibility and reusability even when requirements seem simple.
- **Complete workflow execution:** Full SynthesisFlow workflow completed successfully from issue-executor through PR creation to change integration.

### #125 - feat: Add comprehensive tasks.yml format specification

- **Went well:** Successfully created comprehensive tasks.yml format specification covering all acceptance criteria from issue #125. Provided clear schema, validation rules, migration guidance, and integration notes for automation.
- **Lesson:** Clear specification with examples and validation rules enables reliable automation and reduces parsing errors compared to prose-based tasks.md. Machine-readable formats significantly improve framework reliability.

### #126 - refactor: Remove LLM calls from sprint-planner and implement YAML parsing

- **Went well:** Successfully replaced LLM dependency with robust YAML parsing using yq, adding comprehensive validation for malformed files and missing required fields. Implemented graceful handling of optional priority labels and clear error messaging for debugging.
- **Lesson:** Removing external API dependencies improves reliability, performance, and maintainability. Proper validation with informative error messages is essential for automation scripts. Testing edge cases (malformed YAML, missing fields, optional data) ensures robust production behavior.


### #144 - feat/128-refactor-project-migrate-to-use-llm-for-link-correction

- **Went well:** Successfully replaced brittle shell-based link correction with robust LLM approach. The new Python script is cleaner, more maintainable, and provides better error handling with graceful fallbacks.
- **Lesson:** LLM-based approaches can dramatically simplify complex string manipulation tasks. Using Gemini Flash 2.5 model provides good balance of cost and capability. Proper fallback handling is essential when depending on external APIs.


### #145 - feat/129-create-skill-lister-skill

- **Went well:** Successfully implemented skill-lister skill with comprehensive documentation, dual output modes (human-readable and JSON), and automated skill discovery. The implementation followed established patterns from scan-docs.sh, ensuring consistency with existing SynthesisFlow skills.
- **Lesson:** Following established patterns from existing skills (using scan-docs.sh as a model) significantly accelerates development and ensures consistency. Clear acceptance criteria in issues make validation straightforward. The skill-lister itself demonstrates the value of discoverable, self-documenting systems.


### #146 - feat/130-update-agent-integrator-to-recommend-skill-lister

- **Went well:** Successfully updated agent-integrator skill to recommend skill-lister early in workflow
- **Lesson:** Important to understand the difference between .claude/skills/ (for skill distribution) and skills/ (for skill development)


### #147 - feat/131-create-doc-validator-skill

- **Went well:** Successfully implemented doc-validator skill with comprehensive pattern matching for Markdown files. The Gemini-generated implementation plan provided excellent guidance and the script works flawlessly after fixing the pattern matching logic.
- **Lesson:** When implementing glob pattern matching with ** (recursive) and * (single-level) wildcards in bash, use placeholder substitution to avoid double regex replacement. Replace ** with a placeholder first, then replace *, then replace the placeholder with .* to ensure correct regex conversion.


### #148 - feat/132-integrate-doc-validator-into-issue-executor

- **Went well:** Integration was straightforward and well-tested. The doc-validator path resolution worked correctly on first try.
- **Lesson:** Always test integration points with actual test data. The test markdown file helped verify the integration before committing.


### #149 - feat/133-integrate-doc-validator-into-change-integrator

- **Went well:** Successfully integrated doc-validator into change-integrator workflow with clear error handling and output logging. The implementation was straightforward and met all acceptance criteria on first try.
- **Lesson:** When integrating validation scripts, leveraging existing 'set -e' behavior simplifies error handling - no need for explicit exit code checks when the script already halts on failures.

