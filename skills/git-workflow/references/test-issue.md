# Test Issue Command

Run comprehensive testing for the current issue including linting, unit tests, integration tests, and e2e tests.

## Purpose

Validate implementation quality before creating a pull request. Ensures code meets quality standards, tests pass, and functionality works as specified.

## When to Use

- After completing implementation
- Before running `submit-issue`
- After making significant changes
- When PR has test failures
- As part of review feedback cycle

## Workflow

### 1. Check Current Branch and PR Status

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "⚠ Error: On main branch. Switch to feature branch first."
  exit 1
fi

echo "Testing branch: $CURRENT_BRANCH"

# Extract issue number
ISSUE_NUMBER=$(echo "$CURRENT_BRANCH" | sed -E 's/(feat|fix|chore|refactor)\/([0-9]+).*/\2/')

if [ -n "$ISSUE_NUMBER" ]; then
  echo "Issue: #$ISSUE_NUMBER"

  # Check if PR exists
  PR_STATUS=$(gh pr view --json state,reviewDecision,statusCheckRollup 2>/dev/null)

  if [ -n "$PR_STATUS" ]; then
    echo "PR Status:"
    echo "$PR_STATUS" | jq '{state, reviewDecision, checks: .statusCheckRollup}'
  else
    echo "No PR yet (will create after tests pass)"
  fi
fi
```

### 2. Run Linting

```bash
echo "=== Running Linter ==="
npm run lint

LINT_EXIT=$?
if [ $LINT_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Linting failed"
  echo ""
  echo "Fix linting errors before proceeding:"
  echo "  npm run lint -- --fix"
  echo ""
  exit 1
fi

echo "✓ Linting passed"
```

If linting fails, provide specific guidance:

```
❌ Linting failed with 5 errors:

src/auth/login.ts:15:3 - Unexpected var, use let or const instead
src/auth/login.ts:23:45 - Missing semicolon
src/components/Form.tsx:12:8 - 'React' is defined but never used

Quick fix:
  npm run lint -- --fix

Then run 'test-issue' again.
```

### 3. Run Unit Tests

```bash
echo ""
echo "=== Running Unit Tests ==="
npm run test -- --coverage

TEST_EXIT=$?
if [ $TEST_EXIT -ne 0 ]; then
  echo ""
  echo "❌ Unit tests failed"
  echo ""
  echo "Fix failing tests before proceeding."
  echo "Review test output above for details."
  echo ""
  exit 1
fi

# Extract coverage
COVERAGE=$(npm run test -- --coverage --silent | rg "All files.*?([0-9.]+)" -o -r '$1' | head -1)
echo "✓ Unit tests passed (Coverage: ${COVERAGE}%)"
```

If tests fail, analyze and provide context:

```
❌ Unit tests failed: 3 failures

Failed tests:
  1. src/auth/login.test.ts
     - "should validate email format"
     - Expected: true, Received: false
     - Likely cause: Email validation regex not matching spec

  2. src/auth/login.test.ts
     - "should hash passwords before storage"
     - TypeError: Cannot read property 'hash' of undefined
     - Likely cause: bcrypt not imported or initialized

  3. src/components/Form.test.tsx
     - "should render with initial values"
     - Component not found in render tree
     - Likely cause: Component name mismatch

Action required:
  1. Fix email validation in src/auth/login.ts:42
  2. Import bcrypt in src/auth/login.ts:1
  3. Check component export in src/components/Form.tsx:89

Run tests with verbose mode for more details:
  npm run test -- --verbose

After fixes, run 'test-issue' again.
```

### 4. Run Integration Tests

```bash
echo ""
echo "=== Running Integration Tests ==="

# Check if integration tests exist
if [ -f "package.json" ] && grep -q "test:integration" package.json; then
  npm run test:integration

  INTEGRATION_EXIT=$?
  if [ $INTEGRATION_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Integration tests failed"
    echo ""
    echo "Fix failing integration tests before proceeding."
    echo ""
    exit 1
  fi

  echo "✓ Integration tests passed"
else
  echo "ℹ No integration tests configured (skipping)"
fi
```

### 5. Run E2E Tests

```bash
echo ""
echo "=== Running E2E Tests ==="

# Check if e2e tests exist
if [ -f "package.json" ] && grep -q "test:e2e" package.json; then
  npm run test:e2e

  E2E_EXIT=$?
  if [ $E2E_EXIT -ne 0 ]; then
    echo ""
    echo "❌ E2E tests failed"
    echo ""
    echo "Fix failing E2E tests before proceeding."
    echo ""

    # If screenshots exist, mention them
    if [ -d "test-results" ] || [ -d "screenshots" ]; then
      echo "Check screenshots in test-results/ or screenshots/ for visual debugging."
    fi

    exit 1
  fi

  echo "✓ E2E tests passed"
else
  echo "ℹ No E2E tests configured (skipping)"
fi
```

### 6. Run Type Checking (if TypeScript)

```bash
echo ""
echo "=== Running Type Check ==="

if [ -f "tsconfig.json" ]; then
  npx tsc --noEmit

  TSC_EXIT=$?
  if [ $TSC_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Type checking failed"
    echo ""
    echo "Fix type errors before proceeding."
    echo ""
    exit 1
  fi

  echo "✓ Type checking passed"
else
  echo "ℹ Not a TypeScript project (skipping)"
fi
```

### 7. Run Build (if applicable)

```bash
echo ""
echo "=== Running Build ==="

if [ -f "package.json" ] && grep -q "\"build\"" package.json; then
  npm run build

  BUILD_EXIT=$?
  if [ $BUILD_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Build failed"
    echo ""
    echo "Fix build errors before proceeding."
    echo ""
    exit 1
  fi

  echo "✓ Build passed"
else
  echo "ℹ No build script configured (skipping)"
fi
```

### 8. Analyze Results

Provide comprehensive summary:

```bash
echo ""
echo "========================================="
echo "          TEST SUMMARY"
echo "========================================="
echo ""
echo "✓ Linting: PASSED"
echo "✓ Unit Tests: PASSED (Coverage: 92%)"
echo "✓ Integration Tests: PASSED"
echo "✓ E2E Tests: PASSED"
echo "✓ Type Check: PASSED"
echo "✓ Build: PASSED"
echo ""
echo "========================================="
echo "All tests passed! ✅"
echo "========================================="
echo ""
echo "Ready to submit PR. Run: submit-issue"
```

If any failures:

```bash
echo ""
echo "========================================="
echo "          TEST SUMMARY"
echo "========================================="
echo ""
echo "✓ Linting: PASSED"
echo "❌ Unit Tests: FAILED (3 failures)"
echo "⊘ Integration Tests: SKIPPED"
echo "⊘ E2E Tests: SKIPPED"
echo "✓ Type Check: PASSED"
echo "⊘ Build: SKIPPED"
echo ""
echo "========================================="
echo "Tests failed! ❌"
echo "========================================="
echo ""
echo "Fix failing tests before submitting PR."
echo "See detailed output above for specific failures."
```

### 9. Update TODO.md

Add test status to the issue entry:

```markdown
## In Progress

- [ ] #201 - Curriculum Framework (feat/201-curriculum-framework)
  - **Started**: 2025-10-21
  - **Branch**: feat/201-curriculum-framework
  - **Tests**: ✅ All Passed (Unit: 92%, Integration: ✅, E2E: ✅)
  - **Last Tested**: 2025-10-22
```

### 10. Update Sprint File

Add test results to sprint file:

```markdown
## Curriculum Framework

**Status**: In Progress - Testing Complete ✅
**Branch**: feat/201-curriculum-framework
**Started**: 2025-10-21
**Issue**: #201

**Test Results**:
- Linting: ✅ PASSED
- Unit Tests: ✅ PASSED (Coverage: 92%)
- Integration Tests: ✅ PASSED
- E2E Tests: ✅ PASSED
- Type Check: ✅ PASSED
- Build: ✅ PASSED
- **Last Tested**: 2025-10-22
```

### 11. Chrome DevTools Debugging (E2E Test Failures)

When E2E tests fail, use chrome-devtools-mcp tools for interactive debugging. This is more effective than analyzing test screenshots alone.

#### When to Use Chrome DevTools MCP

- E2E test failures that are hard to reproduce
- Element not found errors in tests
- Unexpected UI behavior
- Network/API issues during E2E tests
- Performance problems during user flows
- JavaScript errors affecting functionality

#### Basic Debugging Workflow

**1. Navigate to the failing page:**
```
navigate_page(url='http://localhost:3000/failing-feature')
```

**2. Take snapshot to see page state:**
```
take_snapshot()
```
This shows the accessibility tree with element uids - faster than screenshots and provides interaction handles.

**3. Check console for JavaScript errors:**
```
list_console_messages(types=['error', 'warn'])
```

**4. Inspect specific error:**
```
get_console_message(msgid=1)
```

**5. Check network requests:**
```
list_network_requests(resourceTypes=['fetch', 'xhr'])
```

**6. Get failed request details:**
```
get_network_request(reqid=1)
```

#### Common E2E Debugging Patterns

**Pattern 1: Element Not Found**
```
# Test says: "Button not found"

# Take snapshot to see what elements exist
take_snapshot()

# Output might show:
# [100] button "Save Draft"  (not "Submit" as test expects)

# Fix: Update test selector or check if element is conditionally rendered
```

**Pattern 2: Form Submission Fails**
```
# Navigate to form
navigate_page(url='http://localhost:3000/form')

# Take snapshot to discover form fields
take_snapshot()

# Fill form using discovered uids
fill(uid='50', value='test@example.com')
fill(uid='51', value='password123')

# Check console before submit
list_console_messages()

# Submit
click(uid='52')

# Check console after submit
list_console_messages(types=['error'])

# Check network requests
list_network_requests(resourceTypes=['fetch', 'xhr'])

# Analyze the POST request
get_network_request(reqid=1)
```

**Pattern 3: Navigation Timeout**
```
# Test times out waiting for page load

# Navigate and monitor
navigate_page(url='http://localhost:3000/slow-page', timeout=30000)

# Check console for errors
list_console_messages(types=['error'])

# Check network for stuck/failed requests
list_network_requests()

# Find the blocking request
get_network_request(reqid=5)  # Shows: 500 Internal Server Error
```

**Pattern 4: State Synchronization Issues**
```
# Test expects element to appear after action

# Take initial snapshot
navigate_page(url='http://localhost:3000/dashboard')
take_snapshot()

# Trigger action
click(uid='100')

# Wait for expected content
wait_for(text='Data loaded', timeout=5000)

# If wait_for fails, check what's actually happening:
take_snapshot()  # See current page state
list_console_messages()  # Check for JS errors
list_network_requests()  # Check if API call completed
```

**Pattern 5: Performance Issues**
```
# Test is slow or times out

# Start performance trace
performance_start_trace(reload=true, autoStop=true)

# Stop and analyze
performance_stop_trace()

# Output shows Core Web Vitals:
# - LCP: 4.5s (slow!)
# - FID: 250ms (slow!)

# Get detailed breakdown
performance_analyze_insight(insightName='LCPBreakdown')

# This reveals: Large image blocking render
```

#### Verifying Test Fixes

After fixing E2E tests, verify interactively:

```
# Navigate to the feature
navigate_page(url='http://localhost:3000/feature')

# Reproduce test steps manually
take_snapshot()
click(uid='100')
fill(uid='101', value='test data')
click(uid='102')

# Verify expected outcome
wait_for(text='Success')
take_screenshot(filePath='/tmp/verified.png')

# Confirm no errors
list_console_messages(types=['error'])
# Expected: No errors

# Confirm API calls succeeded
list_network_requests(resourceTypes=['fetch'])
# Expected: All 200 status codes
```

#### Multi-Page Testing

For tests involving multiple pages/tabs:

```
# List all open pages
list_pages()

# Create new page for comparison
new_page(url='http://localhost:3000/compare')

# Switch between pages
select_page(pageIdx=0)  # Original page
take_snapshot()

select_page(pageIdx=1)  # New page
take_snapshot()

# Close when done
close_page(pageIdx=1)
```

#### Network Condition Testing

Test behavior under poor network conditions:

```
# Simulate slow 3G
emulate_network(throttlingOption='Slow 3G')

# Navigate and test
navigate_page(url='http://localhost:3000')

# Check if loading states work properly
take_snapshot()  # Should show loading indicators

# Reset to normal
emulate_network(throttlingOption='No emulation')
```

#### JavaScript Execution for Test Setup

If you need to manipulate page state:

```
# Navigate to page
navigate_page(url='http://localhost:3000')

# Execute custom JS to set up test state
evaluate_script(function='() => { localStorage.setItem("testMode", "true"); location.reload(); }')

# Verify state
take_snapshot()
```

#### Best Practices for E2E Debugging

1. **Always snapshot first** - Faster and provides uids for interaction
2. **Check console immediately** - JavaScript errors often explain failures
3. **Inspect network activity** - API failures are common E2E issues
4. **Use wait_for instead of timeouts** - More reliable for dynamic content
5. **Verify element state** - Use verbose snapshot to see disabled/hidden states
6. **Test incrementally** - Reproduce test step-by-step to find exact failure point
7. **Clean up** - Close extra pages, reset network emulation when done

#### Tool Quick Reference

| Need | Tool |
|------|------|
| See page structure | `take_snapshot()` |
| Visual verification | `take_screenshot()` |
| JavaScript errors | `list_console_messages(types=['error'])` |
| Network issues | `list_network_requests()` |
| Slow performance | `performance_start_trace()` |
| Element interaction | `click(uid)`, `fill(uid, value)` |
| Wait for content | `wait_for(text='Expected')` |
| Run custom JS | `evaluate_script(function)` |

## Test Configuration

### Recommended package.json Scripts

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:integration": "jest --config jest.integration.config.js",
    "test:e2e": "playwright test",
    "type-check": "tsc --noEmit",
    "build": "next build"
  }
}
```

### Test Execution Order

Always run in this order:
1. **Linting** - Fast, catches syntax issues
2. **Type Check** - Fast, catches type errors
3. **Unit Tests** - Fast, tests isolated logic
4. **Integration Tests** - Medium, tests component integration
5. **E2E Tests** - Slow, tests full user flows
6. **Build** - Medium, validates production build

Stop at first failure to save time.

## Error Handling Patterns

### Linting Errors

```
⚠ Common linting issues:

1. Unused imports
   Fix: Remove or use the import

2. Missing semicolons
   Fix: npm run lint -- --fix

3. Wrong quotes (single vs double)
   Fix: npm run lint -- --fix

4. Trailing whitespace
   Fix: npm run lint -- --fix

For unfixable errors, manually address them based on output.
```

### Test Failures

```
⚠ Common test failure patterns:

1. Async timing issues
   - Use waitFor() or act()
   - Increase timeout if needed

2. Mock issues
   - Verify mocks are properly reset
   - Check mock return values match expectations

3. Environment issues
   - Check test database is seeded
   - Verify environment variables are set

4. Test isolation failures
   - Ensure tests clean up after themselves
   - Use beforeEach/afterEach properly
```

### Integration Test Failures

```
⚠ Common integration issues:

1. Database connection failures
   - Check database is running
   - Verify connection string

2. API endpoint errors
   - Check server is running
   - Verify routes are registered

3. Authentication issues
   - Verify test user credentials
   - Check token generation

4. Data fixture issues
   - Ensure fixtures are loaded
   - Check data matches schema
```

### E2E Test Failures

```
⚠ Common E2E issues:

1. Element not found
   - Check selectors match current DOM
   - Wait for element to appear

2. Navigation timeout
   - Increase timeout
   - Check URL is correct

3. State issues
   - Clear browser state between tests
   - Use isolated test users

4. Screenshot mismatches (visual regression)
   - Review diff images
   - Update baselines if intentional change
```

### Build Failures

```
⚠ Common build issues:

1. Missing dependencies
   - Run: npm install

2. Type errors not caught by editor
   - Fix types in source files
   - Update type definitions

3. Import path errors
   - Check import paths
   - Verify file exists

4. Environment variable issues
   - Create .env.production
   - Verify all required vars are set
```

## Test Coverage Requirements

Recommended coverage thresholds:

```json
{
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

If coverage is below threshold:

```
⚠ Code coverage below threshold

Current coverage: 75%
Required: 80%

Files with low coverage:
  - src/auth/login.ts (60%) - Missing error case tests
  - src/utils/validation.ts (55%) - Missing edge case tests

Add tests for:
  1. Error scenarios
  2. Edge cases
  3. Boundary conditions

Then run 'test-issue' again.
```

## Performance Testing (Optional)

For performance-critical changes:

```bash
echo ""
echo "=== Running Performance Tests ==="

if [ -f "package.json" ] && grep -q "test:performance" package.json; then
  npm run test:performance

  # Check if performance regression
  # Compare with baseline metrics
fi
```

## File Update Patterns

### TODO.md with Test Results

```markdown
## In Progress

- [ ] #201 - Curriculum Framework (feat/201-curriculum-framework)
  - **Started**: 2025-10-21
  - **Tests**: ✅ All Passed
    - Linting: ✅
    - Unit: ✅ (92%)
    - Integration: ✅
    - E2E: ✅
    - Build: ✅
  - **Last Tested**: 2025-10-22
  - **Ready for PR**: Yes
```

### Sprint File with Test Details

```markdown
## Curriculum Framework

**Status**: In Progress - Testing Complete ✅
**Branch**: feat/201-curriculum-framework
**Started**: 2025-10-21
**Issue**: #201

**Test Results** (2025-10-22):
| Test Type | Status | Details |
|-----------|--------|---------|
| Linting | ✅ | No issues |
| Unit Tests | ✅ | 92% coverage, 45 tests |
| Integration | ✅ | All API endpoints tested |
| E2E | ✅ | All user flows verified |
| Type Check | ✅ | No type errors |
| Build | ✅ | Production build successful |

**Ready for PR**: Yes
```

## Continuous Integration Alignment

Ensure local tests match CI pipeline:

```bash
# Run same tests as CI
echo "Running CI test suite locally..."

# Usually this matches:
npm run lint && \
npm run type-check && \
npm run test:coverage && \
npm run test:integration && \
npm run test:e2e && \
npm run build

if [ $? -eq 0 ]; then
  echo "✓ All CI checks would pass"
else
  echo "❌ CI checks would fail - fix before pushing"
fi
```

## Notes

- Run tests in the correct order (fast to slow)
- Stop at first failure to save time
- Update tracking files immediately after test completion
- Provide actionable feedback for failures
- Never proceed with PR if tests are failing
- Consider test coverage requirements
- Align local tests with CI pipeline
- Document test failures in sprint file for tracking
- Use screenshots/logs for debugging E2E failures
- Validate both happy path and error scenarios
