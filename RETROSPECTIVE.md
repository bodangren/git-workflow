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

---
## Active Improvements

- Need to fix `issue-executor/run.sh` syntax error (line 47)
- Continue restructuring remaining 6 skills following doc-indexer pattern
- Validate restructured skills with new validation script (task #52)
- Keep RETROSPECTIVE.md under 100 lines by compressing older content as needed
