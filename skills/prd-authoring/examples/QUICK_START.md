# PRD Authoring - Quick Start Guide

## 5-Minute Overview

The PRD authoring skill guides you from vague project ideas to validated Product Requirements Documents ready for implementation.

**Workflow**: status → brief → research → create-prd → validate-prd → decompose → generate-spec

**Time Investment**: 18-36 hours of planning (saves weeks of rework later)

**Output**: Validated PRD with measurable objectives, testable requirements, and epic breakdown

## Prerequisites

```bash
# Ensure you have docs/prds directory
mkdir -p docs/prds

# Navigate to project root
cd /path/to/your/project
```

## Quick Workflow

### Step 1: Check Status (30 seconds)
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh status
```
**Output**: Shows what exists, recommends next step

### Step 2: Create Product Brief (2-4 hours)
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh brief "Your Project Name"
```
**Then**: Edit `docs/prds/your-project-name/product-brief.md`

**Fill in**:
- Problem statement (what, who, frequency, business impact)
- Target users (personas with goals and pain points)
- Proposed solution (what you'll build and why)
- Value proposition (user benefits, business benefits)
- Success metrics (baseline → target within timeframe)

**Example**: See `examples/01-product-brief-example.md`

### Step 3: Conduct Research (4-8 hours)
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh research your-project-name
```
**Then**: Edit `docs/prds/your-project-name/research.md`

**Research**:
- Competitive analysis (3-5 competitors)
- Market insights (size, growth, trends)
- User feedback (pain points, desired features)
- Technical considerations (approaches, risks)
- Recommendations (must-build, should-build, could-build)

**Example**: See `examples/02-research-example.md`

### Step 4: Create PRD (8-16 hours)
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh create-prd your-project-name
```
**Then**: Edit `docs/prds/your-project-name/prd.md`

**Define**:
- Objectives (SMART: Specific, Measurable, Achievable, Relevant, Time-bound)
- Success criteria (launch criteria, post-launch metrics)
- Functional requirements (FR1, FR2, etc. with acceptance criteria)
- Non-functional requirements (performance, security, reliability, usability)
- Constraints and assumptions
- Out of scope (what you won't build)

**Example**: See `examples/03-prd-example-abbreviated.md`

### Step 5: Validate PRD (iterative)
```bash
# Draft validation (lenient mode)
bash skills/prd-authoring/scripts/prd-authoring.sh validate-prd your-project-name --lenient

# Fix issues, then strict validation
bash skills/prd-authoring/scripts/prd-authoring.sh validate-prd your-project-name
```
**Goal**: "GOOD" or "EXCELLENT" rating with zero critical issues

**Common fixes**:
- Replace vague terms ("fast" → "<200ms at p95")
- Add measurable targets ("improve UX" → "task completion rate >85%")
- Add acceptance criteria to requirements

### Step 6: Decompose into Epics (4-8 hours)
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh decompose your-project-name
```
**Then**: Edit `docs/prds/your-project-name/epics.md`

**Break down**:
- Group requirements into 3-7 independently deliverable epics
- Map epic dependencies
- Ensure 100% requirements coverage
- Estimate effort (2-4 sprints per epic)

### Step 7: Generate Spec Proposals
```bash
bash skills/prd-authoring/scripts/prd-authoring.sh generate-spec your-project-name "Epic Name"
```
**Output**: Creates `docs/changes/epic-name/` with:
- `proposal.md` (epic scope and objectives)
- `spec-delta.md` (technical requirements)
- `tasks.md` (implementation breakdown)

**Then**: Transition to spec-authoring workflow for each epic

## Command Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `status` | Check project state | Start of session, after each step |
| `brief` | Create product brief | First step for new project |
| `research` | Create research doc | After brief is complete |
| `create-prd` | Create PRD template | After brief and research |
| `validate-prd` | Check PRD quality | After writing PRD, before decompose |
| `decompose` | Break into epics | After PRD validated |
| `generate-spec` | Create spec proposal | For each epic, transition to development |

## Common Patterns

### Problem Statement
```
[What problem] + [Who experiences] + [Frequency] + [Business impact]

Example: "Our e-commerce platform lacks payment processing, forcing
customers through manual invoices. This affects 100% of transactions
(1,000/month), causing 45% cart abandonment and $2.4M lost revenue annually."
```

### Success Metric
```
[Metric name]: [Baseline] → [Target] within [Timeframe]

Example: "Checkout conversion rate: 55% → 75% within 30 days post-launch"
```

### Functional Requirement
```markdown
### FR1: [Requirement Name]

**Description**: [What the system must do]

**User Story**: As a [user], I want [capability], so that [benefit]

**Acceptance Criteria**:
- [ ] Given [precondition], when [action], then [result]
- [ ] Given [precondition], when [action], then [result]
- [ ] Given [precondition], when [action], then [result]

**Priority**: Must Have / Should Have / Could Have

**Dependencies**: [Other requirements or systems]
```

## Troubleshooting Quick Fixes

### "docs/prds/ directory does not exist"
```bash
mkdir -p docs/prds
```

### "Product brief already exists"
```bash
# Check what exists
bash scripts/prd-authoring.sh status

# Edit existing or use different name
vim docs/prds/project-name/product-brief.md
```

### "Vague language detected"
Replace with specific metrics:
- "fast" → "<200ms at 95th percentile"
- "many users" → "10,000 concurrent users"
- "good UX" → "task completion rate >85%"

### "Success criteria may lack measurable targets"
Add numbers:
- Before: "Improve customer satisfaction"
- After: "Customer satisfaction: NPS 35 → 55 within 3 months"

## Tips for Success

### Do This ✓
- Run `status` frequently to track progress
- Be specific with numbers (avoid "fast", "good", "many")
- Link requirements back to objectives (traceability)
- Validate early and often (use lenient mode for drafts)
- Time-box research (4-8 hours max)
- Include out-of-scope to prevent scope creep

### Avoid This ✗
- Skipping research (leads to uninformed requirements)
- Vague requirements ("should be fast and secure")
- Unmeasurable success criteria ("improve user experience")
- Missing acceptance criteria (how do you test?)
- Over-engineering the PRD (done > perfect)
- Changing PRD endlessly (lock after 2-3 iterations)

## Example Project

**Payment Gateway Integration** (see `examples/` directory):
- **Problem**: 45% cart abandonment, $2.4M lost revenue
- **Solution**: Stripe integration for real-time payments
- **Value**: $1.8M revenue recovery + $100K cost savings
- **Timeline**: 18-36 hours planning, 6 months to launch
- **Outcome**: 5 functional requirements, 4 epics, validated PRD

## Next Steps

1. **Learn**: Read `examples/README.md` for detailed examples
2. **Practice**: Run workflow on test project
3. **Apply**: Create brief for your real project
4. **Validate**: Use validate-prd to check quality
5. **Iterate**: Refine based on feedback
6. **Deploy**: Transition to spec-authoring for implementation

## Need Help?

- **Examples**: See `skills/prd-authoring/examples/` directory
- **Troubleshooting**: See SKILL.md Troubleshooting section
- **Workflow Details**: See SKILL.md for command documentation
- **Test Results**: See `examples/workflow-test-log.md`

## Time Budget

| Activity | Time | Cumulative |
|----------|------|------------|
| Product Brief | 2-4 hours | 2-4 hours |
| Research | 4-8 hours | 6-12 hours |
| PRD Creation | 8-16 hours | 14-28 hours |
| Validation | 1-2 hours | 15-30 hours |
| Epic Decomposition | 4-8 hours | 19-38 hours |
| **Total Planning** | **18-36 hours** | |

**ROI**: 1 week of planning prevents 4-8 weeks of rework from unclear requirements

## Success Criteria

Your PRD is ready when:
- ✓ Validation passes with "GOOD" or "EXCELLENT"
- ✓ All objectives are SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
- ✓ Every requirement has acceptance criteria
- ✓ Success metrics have baseline → target → timeframe
- ✓ Stakeholders approve and understand what to build
- ✓ Team knows how to test each requirement

## Remember

> "Hours of planning save weeks of rework. A validated PRD is your blueprint for success."

Start with `status`, follow the workflow, validate often, and maintain traceability. Good luck!
