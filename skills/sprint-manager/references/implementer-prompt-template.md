# Implementer Subagent Prompt Template

Use this template when launching a subagent to implement a GitHub issue.

## Template

```markdown
## Task: Implement GitHub Issue #<ISSUE_NUMBER> - <ISSUE_TITLE>

You are working on branch `<BRANCH_NAME>` in `<WORKING_DIRECTORY>`.

### Issue Summary

<Brief description of what needs to be implemented>

### Implementation Plan

<Step-by-step implementation plan, either from Gemini CLI or manually constructed>

**Step 1: <First task>**
<Details>

**Step 2: <Second task>**
<Details>

... (continue for all steps)

### Existing Code Context

<Relevant files and their purposes>
- `<file_path>` - <description>
- `<file_path>` - <description>

### Schema/Type Definitions

<If relevant, include type definitions the subagent needs>

```typescript
// Example type context
interface ExampleType {
  field: string;
}
```

### Project Conventions

- TypeScript with 2-space indentation
- Use `@/` path alias for imports
- Conventional Commits: `feat:`, `fix:`, `chore:`
- Run `npm run lint` before committing
- Run `npm run test` to verify tests pass

### Test Requirements

<List specific tests to implement>
- Test: <description>
- Test: <description>

### Your Deliverables

1. Create/modify the necessary files
2. Implement all acceptance criteria
3. Write tests as specified
4. Run `npm run lint` - fix any errors
5. Run `npm run test` - ensure tests pass
6. Commit with message: `<type>: <description> (#<ISSUE_NUMBER>)`
7. Push: `git push -u origin <BRANCH_NAME>`
8. Create PR: `gh pr create --title "<PR_TITLE>" --body "..." --label "<labels>" --milestone "<MILESTONE>"`

### Report Back

When done, report:
1. PR URL
2. Test results summary (pass/fail count)
3. Files created/modified
4. Any issues encountered
```

## Variables to Fill

| Variable | Description | Example |
|----------|-------------|---------|
| `<ISSUE_NUMBER>` | GitHub issue number | `144` |
| `<ISSUE_TITLE>` | Issue title | `Design Lesson Content JSON Schema` |
| `<BRANCH_NAME>` | Feature branch name | `feat/144-design-lesson-content-json-schema` |
| `<WORKING_DIRECTORY>` | Absolute path to repo | `/home/user/project` |
| `<MILESTONE>` | Sprint milestone name | `Sprint 5: Rich Curriculum` |

## Subagent Type Selection

Choose the subagent type based on the issue:

| Issue Type | Subagent Type | Use When |
|------------|---------------|----------|
| API routes, backend | `backend-architect` | Database, APIs, server logic |
| React components, UI | `frontend-developer` | Components, styling, client-side |
| Database/schema | `backend-architect` | Prisma, migrations |
| Mixed/unclear | `general-purpose` | Multiple areas, small tasks |
| Quick fixes | `general-purpose` with `model: haiku` | Simple changes |

## Tips for Effective Prompts

1. **Be explicit about file paths** - Subagents don't have your context
2. **Include type definitions** - Copy relevant interfaces/types into the prompt
3. **Specify exact test cases** - Don't leave testing open-ended
4. **Provide fallback instructions** - What to do if a step fails
5. **Request specific output format** - Makes parsing the response easier
