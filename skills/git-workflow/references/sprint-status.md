# Sprint Status Command

Provide sprint progress visibility, analytics, and burndown metrics.

## Purpose

Generate comprehensive sprint status reports including progress, velocity, blocked issues, and predictions. Helps teams understand current state and make informed decisions.

## When to Use

- Daily standup preparation
- Sprint planning meetings
- Progress check-ins
- Identifying blockers
- Velocity tracking
- Sprint retrospectives

## Workflow

### 1. Identify Current Sprint

```bash
echo "=== Current Sprint Detection ==="

# Get all open milestones
OPEN_MILESTONES=$(gh api repos/:owner/:repo/milestones \
  --jq '.[] | select(.state == "open") | {number, title, dueOn}' | jq -s 'sort_by(.dueOn)')

# Show active sprints
echo "$OPEN_MILESTONES" | jq -r '.[] | "\(.title) (Due: \(.dueOn))"'

# Detect current sprint (earliest due date)
CURRENT_MILESTONE=$(echo "$OPEN_MILESTONES" | jq -r '.[0].title')
CURRENT_MILESTONE_NUM=$(echo "$OPEN_MILESTONES" | jq -r '.[0].number')
DUE_DATE=$(echo "$OPEN_MILESTONES" | jq -r '.[0].dueOn' | cut -d'T' -f1)

echo ""
echo "Current Sprint: $CURRENT_MILESTONE"
echo "Due: $DUE_DATE"
```

### 2. Get All Sprint Issues

```bash
echo ""
echo "=== Fetching Sprint Issues ==="

# Get all issues in current milestone
SPRINT_ISSUES=$(gh issue list \
  --milestone "$CURRENT_MILESTONE" \
  --state all \
  --json number,title,state,labels,assignees,createdAt,closedAt,url \
  --limit 100)

TOTAL_ISSUES=$(echo "$SPRINT_ISSUES" | jq 'length')
echo "Total issues: $TOTAL_ISSUES"
```

### 3. Categorize Issues by State

```bash
# Count by state
COMPLETED=$(echo "$SPRINT_ISSUES" | jq '[.[] | select(.state == "CLOSED")] | length')
OPEN=$(echo "$SPRINT_ISSUES" | jq '[.[] | select(.state == "OPEN")] | length')

# Further categorize open issues
IN_PROGRESS=$(gh issue list --milestone "$CURRENT_MILESTONE" --state open --label "in-progress" --json number | jq 'length')
IN_REVIEW=$(gh pr list --search "milestone:\"$CURRENT_MILESTONE\"" --state open --json number | jq 'length')
READY=$((OPEN - IN_PROGRESS - IN_REVIEW))

echo ""
echo "=== Issue Status ==="
echo "Completed: $COMPLETED"
echo "In Review: $IN_REVIEW"
echo "In Progress: $IN_PROGRESS"
echo "Ready: $READY"
echo "Total: $TOTAL_ISSUES"
```

### 4. Calculate Progress Percentage

```bash
PROGRESS_PCT=0
if [ $TOTAL_ISSUES -gt 0 ]; then
  PROGRESS_PCT=$((COMPLETED * 100 / TOTAL_ISSUES))
fi

echo ""
echo "=== Progress ==="
echo "$COMPLETED / $TOTAL_ISSUES ($PROGRESS_PCT%)"

# Progress bar
BAR_LENGTH=20
FILLED=$((PROGRESS_PCT * BAR_LENGTH / 100))
EMPTY=$((BAR_LENGTH - FILLED))

printf "["
printf "█%.0s" $(seq 1 $FILLED)
printf "░%.0s" $(seq 1 $EMPTY)
printf "] $PROGRESS_PCT%%\n"
```

### 5. Analyze by Priority

```bash
echo ""
echo "=== Priority Breakdown ==="

for PRIORITY in P0 P1 P2 P3; do
  PRIORITY_ISSUES=$(echo "$SPRINT_ISSUES" | jq "[.[] | select(.labels[].name | contains(\"priority:$PRIORITY\"))]")
  PRIORITY_TOTAL=$(echo "$PRIORITY_ISSUES" | jq 'length')
  PRIORITY_DONE=$(echo "$PRIORITY_ISSUES" | jq '[.[] | select(.state == "CLOSED")] | length')

  if [ $PRIORITY_TOTAL -gt 0 ]; then
    PRIORITY_PCT=$((PRIORITY_DONE * 100 / PRIORITY_TOTAL))
    echo "$PRIORITY: $PRIORITY_DONE/$PRIORITY_TOTAL ($PRIORITY_PCT%)"
  fi
done
```

### 6. Identify Blocked Issues

```bash
echo ""
echo "=== Blocked Issues ==="

# Find issues with "blocked" label or dependency mentions
BLOCKED_ISSUES=$(gh issue list \
  --milestone "$CURRENT_MILESTONE" \
  --state open \
  --label "blocked" \
  --json number,title)

BLOCKED_COUNT=$(echo "$BLOCKED_ISSUES" | jq 'length')

if [ $BLOCKED_COUNT -gt 0 ]; then
  echo "⚠ $BLOCKED_COUNT issue(s) blocked:"
  echo "$BLOCKED_ISSUES" | jq -r '.[] | "  #\(.number) - \(.title)"'
else
  echo "✓ No blocked issues"
fi

# Check for dependency blockers in issue bodies
echo ""
echo "Checking for dependency issues..."
gh issue list --milestone "$CURRENT_MILESTONE" --state open --json number,body | \
  jq -r '.[] | select(.body | test("blocked by|depends on"; "i")) | .number' | \
  while read ISSUE_NUM; do
    echo "  ⚠ #$ISSUE_NUM may have dependencies (check issue body)"
  done
```

### 7. Calculate Velocity

```bash
echo ""
echo "=== Velocity Analysis ==="

# Calculate days into sprint
MILESTONE_CREATED=$(gh api repos/:owner/:repo/milestones/$CURRENT_MILESTONE_NUM --jq .created_at | cut -d'T' -f1)
DAYS_ELAPSED=$(( ($(date +%s) - $(date -d "$MILESTONE_CREATED" +%s)) / 86400 ))
DAYS_TOTAL=$(( ($(date -d "$DUE_DATE" +%s) - $(date -d "$MILESTONE_CREATED" +%s)) / 86400 ))
DAYS_REMAINING=$((DAYS_TOTAL - DAYS_ELAPSED))

echo "Sprint duration: $DAYS_TOTAL days"
echo "Days elapsed: $DAYS_ELAPSED"
echo "Days remaining: $DAYS_REMAINING"

# Calculate velocity (issues per day)
if [ $DAYS_ELAPSED -gt 0 ]; then
  VELOCITY=$(echo "scale=2; $COMPLETED / $DAYS_ELAPSED" | bc)
  echo "Current velocity: $VELOCITY issues/day"

  # Project completion
  REMAINING_ISSUES=$((TOTAL_ISSUES - COMPLETED))
  if [ $(echo "$VELOCITY > 0" | bc) -eq 1 ]; then
    DAYS_TO_COMPLETE=$(echo "scale=0; $REMAINING_ISSUES / $VELOCITY" | bc)
    PROJECTED_DATE=$(date -d "+$DAYS_TO_COMPLETE days" +%Y-%m-%d)

    echo "Projected completion: $PROJECTED_DATE"

    if [ $DAYS_TO_COMPLETE -gt $DAYS_REMAINING ]; then
      echo "⚠ Warning: May not complete by due date"
      echo "  Recommendation: Consider scope reduction or deadline extension"
    else
      echo "✓ On track to complete by due date"
    fi
  fi
fi
```

### 8. Burndown Chart Data

```bash
echo ""
echo "=== Burndown Chart ==="

# Get daily completion data
echo "Date,Completed,Remaining"
for DAY in $(seq 0 $DAYS_ELAPSED); do
  CHECK_DATE=$(date -d "$MILESTONE_CREATED +$DAY days" +%Y-%m-%d)
  COMPLETED_BY_DATE=$(echo "$SPRINT_ISSUES" | jq "[.[] | select(.closedAt and (.closedAt | split(\"T\")[0]) <= \"$CHECK_DATE\")] | length")
  REMAINING=$((TOTAL_ISSUES - COMPLETED_BY_DATE))
  echo "$CHECK_DATE,$COMPLETED_BY_DATE,$REMAINING"
done
```

### 9. Team Member Workload

```bash
echo ""
echo "=== Team Workload ==="

# Get unique assignees
ASSIGNEES=$(echo "$SPRINT_ISSUES" | jq -r '.[].assignees[].login' | sort -u)

for ASSIGNEE in $ASSIGNEES; do
  ASSIGNEE_ISSUES=$(echo "$SPRINT_ISSUES" | jq "[.[] | select(.assignees[].login == \"$ASSIGNEE\")]")
  ASSIGNEE_TOTAL=$(echo "$ASSIGNEE_ISSUES" | jq 'length')
  ASSIGNEE_DONE=$(echo "$ASSIGNEE_ISSUES" | jq '[.[] | select(.state == "CLOSED")] | length')
  ASSIGNEE_OPEN=$((ASSIGNEE_TOTAL - ASSIGNEE_DONE))

  if [ $ASSIGNEE_TOTAL -gt 0 ]; then
    ASSIGNEE_PCT=$((ASSIGNEE_DONE * 100 / ASSIGNEE_TOTAL))
    echo "@$ASSIGNEE: $ASSIGNEE_DONE/$ASSIGNEE_TOTAL ($ASSIGNEE_PCT%) - $ASSIGNEE_OPEN open"
  fi
done
```

### 10. Upcoming Deadlines

```bash
echo ""
echo "=== Upcoming Deadlines ==="

# Issues with due dates in next 3 days
TODAY=$(date +%Y-%m-%d)
THREE_DAYS=$(date -d "+3 days" +%Y-%m-%d)

gh issue list \
  --milestone "$CURRENT_MILESTONE" \
  --state open \
  --json number,title,labels | \
  jq -r '.[] | select(.labels[].name | startswith("due:")) | "#\(.number) - \(.title) - \(.labels[] | select(.name | startswith("due:")) | .name)"'
```

### 11. Pull Request Status

```bash
echo ""
echo "=== Pull Request Status ==="

# Get all PRs in sprint
SPRINT_PRS=$(gh pr list --search "milestone:\"$CURRENT_MILESTONE\"" --state all --json number,title,state,isDraft,reviewDecision)

PR_OPEN=$(echo "$SPRINT_PRS" | jq '[.[] | select(.state == "OPEN")] | length')
PR_MERGED=$(echo "$SPRINT_PRS" | jq '[.[] | select(.state == "MERGED")] | length')
PR_DRAFT=$(echo "$SPRINT_PRS" | jq '[.[] | select(.isDraft == true)] | length')
PR_NEEDS_REVIEW=$(echo "$SPRINT_PRS" | jq '[.[] | select(.state == "OPEN" and .reviewDecision == null and .isDraft == false)] | length')
PR_APPROVED=$(echo "$SPRINT_PRS" | jq '[.[] | select(.reviewDecision == "APPROVED")] | length')
PR_CHANGES=$(echo "$SPRINT_PRS" | jq '[.[] | select(.reviewDecision == "CHANGES_REQUESTED")] | length')

echo "Total PRs: $(echo "$SPRINT_PRS" | jq 'length')"
echo "  Open: $PR_OPEN (Draft: $PR_DRAFT)"
echo "  Needs Review: $PR_NEEDS_REVIEW"
echo "  Approved: $PR_APPROVED"
echo "  Changes Requested: $PR_CHANGES"
echo "  Merged: $PR_MERGED"

if [ $PR_NEEDS_REVIEW -gt 0 ]; then
  echo ""
  echo "PRs awaiting review:"
  echo "$SPRINT_PRS" | jq -r '.[] | select(.state == "OPEN" and .reviewDecision == null and .isDraft == false) | "  #\(.number) - \(.title)"'
fi
```

### 12. Spec Coverage Analysis

```bash
echo ""
echo "=== Spec Coverage ==="

# Check which specs are affected by sprint issues
AFFECTED_SPECS=$(gh issue list --milestone "$CURRENT_MILESTONE" --state all --json body | \
  jq -r '.[].body' | \
  rg "docs/specs/([^/]+)" -o -r '$1' | \
  sort -u)

if [ -n "$AFFECTED_SPECS" ]; then
  echo "Specs touched in this sprint:"
  for SPEC in $AFFECTED_SPECS; do
    SPEC_ISSUES=$(gh issue list --milestone "$CURRENT_MILESTONE" --search "$SPEC in:body" --json number,state)
    SPEC_TOTAL=$(echo "$SPEC_ISSUES" | jq 'length')
    SPEC_DONE=$(echo "$SPEC_ISSUES" | jq '[.[] | select(.state == "CLOSED")] | length')
    echo "  - $SPEC: $SPEC_DONE/$SPEC_TOTAL complete"
  done
else
  echo "No spec references found in issues"
fi
```

### 13. Risk Assessment

```bash
echo ""
echo "=== Risk Assessment ==="

RISKS=()

# Check if behind schedule
if [ $DAYS_TO_COMPLETE -gt $DAYS_REMAINING ]; then
  RISKS+=("⚠ Behind schedule - may miss deadline")
fi

# Check for many blocked issues
if [ $BLOCKED_COUNT -gt 2 ]; then
  RISKS+=("⚠ High number of blocked issues ($BLOCKED_COUNT)")
fi

# Check for low velocity
if [ $(echo "$VELOCITY < 0.5" | bc) -eq 1 ]; then
  RISKS+=("⚠ Low velocity ($VELOCITY issues/day)")
fi

# Check for PRs needing review
if [ $PR_NEEDS_REVIEW -gt 3 ]; then
  RISKS+=("⚠ Many PRs awaiting review ($PR_NEEDS_REVIEW)")
fi

# Check for uneven workload
MAX_WORKLOAD=$(echo "$SPRINT_ISSUES" | jq 'group_by(.assignees[].login) | map(length) | max')
if [ $MAX_WORKLOAD -gt 5 ]; then
  RISKS+=("⚠ Uneven workload distribution (max $MAX_WORKLOAD per person)")
fi

if [ ${#RISKS[@]} -gt 0 ]; then
  for RISK in "${RISKS[@]}"; do
    echo "  $RISK"
  done
else
  echo "✓ No significant risks identified"
fi
```

### 14. Recommendations

```bash
echo ""
echo "=== Recommendations ==="

RECOMMENDATIONS=()

# Velocity recommendations
if [ $(echo "$VELOCITY < 0.5" | bc) -eq 1 ]; then
  RECOMMENDATIONS+=("• Consider pair programming to increase velocity")
  RECOMMENDATIONS+=("• Review and remove blockers")
fi

# Review recommendations
if [ $PR_NEEDS_REVIEW -gt 2 ]; then
  RECOMMENDATIONS+=("• Schedule dedicated code review session")
  RECOMMENDATIONS+=("• Assign specific reviewers to pending PRs")
fi

# Blocked issue recommendations
if [ $BLOCKED_COUNT -gt 0 ]; then
  RECOMMENDATIONS+=("• Address blocked issues in daily standup")
  RECOMMENDATIONS+=("• Consider de-prioritizing blocked work")
fi

# Deadline recommendations
if [ $DAYS_TO_COMPLETE -gt $DAYS_REMAINING ]; then
  RECOMMENDATIONS+=("• Reduce scope by deferring P3 issues")
  RECOMMENDATIONS+=("• Request deadline extension")
  RECOMMENDATIONS+=("• Add team capacity if possible")
fi

# PR recommendations
if [ $PR_CHANGES -gt 0 ]; then
  RECOMMENDATIONS+=("• Prioritize addressing change requests on $PR_CHANGES PR(s)")
fi

if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
  for REC in "${RECOMMENDATIONS[@]}"; do
    echo "  $REC"
  done
else
  echo "✓ Sprint is on track, keep up the good work!"
fi
```

### 15. Update TODO.md with Status

Add sprint status summary to TODO.md:

```markdown
## Sprint S2 – Core Curriculum & Content Management

**Status**: In Progress (60% complete)
**Due**: 2025-11-04 (12 days remaining)
**Velocity**: 0.75 issues/day
**Projected Completion**: 2025-11-02 ✅

**Progress**: 3/5 issues
  - Completed: 3
  - In Review: 1
  - In Progress: 0
  - Ready: 1

**Risks**:
  - None identified ✓

**Last Updated**: 2025-10-22
```

### 16. Generate Sprint Report

Create comprehensive report:

```
================================================================================
                    SPRINT STATUS REPORT
================================================================================

Sprint: S2 – Core Curriculum & Content Management
Due: 2025-11-04
Days Remaining: 12

PROGRESS
--------
Completed: 3/5 (60%)
[████████████████░░░░] 60%

In Review: 1
In Progress: 0
Ready: 1

VELOCITY
--------
Current: 0.75 issues/day
Projected Completion: 2025-11-02
Status: ✓ On track

PRIORITY BREAKDOWN
------------------
P0: 0/0 (N/A)
P1: 2/3 (67%)
P2: 1/2 (50%)
P3: 0/0 (N/A)

PULL REQUESTS
-------------
Total: 4
Merged: 3
Open: 1
Needs Review: 0
Changes Requested: 0

BLOCKERS
--------
✓ No blocked issues

TEAM WORKLOAD
-------------
@alice: 2/3 (67%) - 1 open
@bob: 1/2 (50%) - 1 open

RISKS
-----
✓ No significant risks identified

RECOMMENDATIONS
---------------
✓ Sprint is on track, keep up the good work!

================================================================================
Report Generated: 2025-10-22
================================================================================
```

## Report Formats

### Daily Standup Format

```
Sprint S2 - Day 5 of 14

Yesterday:
  ✓ Completed #201 (Curriculum Framework)

Today:
  🔄 In Review: #202 (Lesson Player)

Blockers:
  None

Progress: 60% (on track)
```

### Weekly Summary Format

```
Sprint S2 - Week 1 Summary

Completed: 3 issues
Velocity: 0.6 issues/day

Key Achievements:
  - Curriculum Framework ✅
  - User Auth ✅
  - Database Setup ✅

Next Week Focus:
  - Lesson Player (in review)
  - Virtual Laboratory (ready to start)

Risks: None
```

### Executive Summary Format

```
Sprint S2 Progress

Status: 🟢 On Track
Completion: 60% (3/5 issues)
Due: Nov 4 (12 days)

Highlights:
  • Core curriculum framework implemented
  • All P1 items progressing
  • No blockers

Forecast: Will complete on time
```

## Advanced Analytics

### Cycle Time Analysis

```bash
# Calculate average time from start to completion
echo "=== Cycle Time Analysis ==="

CLOSED_ISSUES=$(echo "$SPRINT_ISSUES" | jq '[.[] | select(.state == "CLOSED")]')

CYCLE_TIMES=$(echo "$CLOSED_ISSUES" | jq -r '.[] |
  (((.closedAt | fromdateiso8601) - (.createdAt | fromdateiso8601)) / 86400) | floor')

AVG_CYCLE_TIME=$(echo "$CYCLE_TIMES" | jq -s 'add / length')

echo "Average cycle time: $AVG_CYCLE_TIME days"
```

### Lead Time Analysis

```bash
# Time from issue creation to PR merge
echo "=== Lead Time Analysis ==="

# Calculate time from creation to completion for closed issues
# Similar to cycle time but may include queue time
```

## File Update Patterns

### TODO.md Sprint Summary

```markdown
## Sprint S2 – Core Curriculum & Content Management

**Status**: 🟢 In Progress (60% complete)
**Timeline**: Oct 21 - Nov 4, 2025 (12 days remaining)
**Velocity**: 0.75 issues/day (on track)

**Progress**: 3/5 issues [████████████░░░░] 60%

**Breakdown**:
  - ✅ Completed: 3
  - 🔄 In Review: 1
  - 🚧 In Progress: 0
  - 📋 Ready: 1
  - 🚫 Blocked: 0

**Last Updated**: 2025-10-22
```

## Notes

- Run daily for standup preparation
- Weekly for planning meetings
- Use metrics to identify trends
- Track velocity over multiple sprints
- Adjust projections based on actuals
- Communicate risks early
- Celebrate achievements
- Use data to improve processes
