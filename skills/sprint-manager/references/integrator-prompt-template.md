# Integrator Subagent Prompt Template

Use this template when launching a subagent to perform post-merge integration tasks.

## Template

```markdown
## Task: Post-Merge Integration for PR #<PR_NUMBER>

Working directory: `<WORKING_DIRECTORY>`

PR #<PR_NUMBER> (Issue #<ISSUE_NUMBER>: <ISSUE_TITLE>) has been merged.

### Steps

1. Switch to main and pull:
```bash
git switch main && git pull --ff-only
```

2. Delete feature branch:
```bash
git push origin --delete <BRANCH_NAME> || echo "Already deleted"
git branch -D <BRANCH_NAME> || echo "Already deleted"
git remote prune origin
```

3. Update retrospective - append to `<RETROSPECTIVE_PATH>`:

```markdown

## PR #<PR_NUMBER> - <ISSUE_TITLE>

**Date**: <DATE>
**Issue**: #<ISSUE_NUMBER>
**Epic**: #<EPIC_NUMBER> - <EPIC_TITLE>

### What Went Well
- <key accomplishment 1>
- <key accomplishment 2>
- <key accomplishment 3>

### Lessons Learned
- <lesson 1>
- <lesson 2>

### Technical Notes
- <technical detail 1>
- <technical detail 2>
```

4. Commit and push:
```bash
git add docs/
git commit -m "docs: Add retrospective for PR #<PR_NUMBER>"
git push
```

5. Close issue (if not auto-closed):
```bash
gh issue close <ISSUE_NUMBER> --comment "Completed in PR #<PR_NUMBER>"
```

### Report Back
- Branch cleanup status
- Retrospective update status
- Issue close status
```

## Variables to Fill

| Variable | Description | Example |
|----------|-------------|---------|
| `<PR_NUMBER>` | Pull request number | `152` |
| `<ISSUE_NUMBER>` | GitHub issue number | `144` |
| `<ISSUE_TITLE>` | Issue title | `Design Lesson Content JSON Schema` |
| `<BRANCH_NAME>` | Feature branch to delete | `feat/144-design-lesson-content-json-schema` |
| `<WORKING_DIRECTORY>` | Absolute path to repo | `/home/user/project` |
| `<RETROSPECTIVE_PATH>` | Path to retrospective file | `docs/changes/retrospective.md` |
| `<DATE>` | Current date | `2025-11-22` |
| `<EPIC_NUMBER>` | Parent epic issue number | `143` |
| `<EPIC_TITLE>` | Parent epic title | `Rich Curriculum and Interactive Content` |

## Retrospective Content Guidelines

### What Went Well
Focus on:
- Clean implementation patterns discovered
- Good test coverage achieved
- Smooth integration with existing code
- Effective use of libraries/frameworks

### Lessons Learned
Focus on:
- Gotchas encountered and how they were resolved
- Patterns that didn't work initially
- Things to do differently next time
- Edge cases discovered during implementation

### Technical Notes
Include:
- Key file paths created/modified
- Dependencies added
- Schema changes made
- Configuration changes
- Breaking changes or migration notes

## Tips

1. **Use haiku model** - Integration tasks are straightforward, save tokens
2. **Check for auto-close** - Many PRs auto-close issues via "Closes #X" in PR body
3. **Create retrospective if missing** - First integration should create the file
4. **Keep retrospectives concise** - Focus on actionable learnings
