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

- **Went well:** Successfully restructured the doc-indexer to Claude Code compliance. Fixed multiple bugs (syntax errors and subshell output loss). Expanded SKILL.md from 7 to 186 lines with comprehensive workflow instructions.
- **Friction:** Multiple issues discovered:
  1. Two syntax errors: missing `do` keywords on while loops (lines 13, 30)
  2. Subshell output loss: Pipeline `find | while` created subshell that swallowed all output
  3. Issue-executor script has syntax error on line 47 (heredoc quote mismatch)
- **Technical Solution:** Fixed subshell issue by using process substitution (`done < <(find ...)`) instead of pipeline. This ensures the while loop runs in the current shell, not a subshell, so output is visible.
- **Lesson:** Bash pipelines create subshells. Use process substitution when you need side effects (like echo/print) from loop bodies to be visible. This is critical for scripts that produce output.
- **Architecture Insight:** The hybrid approach (LLM-guided workflows + helper scripts) works well. SKILL.md now guides Claude on when/why/how to use the helper script, achieving both context efficiency and strategic understanding.
- **Process Improvement:** Confirmed complete issue workflow:
  1. Create feature branch
  2. Implement changes
  3. Create PR
  4. Enable auto-merge: `gh pr merge --auto --squash --delete-branch`
  5. Wait 60 seconds for tests/merge
  6. Verify merge: `gh pr view --json state,mergedAt`
  7. Issue auto-closes when PR merges
  8. Switch to main: `git switch main && git pull`
  9. Prune stale refs: `git fetch --prune`
  10. **Update RETROSPECTIVE.md** (don't forget!)
- **Documentation Quality:** Writing comprehensive SKILL.md files (50-200 lines) provides significant value. Clear workflows, error handling, and examples help Claude understand when and how to use skills effectively.

---
## Active Improvements

- Need to fix `issue-executor/run.sh` syntax error (line 47)
- Continue restructuring remaining 6 skills following doc-indexer pattern
- Validate restructured skills with new validation script (task #52)
- Keep RETROSPECTIVE.md under 100 lines by compressing older content as needed
