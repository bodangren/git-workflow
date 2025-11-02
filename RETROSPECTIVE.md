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

### #52 - TASK: Create skill validation script

- **Went well:** Created comprehensive validation script with 9 checks per skill. 271 lines of robust validation logic.
- **Automated Quality Assurance:** Script validates SKILL.md structure, frontmatter, length, scripts/ directory, imperative form usage, and required sections.
- **CI/CD Ready:** Exit codes and color-coded output make it suitable for automated pipelines.
- **Test Results:** 6/7 skills pass all checks perfectly. spec-authoring has 2 acceptable differences due to multi-command structure.
- **Validation Coverage:** 9 checks × 7 skills = 63 total checks, 61 passed (96.8% compliance).
- **Lesson:** Automated validation provides objective quality metrics and catches regressions. The high compliance rate (96.8%) validates that the restructuring pattern was applied consistently across all skills.

### #53 - TASK: Update AGENTS.md with new structure

- **Went well:** Enhanced AGENTS.md with comprehensive skill descriptions and Getting Started section.
- **5th Core Philosophy:** Added Hybrid Architecture principle to clarify LLM strategic reasoning + script automation.
- **Enhanced Descriptions:** Expanded each skill description from single-line to detailed explanations of capabilities.
- **Getting Started Section:** Added 4-step workflow guidance for agents entering the project.
- **No Broken References:** AGENTS.md never referenced specific scripts, only skill directories, so no fixes needed.
- **Lesson:** Documentation should be a living artifact that evolves with the codebase. The comprehensive skill descriptions now match the comprehensive SKILL.md documentation created during restructuring.

### #54 - TASK: Update README with restructuring notes

- **Went well:** Added comprehensive "Skill Architecture" section to README. Final task of Sprint 4 complete!
- **Directory Structure:** Documented standard skill layout with SKILL.md, scripts/ directory, and optional references/
- **Hybrid Philosophy:** Clearly explained LLM strategic reasoning + helper script automation. Emphasized this is NOT script automation vs AI instructions.
- **SKILL.md Template:** Documented 7-part template structure all skills follow.
- **Concrete Example:** Used issue-executor to demonstrate hybrid approach in action.
- **No Broken References:** README already used skill names, not script paths, so no run.sh references to update.
- **Lesson:** README is the first documentation most people read. The Skill Architecture section provides essential context for understanding SynthesisFlow's design philosophy and helps new contributors get oriented quickly.

---
## Sprint 4 Summary

🎉 **ALL 10 TASKS COMPLETE!**

- 7 skill restructurings (#45-#51): Expanded SKILL.md from 7 to 50-262 lines each
- Validation script created (#52): 96.8% compliance across all skills
- Documentation updated (#53, #54): AGENTS.md and README reflect new architecture

**Key Achievement**: Successfully applied the hybrid LLM-guided + helper-script architecture across all SynthesisFlow skills while maintaining backward compatibility and improving documentation quality.

---
## Sprint 5

### #67 - TASK: Create Skill Structure (project-migrate)

- **Went well:** Created comprehensive skill structure with SKILL.md (228 lines) and script skeleton. Followed complete workflow including auto-merge, wait, verify, and cleanup.
- **Critical Gap Identified - issue-executor Missing Completion Steps:**
  - Current issue-executor skill only covers loading context and starting work
  - **Missing steps:** Auto-merge PR, wait for CI/CD (60 seconds), check merge status, close issue if passed, clean up feature branch, switch back to main
  - User had to prompt: "The execute issue skill should require you to auto-merge, sleep 60 for it to finish merging, then check status and close out and clean up if it passed. Does it?"
  - These completion steps should be documented in issue-executor SKILL.md and/or the work-on-issue.sh script should have a companion "complete-issue.sh" script
- **Complete Workflow Should Be:**
  1. Load context and create feature branch (✅ currently implemented)
  2. Implement changes and commit
  3. Push and create PR
  4. Enable auto-merge: `gh pr merge --squash --auto`
  5. Wait for CI/CD: `sleep 60`
  6. Check merge status: `gh pr view --json mergedAt,mergedBy`
  7. Close issue with completion comment (auto-closed by PR if using "Closes #X")
  8. Clean up: `git checkout main && git pull && git branch -d feat/X-branch-name`
- **Lesson:** The issue-executor skill needs to document the COMPLETE end-to-end workflow, not just the start. Users should know the full cycle from "start work" to "issue closed and branch cleaned up". This ensures consistency and prevents forgotten steps.

### #68 - TASK: Implement Discovery Phase (project-migrate)

- **Critical Error from #67 - Wrong Directory Location:**
  - Issue #67 created project-migrate files in `.claude/skills/` instead of `skills/`
  - **Violated established pattern:** `skills/` is source-of-truth for development; `.claude/skills/` is for installed version
  - This pattern was clearly documented in Sprint 4 retrospective and followed by all other skills
  - Had to move all files to correct location before continuing work
- **Went well:** Successfully implemented comprehensive discovery phase with file scanning, type detection, and inventory display
- **Implementation Details:**
  - Scans docs/, documentation/, wiki/, and root directories for .md files
  - Detects 8 file types using pattern matching: spec, proposal, ADR, design, plan, retrospective, README, doc
  - Uses associative arrays for structured inventory (FILE_TYPES)
  - Handles nested directories (up to 10 levels), excludes .git/ and node_modules/
  - Outputs human-readable summary with type counts and categorized file list
  - Testing: Found 12 files across 5 types in current project
- **Workflow Execution:** Complete workflow executed correctly: auto-merge, 60-second wait, merge verification, auto-close issue, branch cleanup
- **Lesson:** ALWAYS check that new skills follow the established directory structure pattern (skills/ for source). When in doubt, check existing skills (agent-integrator, doc-indexer, etc.) as reference. The retrospective documents these patterns for a reason - follow them consistently.

### #69 - TASK: Implement Analysis Phase (project-migrate)

- **Went well:** Successfully implemented comprehensive analysis phase with categorization, conflict detection, and migration planning
- **Edge Case Discovery Through Testing:**
  - Initial implementation flagged false conflicts for files already in target location
  - Path normalization issue: `./RETROSPECTIVE.md` vs `RETROSPECTIVE.md` treated as different files
  - Name collision risk: Multiple subdirectories with files named `proposal.md`, `spec-delta.md`, `tasks.md`
  - Fixed by: Path normalization in conflict detection, subdirectory preservation in target path generation
- **Three-State Conflict Detection:**
  - Implemented nuanced conflict states: "false" (no conflict), "in_place" (already correct), "true" (real conflict)
  - Improves UX by distinguishing files that need no action from actual conflicts
  - Visual indicators: ✓ for in-place, ⚠️ for conflicts, blank for migrations
- **Subdirectory Preservation Strategy:**
  - Files in `docs/changes/subdir/` migrate to `docs/specs/subdir/` or `docs/subdir/`
  - Prevents name collisions when multiple subdirectories contain identically-named files
  - Example: `docs/changes/project-migrate-skill/tasks.md` → `docs/project-migrate-skill/tasks.md`
- **Categorization Logic:**
  - specs/ADRs/designs/plans → docs/specs/ (architectural source-of-truth)
  - proposals → docs/changes/ (changes under review)
  - retrospectives → root/RETROSPECTIVE.md (SynthesisFlow convention)
  - READMEs → preserved in place
  - general docs → docs/
- **Testing Results:** Tested with current project (12 files, 5 types) - 7 files already in place, 5 to migrate, 0 conflicts after fixes
- **Lesson:** Edge cases are discovered through testing with real data. Dry-run mode is invaluable for validating migration logic without side effects. Three-state conflict detection (no conflict / already in place / true conflict) provides better UX than binary detection. Subdirectory preservation is essential to avoid name collisions in complex documentation structures.

### #70 - TASK: Implement Planning Phase (project-migrate)

- **Went well:** Successfully implemented comprehensive planning phase with all 5 acceptance criteria met in first iteration
- **Implementation Scope:** Added 263 lines across 5 functions for complete planning workflow
- **Key Features Delivered:**
  - Structured JSON migration plan with timestamp and complete metadata
  - Human-readable summary with clear action groupings (files to move vs skip)
  - Interactive plan review with 4 intuitive options (approve/modify/save/cancel)
  - Plan modification mode with interactive target path adjustment
  - Automatic conflict re-detection when paths are modified
  - Timestamped manifest file: `.project-migrate-manifest-TIMESTAMP.json`
  - Proper dry-run mode handling (shows plan, skips approval prompts)
- **Design Pattern - Multi-Option Approval Flow:**
  - Not just yes/no, but actionable choices: approve, modify, save-for-later, cancel
  - Modification mode allows granular control over individual file targets
  - Recursive approval after modifications ensures user confirms changes
  - Save-and-exit option enables review workflow without execution
- **JSON Generation Best Practice:**
  - Proper string escaping for JSON safety (handles quotes in paths/rationales)
  - Structured format with arrays for easy parsing/processing
  - Includes both machine-readable data and human context (rationales)
  - Timestamp enables multiple plan versions for comparison
- **Variable Scoping Fix:**
  - Initial bug: timestamp variable set inside function that needs it externally
  - Solution: Move timestamp generation to calling function, pass manifest path to generator
  - Lesson: When variables need to persist beyond function scope, set them at appropriate level
- **Testing Validation:**
  - Dry-run test confirmed all functions work correctly
  - JSON manifest properly formatted and valid
  - Plan summary clearly distinguishes "files to move" vs "already in place"
  - Conflict detection integrated with modification workflow
- **Complete Workflow Execution:** Auto-merge enabled, 60-second wait, merge verified, issue auto-closed (#70), branch cleaned up - entire SynthesisFlow workflow executed correctly
- **Lesson:** Interactive approval flows benefit from multiple clear options rather than simple yes/no. Providing "modify" and "save for later" options gives users control and flexibility. Testing with dry-run mode before committing validates both functionality and UX. The planning phase is critical for user confidence - showing exactly what will happen before execution reduces anxiety and errors.
