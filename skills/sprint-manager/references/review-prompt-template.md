# Code Review Prompt Template (Codex MCP)

Use this template when calling Codex MCP to review a pull request.

## Basic Review Template

```markdown
Review PR #<PR_NUMBER>: <PR_TITLE>
URL: <PR_URL>

The PR implements:
<bullet list of what the PR does>

Focus your review on:
<specific areas of concern based on the PR type>

If everything looks good, say "APPROVED". If there are issues, list them with severity (critical/major/minor).
```

## Review Focus by PR Type

### Schema/Type Changes
```markdown
Focus your review on:
- Schema design correctness
- TypeScript type inference quality
- Validation logic completeness
- Forward/backward compatibility
- JSDoc documentation quality
```

### React Components
```markdown
Focus your review on:
- React component patterns and hooks usage
- Error boundary implementation
- Accessibility (keyboard nav, ARIA, alt text)
- Responsive design considerations
- TypeScript type safety
- Test coverage quality
```

### API Routes
```markdown
Focus your review on:
- Authentication and authorization checks
- Input validation and sanitization
- Error handling and response codes
- Database query efficiency
- TypeScript type safety
- Security considerations (injection, OWASP)
```

### Database/Schema Changes
```markdown
Focus your review on:
- Migration safety (can it be rolled back?)
- Index implications for query performance
- Data integrity constraints
- Backward compatibility with existing data
- Required environment/deployment steps
```

### Integration Changes
```markdown
Focus your review on:
- Hydration handling (server/client consistency)
- Feature flag implementation correctness
- Backward compatibility
- Error boundaries and fallbacks
- Loading and skeleton states
```

## Re-Review Template (After Fixes)

```markdown
Re-review PR #<PR_NUMBER> after fixes were applied:

<list of fixes made>

Verify the fixes address all previous concerns. Say "APPROVED" if ready to merge.
```

## Handling Review Results

### If APPROVED
```bash
gh pr merge <PR_NUMBER> --squash --auto
```

### If Issues Found

1. Parse the issues by severity
2. For critical/major issues: Launch fix subagent
3. For minor issues: Consider accepting with follow-up task
4. Re-review after fixes

### Fix Subagent Prompt

```markdown
## Task: Fix Code Review Issues for PR #<PR_NUMBER>

Working in `<WORKING_DIRECTORY>` on branch `<BRANCH_NAME>`.

### Issues to Fix

**1. <SEVERITY> - <Issue title>** (<file:lines>)
<Problem description>

**Fix**: <Specific fix instructions>

... (repeat for each issue)

### Steps
1. Pull latest from branch
2. Fix all issues in the component files
3. Add tests if needed
4. Run `npm run lint`
5. Run tests to verify all pass
6. Commit: `fix: address code review feedback (#<ISSUE_NUMBER>)`
7. Push to branch

### Report Back
- Confirmation that all issues are fixed
- Test results
- Any additional issues found
```

## Severity Guidelines

| Severity | Description | Action |
|----------|-------------|--------|
| Critical | Breaks functionality, security issue, data loss risk | Must fix before merge |
| High | Significant bug, missing error handling | Should fix before merge |
| Medium | Code quality, edge cases | Fix or create follow-up |
| Minor/Low | Style, optimization, nice-to-have | Accept with optional follow-up |

## Tips

1. **Be specific about focus areas** - Guide Codex to relevant concerns
2. **Include PR URL** - Helps Codex fetch the actual diff
3. **Summarize what PR does** - Provides context for the review
4. **Request severity levels** - Makes triage decisions clearer
5. **Re-review is cheaper** - Verify fixes rather than re-reviewing everything
