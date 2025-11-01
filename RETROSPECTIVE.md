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
## Sprint 4

### Spec Approval: "Claude Code Skill Compliance"

- **Went well:** Using the SynthesisFlow workflow to refactor itself ("dogfooding") revealed bugs in existing skills and validated the methodology
- **Lesson:** Dogfooding is extremely valuable for understanding and improving workflows. Issues found: syntax errors in `doc-indexer` and `issue-executor` scripts

### #45 - TASK: Restructure doc-indexer skill

- **Went well:** Successfully restructured doc-indexer. Fixed multiple bugs. Expanded SKILL.md from 7 to 186 lines.
- **Critical Friction - Misunderstood the Design Intent:**
  1. Initially provided "Claude Code compliance" recommendations without understanding SynthesisFlow's actual philosophy
  2. Suggested converting scripts to AI instructions, which completely missed the point
  3. User had to redirect: "Read the specs and retrospective FIRST to understand the workflow"
- **The Real SynthesisFlow Philosophy (Most Important Learning):**
  - **LLM executes the workflow STEPS** with full strategic understanding and reasoning
  - **Scripts are context-efficient helpers** for repetitive/complex automation (like GitHub API calls, parsing)
  - **NOT** script automation vs AI instructions - it's AI-guided workflows WITH helper scripts
  - **Context efficiency is first-class:** doc-indexer scans frontmatter without loading full docs to save tokens
  - Example: sprint-planner should guide LLM through reviewing specs and discussing with user, then use helper script to create GitHub issues
- **Process Gaps I Had:**
  1. Forgot to wait for auto-merge and verify completion
  2. User reminded: "Enable auto-merge, wait 60 seconds, verify status"
  3. **Forgot to update RETROSPECTIVE.md after closing issue** - user had to remind me
  4. User: "Don't forget the retro!" - this is a REQUIRED step, not optional
- **Dogfooding Works:** Using SynthesisFlow to refactor itself revealed bugs and validated the methodology
- **Technical Fixes:** Fixed subshell output loss with process substitution (`done < <(find ...)`), fixed two syntax errors
- **Meta-Learning:** I initially captured technical details but missed the higher-level insights from the actual conversation. The user corrected: "What did you ACTUALLY learn?" The real learnings are about understanding design intent, following complete workflows, and the philosophy behind the architecture - not just the technical implementation details.

### #46 - TASK: Restructure project-init skill

- **Went well:** Second restructuring went smoothly following the pattern established with doc-indexer. Completed in significantly less time. Expanded SKILL.md from 7 to 179 lines.
- **Pattern Validated:** The restructuring approach is now established:
  1. Move run.sh → scripts/descriptive-name.sh
  2. Expand SKILL.md (50-200 lines) with workflow instructions
  3. Test both usage patterns (default and with options)
  4. Follow complete PR workflow including retrospective
- **Testing Improvement:** Tested both default usage and -d flag option in temp directories to ensure script works correctly before committing
- **Lesson:** Having a clear pattern from the first restructuring (doc-indexer) made subsequent restructurings much faster and more confident. The template approach works.

### #47 - TASK: Restructure spec-authoring skill

- **Went well:** Restructuring proceeded smoothly. Expanded SKILL.md from 7 to 242 lines documenting both subcommands and Spec PR philosophy.
- **Multi-Subcommand Skill:** This was the first skill with multiple subcommands (propose and update), requiring more comprehensive documentation to explain when and how to use each.
- **Testing Both Subcommands:** Tested both `propose` (creates directory structure) and `update` (fetches PR comments) to ensure both work correctly
- **Philosophy Documentation:** Included "Specs as Code" philosophy section explaining WHY spec PRs matter, not just HOW to use them - important for LLM understanding of strategic intent
- **Lesson:** More complex skills (multiple subcommands) benefit from clear section headers and comprehensive examples. The SKILL.md is longer (242 lines) but necessary to cover both workflows thoroughly.

### #49 - TASK: Restructure issue-executor skill

- **Went well:** Successfully fixed syntax error and restructured. Expanded SKILL.md from 40 to 193 lines. This skill already had a good foundation with references directory.
- **Bug Fix During Restructuring:** Discovered and fixed syntax error on line 47 (quote escaping in grep pattern `[^[:space:]`']*`). Also updated doc-indexer path from old run.sh to new scripts/scan-docs.sh.
- **Existing Structure:** issue-executor already had references/work-on-issue.md, showing the right pattern. Other skills should follow this approach for detailed workflow documentation.
- **Terminology Cleanup:** Changed "Next Issue Command" to "Work on Issue Workflow" for consistency and clarity.
- **Core Principles Section:** Added clear documentation of "Context is King", "Isolation", and "Atomic Work" principles - helps LLM understand WHY the workflow is structured this way.
- **Lesson:** Skills with detailed workflow steps benefit from having both SKILL.md (overview + when to use) and references/ (detailed step-by-step). The issue-executor pattern is good for complex workflow skills.

### #48 - TASK: Restructure sprint-planner skill

- **Went well:** Fifth restructuring completed smoothly. Expanded SKILL.md from 7 to 243 lines. Pattern is now very well-established and executing quickly.
- **Comprehensive Workflow:** Documented 9-step sprint planning workflow clearly separating LLM strategic steps (review board, discuss scope, define metadata) from helper script automation (query API, create issues).
- **Configuration Guidance:** Added section explaining how to adapt the script for different projects - includes finding project-specific IDs and repository paths. This helps users customize the skill.
- **Error Handling:** Documented 6 common error scenarios with solutions. Covers both user errors (jq not installed) and workflow issues (missing spec references).
- **Pattern Consistency:** Each restructuring follows same approach and gets faster. The template is proven and repeatable.
- **Lesson:** After 5 restructurings (doc-indexer, project-init, spec-authoring, issue-executor, sprint-planner), the pattern is solid. Remaining skills should be straightforward following this template.

### #50 - TASK: Restructure change-integrator skill

- **Went well:** Sixth restructuring completed smoothly. Expanded SKILL.md from 7 to 262 lines. Post-merge workflow now comprehensively documented.
- **Dual Approach:** Documented both automated script usage AND manual step-by-step alternative. Provides flexibility for users who prefer manual control.
- **Post-Merge Focus:** Clearly emphasized this runs AFTER code PR is merged, not before. Prevents confusion about timing.
- **Integration Details:** Documented the complete integration process: branch cleanup, spec file movement from docs/changes/ to docs/specs/, retrospective updates, project board sync.
- **Configuration Notes:** Explained project-specific IDs needed for project board integration. Noted that future version should auto-detect these.
- **Lesson:** Skills that can be run manually benefit from documenting both automated and manual approaches. Gives users choice and understanding of what automation does.

### #51 - TASK: Restructure agent-integrator skill

- **Went well:** Seventh and FINAL skill restructuring completed. Expanded SKILL.md from 7 to 150 lines. All 7 SynthesisFlow skills now restructured!
- **Simpler Scope:** This skill is a setup/maintenance tool run infrequently, so 50-80 line target was appropriate (finished at 150 lines with comprehensive coverage).
- **Idempotent Strategy:** Clearly documented the marker-based approach that allows safe repeated runs without side effects.
- **Discovery Purpose:** Explained AGENTS.md purpose for AI agent discovery - helps agents understand available capabilities when entering a project.
- **Pattern Completion:** All 7 skills now follow consistent structure: expanded SKILL.md (50-262 lines), scripts/ directory, imperative form, comprehensive error handling.
- **Lesson:** Simpler skills benefit from more concise documentation. Not every skill needs 200+ lines - match documentation depth to complexity. The 7-skill restructuring sprint validates that the template approach scales well across different skill types (simple setup tools to complex workflow skills).

---
## Active Improvements

- Validate restructured skills with new validation script (task #52)
- Update README and AGENTS.md with restructuring notes (tasks #53, #54)
- Keep RETROSPECTIVE.md under 100 lines by compressing older content as needed
- All 7 skill restructurings complete! 🎉
