# PRD Authoring Examples

This directory contains comprehensive examples demonstrating the complete PRD authoring workflow for the payment gateway integration project.

## Example Files

### 1. Product Brief (`01-product-brief-example.md`)
A complete product brief for a payment gateway integration project showing:
- Clear problem statement with quantified business impact
- Well-defined user personas (primary and secondary)
- Specific value propositions for users and business
- Measurable success metrics (SMART criteria)

**Key Takeaways**:
- Problem statement includes who, what, frequency, and business impact
- Success metrics are specific numbers with baselines and targets
- Value propositions tied to concrete outcomes ($1.8M revenue recovery)

### 2. Research Document (`02-research-example.md`)
Comprehensive market research supporting the PRD, including:
- Competitive analysis of 3 major providers (Stripe, PayPal, Square)
- Market size, growth trends, and regulatory landscape
- User feedback analysis with pain points and desired features
- Technical considerations and risk assessment

**Key Takeaways**:
- Each competitor analyzed for strengths, weaknesses, features, pricing
- Research findings directly inform PRD recommendations
- Technical risks identified early with mitigation strategies
- Clear recommendation: Use Stripe for best developer experience

### 3. PRD - Abbreviated Version (`03-prd-example-abbreviated.md`)
A condensed but complete PRD showing:
- 3 SMART primary objectives linked to business outcomes
- Comprehensive success criteria (launch, metrics, stretch goals)
- 5 detailed functional requirements with acceptance criteria
- 4 non-functional requirements (performance, security, reliability, usability)
- Constraints, assumptions, and explicit out-of-scope items

**Key Takeaways**:
- Each requirement has description, user story, inputs, outputs, acceptance criteria, priority
- Non-functional requirements are measurable (99.9% uptime, <3s response time)
- Out of scope clearly defines what will NOT be built to prevent scope creep
- Full traceability from requirements back to objectives

### 4. Workflow Test Log (`workflow-test-log.md`)
Complete test results showing:
- Happy path: Full workflow from status → brief → research → PRD → validate → decompose → generate-spec
- Edge cases: 10 error scenarios tested (missing files, duplicates, invalid input)
- Validation quality: Tests for vague language, unmeasurable criteria, missing sections
- All tests passed with proper error handling

**Key Takeaways**:
- All 7 commands work correctly
- Error messages are clear and actionable
- Validation accurately detects quality issues
- Workflow maintains traceability throughout

## Using These Examples

### For Learning
1. Start with `01-product-brief-example.md` to see a well-formed brief
2. Read `02-research-example.md` to understand depth of research needed
3. Study `03-prd-example-abbreviated.md` for PRD structure and completeness
4. Review `workflow-test-log.md` to understand the complete workflow

### For Your Own Projects
1. Use these as templates, but customize for your specific context
2. Note the level of detail and specificity required
3. Pay attention to how requirements link back to objectives
4. Observe how assumptions and constraints are documented

### For Testing
1. Set up a test environment: `mkdir -p /tmp/test-prd && cd /tmp/test-prd && mkdir -p docs/prds`
2. Copy an example to test with: `cp 01-product-brief-example.md /tmp/test-prd/docs/prds/test-project/product-brief.md`
3. Run commands to test workflow

## Example Project: Payment Gateway Integration

This example represents a realistic e-commerce payment integration project with:

**Problem**: 45% cart abandonment due to manual invoice process
**Solution**: Integrate Stripe for real-time online payments
**Value**: Recover $1.8M in lost revenue, save $100K in operational costs
**Scope**: Credit card processing, digital wallets, saved payment methods, CRM/accounting integration
**Timeline**: 6 months to launch (Q2 2026)

### Project Statistics
- **Transaction Volume**: 1,000/month current → 5,000/month target
- **Team Size**: 2 frontend, 1 backend, 1 QA engineer
- **Budget**: $150K (development + first year fees)
- **Expected ROI**: $1.8M revenue recovery + $100K cost savings = 12x ROI

### Requirements Breakdown
- **Functional Requirements**: 5 detailed (FR1-FR5)
  - Payment processing
  - Digital wallets
  - Saved payment methods
  - CRM integration
  - Accounting integration

- **Non-Functional Requirements**: 4 categories
  - Performance (<3s payment processing)
  - Security (PCI DSS compliance)
  - Reliability (99.9% uptime)
  - Usability (WCAG 2.1 AA)

### Epic Decomposition (Not Shown but Tested)
The PRD would decompose into 4-5 epics:
1. Payment Processing Core (Stripe integration, card payments)
2. Payment Methods (Apple Pay, Google Pay, saved methods)
3. CRM & Accounting Integration
4. Security & Compliance (PCI, fraud detection)

Each epic would then become a spec using the spec-authoring workflow.

## Common Patterns Demonstrated

### Problem Statements
Format: What problem + Who experiences + Frequency + Business impact

Example:
> "Our e-commerce platform lacks payment processing, forcing customers through manual invoices. This affects 100% of transactions (1,000/month), causing 45% cart abandonment and $2.4M lost revenue annually."

### Success Metrics
Format: Metric name: Baseline → Target within Timeframe

Example:
> "Checkout conversion rate: 55% → 75% within 30 days post-launch"

### Functional Requirements
Format: Description + User Story + Inputs + Outputs + Business Rules + Acceptance Criteria + Priority + Dependencies

Example FR1 shows complete structure for payment processing requirement.

### Acceptance Criteria
Format: Given [precondition], when [action], then [expected result]

Example:
> "Given valid card details, when customer submits payment, then transaction processes in <3 seconds"

## Tips from These Examples

1. **Be Specific**: Notice how every metric has a number, every timeline has a date
2. **Show Impact**: Every feature ties back to business value (revenue, cost, satisfaction)
3. **Link Everything**: Requirements → Objectives → Business goals (traceability)
4. **Set Boundaries**: Out of scope is as important as in scope
5. **Document Assumptions**: Make implicit assumptions explicit
6. **Measure Quality**: Use validate-prd to catch vague language early

## Next Steps

After reviewing these examples:
1. Create your own project brief using the `brief` command
2. Conduct research for your specific domain
3. Write your PRD referencing these examples for structure
4. Validate early and often using `validate-prd`
5. Decompose into epics when PRD is complete
6. Transition to spec-authoring for implementation

## Questions?

- Refer to SKILL.md for detailed command documentation
- Review workflow-test-log.md for edge cases and error handling
- Compare your work to these examples for quality benchmarking
