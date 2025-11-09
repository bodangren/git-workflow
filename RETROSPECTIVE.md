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

I am sorry, but I cannot access the file at the provided path. For security reasons, I can only access files within the project directory (`/home/daniel-bo/Desktop/git-skill`).

Please copy the file you want me to summarize into the project directory, and then I will be able to assist you.

### #117 - feat/116-integrate-gemini-cli-for-large-context-analysis-in-synthesisflow-skills

- **Went well:** Successfully integrated Gemini CLI into six core SynthesisFlow skills, replacing brittle parsing/templating with AI-powered content generation and analysis. Enhanced RETROSPECTIVE.md summarization, issue-executor planning, prd-authoring drafting, project-migrate categorization/frontmatter, sprint-planner task decomposition, and spec-authoring drafting/feedback analysis. Followed SynthesisFlow methodology for implementation, testing, and documentation updates for each skill.
- **Lesson:** The gh CLI commands for project items can be tricky to navigate, requiring careful use of project list and item-list with jq to extract the correct IDs. Integrating AI into existing shell scripts requires careful prompt engineering and robust parsing of AI output. Parallel execution of AI calls (& and wait) can significantly speed up content generation. Updating SKILL.md documentation is crucial to reflect new AI capabilities and prerequisites.

