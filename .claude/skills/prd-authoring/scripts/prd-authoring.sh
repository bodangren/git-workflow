#!/bin/bash
# This script manages the authoring of Product Requirements Documents (PRDs).

set -e

# --- UTILITY FUNCTIONS ---

function to_kebab_case() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

function get_date() {
    date +%Y-%m-%d
}

function check_prd_directory() {
    if [ ! -d "docs/prds" ]; then
        echo "Error: docs/prds/ directory does not exist." >&2
        echo "Please create it first: mkdir -p docs/prds" >&2
        exit 1
    fi
}

function check_project_exists() {
    local project_name=$1
    local project_dir="docs/prds/$project_name"

    if [ ! -d "$project_dir" ]; then
        echo "Error: Project directory '$project_dir' does not exist." >&2
        echo "Run 'brief' command first to create the project." >&2
        exit 1
    fi
}

function check_file_exists() {
    local file_path=$1
    local description=$2

    if [ ! -f "$file_path" ]; then
        echo "Error: $description not found at '$file_path'." >&2
        return 1
    fi
    return 0
}

# --- STATUS COMMAND ---

function status() {
    local project_name=$1
    check_prd_directory

    echo "=== PRD Status Report ==="
    echo ""

    # If no project name provided, list all projects
    if [ -z "$project_name" ]; then
        local projects=(docs/prds/*/)
        if [ ${#projects[@]} -eq 0 ] || [ ! -d "${projects[0]}" ]; then
            echo "No PRD projects found in docs/prds/"
            echo ""
            echo "Recommendation: Run 'brief' command to start a new project"
            echo "Next command: bash scripts/prd-authoring.sh brief \"Project Name\""
            return
        fi

        echo "Found projects:"
        for project_dir in "${projects[@]}"; do
            if [ -d "$project_dir" ]; then
                local proj_name=$(basename "$project_dir")
                echo "  - $proj_name"
            fi
        done
        echo ""
        echo "Run 'status <project-name>' to check specific project status"
        return
    fi

    local project_dir="docs/prds/$project_name"
    if [ ! -d "$project_dir" ]; then
        echo "Project: $project_name (NOT FOUND)"
        echo ""
        echo "Recommendation: Run 'brief' command to create this project"
        echo "Next command: bash scripts/prd-authoring.sh brief \"$project_name\""
        return
    fi

    echo "Project: $project_name"
    echo ""

    # Check product brief
    local brief_status="✗"
    local brief_complete="✗"
    if [ -f "$project_dir/product-brief.md" ]; then
        brief_status="✓"
        # Check for required sections
        if grep -q "## Problem Statement" "$project_dir/product-brief.md" && \
           grep -q "## Target Users" "$project_dir/product-brief.md" && \
           grep -q "## Success Metrics" "$project_dir/product-brief.md"; then
            brief_complete="✓"
        fi
    fi

    # Check research
    local research_status="✗"
    local research_complete="✗"
    if [ -f "$project_dir/research.md" ]; then
        research_status="✓"
        # Check for required sections
        if grep -q "## Competitive Analysis" "$project_dir/research.md" && \
           grep -q "## Recommendations" "$project_dir/research.md"; then
            research_complete="✓"
        fi
    fi

    # Check PRD
    local prd_status="✗"
    local prd_complete="✗"
    if [ -f "$project_dir/prd.md" ]; then
        prd_status="✓"
        # Check for required sections
        if grep -q "## Objectives" "$project_dir/prd.md" && \
           grep -q "## Success Criteria" "$project_dir/prd.md" && \
           grep -q "## Functional Requirements" "$project_dir/prd.md"; then
            prd_complete="✓"
        fi
    fi

    # Check epics
    local epics_status="✗"
    if [ -f "$project_dir/epics.md" ]; then
        epics_status="✓"
    fi

    # Determine status and recommendation
    local status_phase="Inception"
    local recommendation=""
    local next_command=""

    if [ "$epics_status" = "✓" ]; then
        status_phase="Ready for Development"
        recommendation="PRD decomposed into epics. Ready for spec-authoring workflow."
        next_command="Transition to spec-authoring for each epic"
    elif [ "$prd_complete" = "✓" ]; then
        status_phase="PRD Complete"
        recommendation="Run 'decompose' command to break PRD into epics"
        next_command="bash scripts/prd-authoring.sh decompose $project_name"
    elif [ "$prd_status" = "✓" ]; then
        status_phase="PRD Draft"
        recommendation="Complete PRD sections, then run 'validate-prd' command"
        next_command="bash scripts/prd-authoring.sh validate-prd $project_name"
    elif [ "$research_complete" = "✓" ] || [ "$research_status" = "✓" ]; then
        status_phase="Research Phase"
        recommendation="Run 'create-prd' command to create PRD from brief and research"
        next_command="bash scripts/prd-authoring.sh create-prd $project_name"
    elif [ "$brief_complete" = "✓" ]; then
        status_phase="Brief Complete"
        recommendation="Run 'research' command to conduct market analysis"
        next_command="bash scripts/prd-authoring.sh research $project_name"
    elif [ "$brief_status" = "✓" ]; then
        status_phase="Brief Draft"
        recommendation="Complete product brief sections"
        next_command="Edit docs/prds/$project_name/product-brief.md"
    fi

    echo "Status: $status_phase"
    echo "- $brief_status Product brief exists (docs/prds/$project_name/product-brief.md)"
    if [ "$brief_status" = "✓" ]; then
        echo "  - Brief completeness: $brief_complete"
    fi
    echo "- $research_status Research document exists (docs/prds/$project_name/research.md)"
    if [ "$research_status" = "✓" ]; then
        echo "  - Research completeness: $research_complete"
    fi
    echo "- $prd_status PRD exists (docs/prds/$project_name/prd.md)"
    if [ "$prd_status" = "✓" ]; then
        echo "  - PRD completeness: $prd_complete"
    fi
    echo "- $epics_status Epic decomposition exists (docs/prds/$project_name/epics.md)"
    echo ""
    echo "Recommendation: $recommendation"
    echo "Next command: $next_command"
}

# --- BRIEF COMMAND ---

function brief() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        echo "Error: Project name not provided for 'brief' command." >&2
        echo "Usage: $0 brief <project-name>" >&2
        exit 1
    fi

    check_prd_directory

    local dir_name=$(to_kebab_case "$project_name")
    local project_dir="docs/prds/$dir_name"
    local brief_file="$project_dir/product-brief.md"

    echo "Creating product brief: $project_name"

    if [ -d "$project_dir" ]; then
        echo "Warning: Project directory '$project_dir' already exists." >&2
        if [ -f "$brief_file" ]; then
            echo "Error: Product brief already exists at '$brief_file'." >&2
            exit 1
        fi
    fi

    mkdir -p "$project_dir"

    local today=$(get_date)

    local today=$(get_date)
    echo "Generating a draft product brief with Gemini..."

    local gemini_prompt="Generate a comprehensive and well-structured product brief for a new project called '${project_name}'.
The brief should be in markdown format and include the following sections:
- A YAML frontmatter with title, type (product-brief), status (draft), created, and updated fields.
- A main title: '# Product Brief: ${project_name}'
- ## Problem Statement: Articulate a specific, measurable, and customer-focused problem.
- ## Target Users: Define primary and secondary user personas.
- ## Proposed Solution: Give a high-level overview of the solution.
- ## Value Proposition: Detail user and business benefits.
- ## Success Metrics: Define specific, measurable, achievable, relevant, and time-bound (SMART) metrics for launch and long-term success.

Flesh out each section with plausible, high-quality example content appropriate for a project of this nature. The goal is to create a strong first draft that can be reviewed and refined."

    # Call Gemini and write the output to the file
    gemini -p "$gemini_prompt" > "$brief_file"

    # Ensure the frontmatter has the correct dates
    sed -i "s/created: .*/created: $today/" "$brief_file"
    sed -i "s/updated: .*/updated: $today/" "$brief_file"

    echo "Successfully created product brief at $brief_file"
    echo ""
    echo "Next steps:"
    echo "1. Edit $brief_file to populate all sections"
    echo "2. Run 'status $dir_name' to verify completion"
    echo "3. Run 'research $dir_name' to conduct market analysis"
}

# --- RESEARCH COMMAND ---

function research() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        echo "Error: Project name not provided for 'research' command." >&2
        echo "Usage: $0 research <project-name>" >&2
        exit 1
    fi

    check_prd_directory
    check_project_exists "$project_name"

    local project_dir="docs/prds/$project_name"
    local research_file="$project_dir/research.md"

    # Check if brief exists
    if ! check_file_exists "$project_dir/product-brief.md" "Product brief"; then
        echo "Run 'brief' command first to create the product brief." >&2
        exit 1
    fi

    echo "Creating research document for: $project_name"

    if [ -f "$research_file" ]; then
        echo "Error: Research document already exists at '$research_file'." >&2
        exit 1
    fi

    local today=$(get_date)

    local today=$(get_date)
    local brief_file="$project_dir/product-brief.md"
    echo "Generating a draft research document with Gemini..."

    local gemini_prompt="Based on the following product brief, generate a comprehensive market research document for the project '${project_name}'.
The research document should be in markdown format and include:
- A YAML frontmatter with title, type (research), status (in-progress), created, and updated fields.
- A main title: '# Research: ${project_name}'
- ## Competitive Analysis: Identify 2-3 potential competitors and analyze their strengths, weaknesses, and market position.
- ## Market Insights: Discuss market size, trends, and any relevant regulations.
- ## User Feedback Analysis: Synthesize potential user pain points and desired features.
- ## Technical Considerations: Examine common technical approaches, architecture patterns, and risks.
- ## Recommendations: Provide actionable recommendations for priority features, technical approach, and go-to-market positioning.

Flesh out each section with plausible, high-quality example content that logically follows from the product brief. The goal is to create a strong first draft that can be reviewed and refined.

Here is the product brief for context:
@${brief_file}
"

    # Call Gemini and write the output to the file
    gemini -p "$gemini_prompt" > "$research_file"

    # Ensure the frontmatter has the correct dates
    sed -i "s/created: .*/created: $today/" "$research_file"
    sed -i "s/updated: .*/updated: $today/" "$research_file"

    echo "Successfully created research document at $research_file"
    echo ""
    echo "Next steps:"
    echo "1. Conduct competitive analysis and market research"
    echo "2. Edit $research_file to document findings"
    echo "3. Run 'status $project_name' to verify completion"
    echo "4. Run 'create-prd $project_name' to create PRD"
}

# --- CREATE-PRD COMMAND ---

function create-prd() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        echo "Error: Project name not provided for 'create-prd' command." >&2
        echo "Usage: $0 create-prd <project-name>" >&2
        exit 1
    fi

    check_prd_directory
    check_project_exists "$project_name"

    local project_dir="docs/prds/$project_name"
    local prd_file="$project_dir/prd.md"

    # Check if brief exists
    if ! check_file_exists "$project_dir/product-brief.md" "Product brief"; then
        echo "Run 'brief' command first to create the product brief." >&2
        exit 1
    fi

    # Check if research exists (warning only, not required)
    if ! check_file_exists "$project_dir/research.md" "Research document"; then
        echo "Warning: Research document not found. PRD quality may be reduced." >&2
        echo "Consider running 'research $project_name' first." >&2
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    echo "Creating PRD for: $project_name"

    if [ -f "$prd_file" ]; then
        echo "Error: PRD already exists at '$prd_file'." >&2
        exit 1
    fi

    local today=$(get_date)

    local today=$(get_date)
    local brief_file="$project_dir/product-brief.md"
    local research_file="$project_dir/research.md"
    echo "Generating a draft PRD with Gemini..."

    local gemini_prompt="Based on the following product brief and research document, generate a comprehensive Product Requirements Document (PRD) for the project '${project_name}'.
The PRD should be in markdown format and include:
- A YAML frontmatter with title, type (prd), status (draft), created, and updated fields.
- A main title: '# Product Requirements Document: ${project_name}'
- ## Objectives: Define 2-3 primary, SMART objectives.
- ## Success Criteria: Detail both launch criteria and post-launch success metrics.
- ## Functional Requirements: List at least 3-5 detailed functional requirements (FRs) with descriptions, user stories, and acceptance criteria.
- ## Non-Functional Requirements: Detail requirements for Performance, Security, Reliability, and Usability.
- ## Constraints: List any known technical, business, or resource constraints.
- ## Assumptions: Document key assumptions being made.
- ## Out of Scope: Clearly define what will not be built.

Flesh out each section with plausible, high-quality example content that logically follows from the provided context. The requirements should be specific and testable, and the success criteria should be measurable. The goal is to create a strong first draft that can be reviewed and refined.

Here is the product brief for context:
@${brief_file}

Here is the research document for context:
@${research_file}
"

    # Call Gemini and write the output to the file
    gemini -p "$gemini_prompt" > "$prd_file"

    # Ensure the frontmatter has the correct dates
    sed -i "s/created: .*/created: $today/" "$prd_file"
    sed -i "s/updated: .*/updated: $today/" "$prd_file"
title: $project_name PRD
type: prd
status: draft
created: $today
updated: $today
---

# Product Requirements Document: $project_name

<!-- This PRD translates the product brief and research into specific, actionable requirements -->
<!-- PRDs should be: Specific, Measurable, Testable, Unambiguous, and Complete -->
<!-- Review the product brief and research documents before completing this PRD -->

## Objectives

<!-- This section defines what we're trying to achieve and why -->
<!-- Good objectives are SMART: Specific, Measurable, Achievable, Relevant, Time-bound -->
<!-- Each objective should link back to problems identified in the product brief -->

### Primary Objectives

<!-- These are the core goals that define project success -->
<!-- Usually 2-4 primary objectives -->

1. **[Objective Name]**
   - **Goal**: [What we're trying to accomplish]
   - **Measure**: [How we'll measure success with specific metrics]
   - **Target**: [Specific numeric target]
   - **Timeline**: [When we aim to achieve this]
   - **Why it matters**: [Business or user impact]
   - Example: "Reduce customer onboarding time by 50%, from 10 minutes to 5 minutes, within 3 months of launch to decrease abandonment"

2. **[Objective Name]**
   - **Goal**:
   - **Measure**:
   - **Target**:
   - **Timeline**:
   - **Why it matters**:

3. **[Objective Name]**
   - **Goal**:
   - **Measure**:
   - **Target**:
   - **Timeline**:
   - **Why it matters**:

### Secondary Objectives

<!-- Nice-to-have objectives or future phase goals -->
<!-- These add value but aren't required for initial launch success -->

1. [Future phase objective with brief rationale]
2. [Stretch goal that exceeds primary objectives]

## Success Criteria

<!-- This section defines concrete, testable criteria for success -->
<!-- Distinguish between launch readiness and post-launch success -->

### Launch Criteria (Must-Have)

<!-- These must be met before we can launch to users -->
<!-- Each criterion should be binary: pass/fail, yes/no -->
<!-- Use checkboxes to track completion -->

**Functional Completeness**
- [ ] [All MVP features implemented and tested]
  - Example: "User can create account, add payment method, and complete checkout"
- [ ] [Core user workflows tested end-to-end]
  - Example: "100% of critical user paths tested with >95% success rate"

**Quality Standards**
- [ ] [Performance benchmarks met]
  - Example: "Page load time <2 seconds at p95"
- [ ] [Security requirements satisfied]
  - Example: "Security audit completed with no critical vulnerabilities"
- [ ] [Accessibility compliance achieved]
  - Example: "WCAG 2.1 AA compliance verified"

**Operational Readiness**
- [ ] [Monitoring and alerting configured]
- [ ] [Documentation complete]
  - Example: "User guide, API docs, and runbooks published"
- [ ] [Support team trained]

### Success Metrics (Post-Launch)

<!-- These metrics indicate the product is achieving its objectives -->
<!-- Track these for 30-90 days post-launch -->
<!-- Each metric should have: baseline, target, measurement method, and timeframe -->

**Adoption Metrics**
- [ ] **[Metric name]**: [Baseline] → [Target] within [timeframe]
  - How measured: [Measurement method]
  - Example: "Active users: 0 → 5,000 within 60 days"
  - How measured: "Daily active users in analytics platform"

**Engagement Metrics**
- [ ] **[Metric name]**: [Baseline] → [Target] within [timeframe]
  - How measured:
  - Example: "Session duration: 3 min → 8 min within 30 days"

**Business Metrics**
- [ ] **[Metric name]**: [Baseline] → [Target] within [timeframe]
  - How measured:
  - Example: "Conversion rate: 12% → 18% within 90 days"

**Quality Metrics**
- [ ] **[Metric name]**: [Baseline] → [Target] within [timeframe]
  - How measured:
  - Example: "Error rate: <1% sustained over 30 days"

### Stretch Goals

<!-- Ambitious goals that exceed primary objectives -->
<!-- Nice to achieve but not required for success -->

- [ ] [Ambitious goal with clear measurement]
  - Example: "Achieve 10,000 users within 90 days (2x primary target)"

## Functional Requirements

<!-- This section specifies WHAT the system must do -->
<!-- Each requirement should be: Specific, Testable, Unambiguous, and Complete -->
<!-- Number requirements for easy reference (FR1, FR2, etc.) -->
<!-- Group related requirements into logical sections if needed -->

### FR1: [Requirement Name]

**Description**
<!-- What does this requirement enable? What user need does it address? -->
<!-- Be specific about behavior, not implementation -->
<!-- Example: "System shall allow users to save multiple payment methods for future use" -->

**User Story** (Optional but helpful)
<!-- As a [user type], I want [capability], so that [benefit] -->
<!-- Example: "As a returning customer, I want to save my payment method, so that I can check out faster on future purchases" -->

**Inputs**
<!-- What data or actions trigger this functionality? -->
<!-- Example: "User clicks 'Save payment method' checkbox during checkout" -->
<!-- Example: "Payment details: card number, expiration date, CVV, billing address" -->

**Outputs**
<!-- What results or changes occur? -->
<!-- Example: "Payment method stored securely with last 4 digits shown" -->
<!-- Example: "Confirmation message displayed to user" -->

**Business Rules**
<!-- Any constraints or special conditions? -->
<!-- Example: "Maximum 5 payment methods per user" -->
<!-- Example: "Credit card validation must occur before saving" -->

**Acceptance Criteria**
<!-- Specific, testable conditions that must be met -->
<!-- Use Given/When/Then format or checklist format -->

- [ ] Given [precondition], when [action], then [expected result]
  - Example: "Given user has <5 saved methods, when they save a new payment method, then it appears in their payment methods list"
- [ ] Given [precondition], when [action], then [expected result]
  - Example: "Given user enters invalid card number, when they attempt to save, then error message displays and payment method is not saved"
- [ ] [Testable criterion]
  - Example: "Saved payment method can be selected during future checkout"

**Priority**: [Must Have / Should Have / Could Have / Won't Have]

**Dependencies**: [Other requirements or external systems this depends on]
<!-- Example: "Depends on FR3 (User Authentication) and integration with Stripe API" -->

---

### FR2: [Requirement Name]

**Description**

**User Story**

**Inputs**

**Outputs**

**Business Rules**

**Acceptance Criteria**
- [ ]
- [ ]
- [ ]

**Priority**:

**Dependencies**:

---

### FR3: [Requirement Name]

<!-- Repeat structure above -->
<!-- Add as many functional requirements as needed -->
<!-- Typical PRD has 10-30 functional requirements -->

---

## Non-Functional Requirements

<!-- This section specifies HOW WELL the system must perform -->
<!-- NFRs define quality attributes: performance, security, usability, etc. -->
<!-- Each NFR should be measurable and testable -->

### NFR1: Performance

<!-- How fast and responsive must the system be? -->

**Response Time**
- [Operation]: [Target response time]
  - Example: "Page load: <2 seconds at p95 under normal load"
- [Operation]: [Target response time]
  - Example: "API calls: <200ms at p95"
- [Operation]: [Target response time]
  - Example: "Search results: <1 second for 95% of queries"

**Throughput**
- [Metric]: [Target capacity]
  - Example: "Handle 1,000 transactions per minute sustained"
- [Metric]: [Target capacity]
  - Example: "Support 10,000 concurrent users"

**Resource Utilization**
- [Resource]: [Constraint or target]
  - Example: "Database queries: <100ms average execution time"
- [Resource]: [Constraint or target]
  - Example: "Memory footprint: <512MB per service instance"

**Testing Requirements**
- Performance tests must simulate [load conditions]
- Example: "Load test with 10,000 concurrent users for 1 hour"

---

### NFR2: Security

<!-- How must the system protect data and prevent unauthorized access? -->

**Authentication**
- [Requirement]
  - Example: "Support multi-factor authentication (MFA) for all users"
- [Requirement]
  - Example: "Session timeout after 30 minutes of inactivity"

**Authorization**
- [Requirement]
  - Example: "Role-based access control (RBAC) with minimum of 3 roles: Admin, User, Guest"
- [Requirement]
  - Example: "Users can only access their own data"

**Data Protection**
- [Requirement]
  - Example: "All sensitive data encrypted at rest using AES-256"
- [Requirement]
  - Example: "All data in transit encrypted using TLS 1.3"
- [Requirement]
  - Example: "PII must be masked in logs and error messages"

**Compliance**
- [Standard/Regulation]: [Specific requirements]
  - Example: "GDPR: Support right to data deletion within 30 days"
- [Standard/Regulation]: [Specific requirements]
  - Example: "PCI-DSS: Never store full card numbers or CVV"

**Security Testing**
- [Requirement]
  - Example: "Pass OWASP Top 10 security audit"
- [Requirement]
  - Example: "Penetration testing completed before launch"

---

### NFR3: Reliability

<!-- How dependable and fault-tolerant must the system be? -->

**Availability**
- [Target uptime]
  - Example: "99.9% uptime (SLA), measured monthly"
  - Example: "Maximum planned downtime: 4 hours per month during maintenance windows"

**Error Handling**
- [Requirement]
  - Example: "All API errors return appropriate HTTP status codes and user-friendly messages"
- [Requirement]
  - Example: "System gracefully degrades when third-party services unavailable"

**Data Integrity**
- [Requirement]
  - Example: "Zero data loss for committed transactions"
- [Requirement]
  - Example: "Daily automated backups with 30-day retention"
- [Requirement]
  - Example: "Point-in-time recovery capability within 15 minutes"

**Fault Tolerance**
- [Requirement]
  - Example: "System continues operating if single service instance fails"
- [Requirement]
  - Example: "Automatic retry with exponential backoff for transient failures"

**Monitoring & Alerting**
- [Requirement]
  - Example: "Alert on error rate exceeding 1% within 5-minute window"
- [Requirement]
  - Example: "Monitor and log all critical user actions"

---

### NFR4: Usability

<!-- How easy and pleasant must the system be to use? -->

**User Experience**
- [Requirement]
  - Example: "New users can complete primary task within 5 minutes without training"
- [Requirement]
  - Example: "Maximum 3 clicks to reach any major feature"

**Accessibility**
- [Standard]: [Requirements]
  - Example: "WCAG 2.1 Level AA compliance"
- [Requirement]
  - Example: "Support keyboard navigation for all functionality"
- [Requirement]
  - Example: "Screen reader compatible"
- [Requirement]
  - Example: "Color contrast ratio minimum 4.5:1"

**Internationalization**
- [Requirement]
  - Example: "Support English, Spanish, and French languages"
- [Requirement]
  - Example: "Display dates and currency in user's locale format"

**Responsive Design**
- [Requirement]
  - Example: "Full functionality on mobile, tablet, and desktop"
- [Requirement]
  - Example: "Support minimum resolution: 320px width (mobile)"

**Documentation**
- [Requirement]
  - Example: "In-app help tooltips for all major features"
- [Requirement]
  - Example: "Comprehensive user guide and FAQ"

---

### NFR5: Scalability

<!-- How must the system handle growth? -->

**Growth Targets**
- [Metric]: [Current] → [Target] over [timeframe]
  - Example: "Users: 1,000 → 100,000 over 12 months"
- [Metric]: [Current] → [Target] over [timeframe]
  - Example: "Data volume: 10GB → 1TB over 12 months"

**Scaling Approach**
- [Strategy]
  - Example: "Horizontal scaling: Add service instances to handle increased load"
- [Strategy]
  - Example: "Database sharding: Partition data by user ID when >1M users"

**Performance Under Load**
- [Requirement]
  - Example: "Response time degradation <20% at 2x expected peak load"
- [Requirement]
  - Example: "Successfully handle 3x expected peak load with additional resources"

---

### NFR6: Maintainability

<!-- How easy must the system be to maintain and modify? -->

**Code Quality**
- [Requirement]
  - Example: "Minimum 80% unit test coverage"
- [Requirement]
  - Example: "All code passes linter with zero warnings"

**Documentation**
- [Requirement]
  - Example: "All APIs documented with OpenAPI specification"
- [Requirement]
  - Example: "Architecture decision records (ADRs) for major design choices"
- [Requirement]
  - Example: "Runbooks for common operational tasks"

**Modularity**
- [Requirement]
  - Example: "Services loosely coupled with well-defined interfaces"
- [Requirement]
  - Example: "Can deploy individual services independently"

---

## Constraints

<!-- This section documents limitations we must work within -->
<!-- Constraints shape the solution but are typically non-negotiable -->

### Technical Constraints

- [Constraint]: [Description and implications]
  - Example: "Must integrate with legacy CRM system using SOAP APIs (limits performance)"
- [Constraint]: [Description and implications]
  - Example: "Existing infrastructure runs on AWS only (limits multi-cloud options)"

### Business Constraints

- [Constraint]: [Description and implications]
  - Example: "Launch must occur before Q4 holiday season (hard deadline: October 1)"
- [Constraint]: [Description and implications]
  - Example: "No budget for third-party services costing >$5K/month"

### Regulatory Constraints

- [Constraint]: [Description and implications]
  - Example: "Must comply with GDPR and CCPA (requires specific data handling)"
- [Constraint]: [Description and implications]
  - Example: "Healthcare data requires HIPAA compliance (limits storage options)"

### Resource Constraints

- [Constraint]: [Description and implications]
  - Example: "Development team of 3 engineers (limits scope and complexity)"
- [Constraint]: [Description and implications]
  - Example: "No iOS developer available (web-only initial release)"

### Integration Constraints

- [Constraint]: [Description and implications]
  - Example: "Payment gateway limited to Stripe (already contracted)"
- [Constraint]: [Description and implications]
  - Example: "SSO must use company's existing Okta instance"

## Assumptions

<!-- This section documents assumptions that underpin the PRD -->
<!-- Assumptions are things we believe to be true but haven't verified -->
<!-- If assumptions prove false, requirements may need to change -->

**User Assumptions**
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Users have reliable internet connections (mobile experience may degrade on 3G)"
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Users are comfortable with English language (no immediate localization needed)"

**Technical Assumptions**
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Third-party APIs maintain 99.9% uptime (our reliability depends on this)"
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Cloud infrastructure can scale to meet demand (architecture relies on auto-scaling)"

**Business Assumptions**
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Target market will pay premium pricing (revenue projections based on this)"
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Current customer demand remains stable (sizing infrastructure for current scale)"

**Resource Assumptions**
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Key engineers remain available throughout project (timeline depends on specific expertise)"
- [Assumption]: [What we're assuming and why it matters]
  - Example: "Design resources available for 20 hours/week (UI work scheduled accordingly)"

## Out of Scope

<!-- This section explicitly states what we will NOT build -->
<!-- Being clear about exclusions prevents scope creep and manages expectations -->
<!-- For each excluded item, briefly explain why it's out of scope -->

### Features Explicitly Excluded

- **[Feature/Capability]**: [Why it's excluded]
  - Example: "Social media integration: Not requested by users in research, defer to Phase 2"
- **[Feature/Capability]**: [Why it's excluded]
  - Example: "Bulk import tool: Only 5% of users need this, not worth complexity for MVP"
- **[Feature/Capability]**: [Why it's excluded]
  - Example: "Mobile native apps: Web-first strategy, revisit if user demand emerges"

### Deferred to Future Phases

- **[Feature/Capability]**: [Why it's deferred and when it might be reconsidered]
  - Example: "Advanced analytics dashboard: Phase 2 feature after we validate core workflow"
- **[Feature/Capability]**: [Why it's deferred and when it might be reconsidered]
  - Example: "Multi-tenant support: Add in 6 months once single-tenant proven"

### Use Cases Not Supported

- **[Use Case]**: [Why it's not supported]
  - Example: "Enterprise customers with >10,000 users: Architecture doesn't scale to this level yet"
- **[Use Case]**: [Why it's not supported]
  - Example: "Offline mode: Requires significant complexity, not essential for MVP"

### Platforms Not Supported

- [Platform]: [Why not supported]
  - Example: "Internet Explorer 11: <2% of user base, not worth compatibility effort"
- [Platform]: [Why not supported]
  - Example: "Legacy Android versions (pre-10): Security and maintenance burden"

EOF

    echo "Successfully created PRD at $prd_file"
    echo ""
    echo "Next steps:"
    echo "1. Populate PRD sections with requirements and success criteria"
    echo "2. Ensure requirements are specific, measurable, and testable"
    echo "3. Run 'validate-prd $project_name' to check quality"
    echo "4. Run 'decompose $project_name' after PRD is complete"
}

# --- VALIDATE-PRD COMMAND ---

function validate-prd() {
    local project_name=$1
    local mode=${2:-strict}

    if [ -z "$project_name" ]; then
        echo "Error: Project name not provided for 'validate-prd' command." >&2
        echo "Usage: $0 validate-prd <project-name> [--lenient]" >&2
        exit 1
    fi

    # Handle --lenient flag
    if [ "$mode" = "--lenient" ]; then
        mode="lenient"
    elif [ "$mode" != "strict" ] && [ "$mode" != "lenient" ]; then
        mode="strict"
    fi

    check_prd_directory
    check_project_exists "$project_name"

    local project_dir="docs/prds/$project_name"
    local prd_file="$project_dir/prd.md"

    if ! check_file_exists "$prd_file" "PRD"; then
        echo "Run 'create-prd' command first to create the PRD." >&2
        exit 1
    fi

    echo "=== PRD Validation Report ==="
    echo "Project: $project_name"
    echo "File: $prd_file"
    echo "Mode: $mode"
    echo ""

    local issues=0
    local warnings=0

    # Check YAML frontmatter
    if head -n 1 "$prd_file" | grep -q "^---$"; then
        echo "✓ YAML frontmatter present"
    else
        echo "✗ YAML frontmatter missing"
        ((issues++))
    fi

    # Check for required sections
    local required_sections=(
        "## Objectives"
        "## Success Criteria"
        "## Functional Requirements"
        "## Non-Functional Requirements"
        "## Constraints"
        "## Assumptions"
    )

    echo ""
    echo "Completeness Checks:"
    for section in "${required_sections[@]}"; do
        if grep -q "^$section" "$prd_file"; then
            echo "  ✓ $section section present"
        else
            if [ "$mode" = "strict" ]; then
                echo "  ✗ $section section missing"
                ((issues++))
            else
                echo "  ⚠ $section section missing (lenient mode)"
                ((warnings++))
            fi
        fi
    done

    # Check for vague language
    echo ""
    echo "Quality Checks:"

    local vague_terms=("should" "might" "probably" "maybe" "could" "reasonable" "fast" "slow" "good" "better" "best" "many" "few" "most" "some")
    local vague_found=0

    for term in "${vague_terms[@]}"; do
        local matches=$(grep -n -i "\b$term\b" "$prd_file" | grep -v "^#" | head -n 3)
        if [ -n "$matches" ]; then
            if [ $vague_found -eq 0 ]; then
                echo "  Vague language detected:"
                vague_found=1
            fi
            echo "$matches" | while read -r line; do
                local line_num=$(echo "$line" | cut -d: -f1)
                echo "    ⚠ Line $line_num: Contains '$term'"
                ((warnings++)) || true
            done
        fi
    done

    if [ $vague_found -eq 0 ]; then
        echo "  ✓ No vague language detected"
    fi

    # Check for measurable success criteria
    if grep -q "## Success Criteria" "$prd_file"; then
        local success_section=$(sed -n '/## Success Criteria/,/^## /p' "$prd_file")
        if echo "$success_section" | grep -qE '[0-9]+%|[0-9]+ (seconds|minutes|hours|users|transactions)'; then
            echo "  ✓ Success criteria include measurable targets"
        else
            echo "  ⚠ Success criteria may lack measurable targets"
            ((warnings++))
        fi
    fi

    # Check for acceptance criteria in requirements
    if grep -q "## Functional Requirements" "$prd_file"; then
        local fr_count=$(grep -c "^### FR[0-9]" "$prd_file" || echo "0")
        local ac_count=$(sed -n '/## Functional Requirements/,/^## /p' "$prd_file" | grep -c "Acceptance Criteria:" || echo "0")

        if [ "$fr_count" -gt 0 ] && [ "$ac_count" -ge "$fr_count" ]; then
            echo "  ✓ Functional requirements include acceptance criteria"
        else
            echo "  ⚠ Some functional requirements may lack acceptance criteria"
            ((warnings++))
        fi
    fi

    # Check for out of scope section
    if grep -q "## Out of Scope" "$prd_file"; then
        echo "  ✓ Out of scope section defines boundaries"
    else
        echo "  ⚠ Out of scope section missing (recommended)"
        ((warnings++))
    fi

    # Summary
    echo ""
    echo "=== Summary ==="
    echo "Issues: $issues"
    echo "Warnings: $warnings"
    echo ""

    if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
        echo "Overall: EXCELLENT ✓"
        echo "PRD meets all quality standards."
    elif [ $issues -eq 0 ] && [ $warnings -le 3 ]; then
        echo "Overall: GOOD ✓"
        echo "PRD is solid with minor improvements recommended."
    elif [ $issues -eq 0 ]; then
        echo "Overall: ACCEPTABLE"
        echo "PRD is complete but could be improved."
    else
        echo "Overall: NEEDS WORK"
        echo "Address critical issues before proceeding."
        if [ "$mode" = "strict" ]; then
            echo ""
            echo "Tip: Use '--lenient' flag for draft validation"
        fi
    fi

    echo ""
    echo "Next steps:"
    if [ $issues -gt 0 ]; then
        echo "1. Address critical issues in $prd_file"
        echo "2. Re-run validation: bash scripts/prd-authoring.sh validate-prd $project_name"
    else
        echo "1. Run 'decompose $project_name' to break PRD into epics"
    fi
}

# --- DECOMPOSE COMMAND ---

function decompose() {
    local project_name=$1
    if [ -z "$project_name" ]; then
        echo "Error: Project name not provided for 'decompose' command." >&2
        echo "Usage: $0 decompose <project-name>" >&2
        exit 1
    fi

    check_prd_directory
    check_project_exists "$project_name"

    local project_dir="docs/prds/$project_name"
    local prd_file="$project_dir/prd.md"
    local epics_file="$project_dir/epics.md"

    if ! check_file_exists "$prd_file" "PRD"; then
        echo "Run 'create-prd' command first to create the PRD." >&2
        exit 1
    fi

    echo "Creating epic decomposition for: $project_name"

    if [ -f "$epics_file" ]; then
        echo "Error: Epics document already exists at '$epics_file'." >&2
        echo "Edit existing file or delete it to regenerate." >&2
        exit 1
    fi

    local today=$(get_date)

    cat > "$epics_file" << EOF
---
title: $project_name Epics
type: epic-breakdown
prd: docs/prds/$project_name/prd.md
status: draft
created: $today
updated: $today
---

# Epic Breakdown: $project_name

<!-- This document decomposes the PRD into independently deliverable epics -->
<!-- Purpose: Create a logical decomposition that enables parallel work and incremental delivery -->

## Epic Decomposition Guidelines

<!-- Follow these principles when defining epics: -->

**What makes a good epic?**
- **Independently deliverable**: Can be shipped and provide value on its own
- **Right-sized**: Completable in 2-4 sprints (4-8 weeks)
- **Clear scope**: Well-defined boundaries of what's included/excluded
- **Aligned with objectives**: Directly supports one or more PRD objectives
- **Testable**: Has clear success criteria from the PRD
- **Minimal dependencies**: Reduces blocking between teams/sprints

**Common decomposition strategies:**
- By user journey (onboarding epic, checkout epic, etc.)
- By functional area (authentication epic, payment epic, analytics epic)
- By technical layer (frontend epic, API epic, data migration epic)
- By user persona (admin tools epic, end-user features epic)

---

## Epic 1: [Epic Name]

<!-- Use a descriptive name that captures the essence of what's being built -->
<!-- Example: "User Authentication & Authorization" -->
<!-- Example: "One-Click Checkout Experience" -->

### Objective

<!-- What does this epic achieve? What value does it provide? -->
<!-- Connect to PRD objectives - which objective(s) does this epic support? -->
<!-- Example: "Enable users to securely save payment methods and checkout with a single click, reducing checkout time from 3 minutes to 30 seconds (supports Objective 1: Reduce cart abandonment)" -->

### Scope

<!-- What specific features and capabilities are included in this epic? -->
<!-- Be concrete and specific - these become the basis for user stories -->

**Core Features**:
- [Feature/capability 1]
  - Example: "User can save up to 5 payment methods to their account"
- [Feature/capability 2]
  - Example: "User can select saved payment method during checkout"
- [Feature/capability 3]
  - Example: "User can set a default payment method"

**Supporting Features**:
- [Feature/capability]
  - Example: "User can edit or delete saved payment methods"
- [Feature/capability]
  - Example: "System validates payment methods before saving"

### Requirements Coverage

<!-- Which specific PRD requirements does this epic address? -->
<!-- Reference PRD requirement numbers (FR1, FR2, NFR1, etc.) -->

**Functional Requirements**:
- FR1: [Requirement name from PRD]
  - Coverage: [Complete / Partial - specify what's included]
- FR3: [Requirement name from PRD]
  - Coverage: [Complete / Partial - specify what's included]

**Non-Functional Requirements**:
- NFR2: Security
  - Coverage: Payment data encryption, PCI compliance
- NFR3: Reliability
  - Coverage: Error handling for payment service failures

### Success Criteria

<!-- What must be true for this epic to be considered successful? -->
<!-- Pull from PRD success criteria and launch criteria -->
<!-- Make these specific and measurable -->

**Functional Success** (Must meet all):
- [ ] [Specific, testable criterion from PRD]
  - Example: "User can save payment method and use it on next checkout"
- [ ] [Specific, testable criterion from PRD]
  - Example: "Payment method data encrypted at rest and in transit"
- [ ] [Specific, testable criterion from PRD]
  - Example: "System handles invalid payment data gracefully with clear error messages"

**Quality Success** (Must meet all):
- [ ] [Performance/quality target from PRD]
  - Example: "Payment method save operation completes in <1 second"
- [ ] [Performance/quality target from PRD]
  - Example: "Zero stored plaintext payment data in database"

**Business Success** (Measured post-launch):
- [ ] [Business metric from PRD]
  - Example: "30% of users save payment method on first use"
- [ ] [Business metric from PRD]
  - Example: "Returning users using saved payment methods checkout 60% faster"

### User Stories (Optional)

<!-- Breaking epics into user stories helps clarify scope -->
<!-- Format: As a [user type], I want [capability], so that [benefit] -->

1. As a [user type], I want [capability], so that [benefit]
   - Example: "As a returning customer, I want to save my payment method, so that I don't have to re-enter it on every purchase"

2. As a [user type], I want [capability], so that [benefit]
   - Example: "As a user, I want to see only the last 4 digits of my saved card, so that my payment information stays private"

### Dependencies

<!-- What must exist before this epic can be completed? -->
<!-- Are there dependencies on other epics, teams, or external systems? -->

**Epic Dependencies**:
- [Other epic]: [What's needed from that epic]
  - Example: "Epic 2 (User Account Management): Requires user authentication to be complete"

**Technical Dependencies**:
- [System/service]: [What's needed]
  - Example: "Stripe API integration: Account must be set up and credentials configured"

**Team Dependencies**:
- [Team/person]: [What's needed]
  - Example: "Security team: Review and approval of encryption approach"

**If no dependencies**: "None - this is a foundational epic that other work can build on"

### Technical Approach (Optional)

<!-- High-level technical strategy for implementing this epic -->
<!-- This is optional but helpful for complex epics -->

- [Key architectural decision or approach]
  - Example: "Use Stripe's Token API to avoid storing raw payment data"
- [Key architectural decision or approach]
  - Example: "Implement encryption at application layer using AWS KMS"

### Estimated Effort

<!-- How long will this epic take to complete? -->
<!-- Consider: design, implementation, testing, documentation, deployment -->

**Estimate**: [Number of sprints]
- Example: "3 sprints (6 weeks)"

**Breakdown**:
- Design & Planning: [Duration]
  - Example: "1 sprint: UI design, API design, security review"
- Implementation: [Duration]
  - Example: "1.5 sprints: Frontend, backend, integration"
- Testing & Polish: [Duration]
  - Example: "0.5 sprints: Testing, bug fixes, documentation"

**Confidence Level**: [High / Medium / Low]
<!-- High: Clear requirements, familiar territory -->
<!-- Medium: Some unknowns, but manageable -->
<!-- Low: Significant unknowns, may need spike work -->

### Out of Scope

<!-- What is explicitly NOT included in this epic? -->
<!-- Clarity on exclusions prevents scope creep -->

- [Feature/capability explicitly excluded]
  - Example: "Support for cryptocurrency payments (deferred to Phase 2)"
- [Feature/capability explicitly excluded]
  - Example: "Payment method sharing between family accounts (not in PRD)"
- [Feature/capability explicitly excluded]
  - Example: "Integration with non-Stripe payment processors"

### Risks & Mitigations

<!-- What could go wrong? How will you address it? -->

**Risk 1**: [Description of risk]
- Likelihood: [High / Medium / Low]
- Impact: [High / Medium / Low]
- Mitigation: [How to reduce or handle the risk]
- Example: "Stripe API changes - Likelihood: Low, Impact: High, Mitigation: Use stable API version, monitor changelog"

**Risk 2**: [Description of risk]
- Likelihood:
- Impact:
- Mitigation:

### Acceptance Process

<!-- How will this epic be validated before closing? -->

1. [Validation step]
   - Example: "All functional and quality success criteria met"
2. [Validation step]
   - Example: "Product owner sign-off on user experience"
3. [Validation step]
   - Example: "Security review passed"
4. [Validation step]
   - Example: "Documentation complete and published"

---

## Epic 2: [Epic Name]

<!-- Repeat the structure above for each epic -->

### Objective

### Scope

**Core Features**:
-
-

**Supporting Features**:
-

### Requirements Coverage

**Functional Requirements**:
- FRX:
  - Coverage:

**Non-Functional Requirements**:
- NFRX:
  - Coverage:

### Success Criteria

**Functional Success**:
- [ ]

**Quality Success**:
- [ ]

**Business Success**:
- [ ]

### User Stories (Optional)

1. As a [user type], I want [capability], so that [benefit]

### Dependencies

**Epic Dependencies**:
-

**Technical Dependencies**:
-

**Team Dependencies**:
-

### Technical Approach (Optional)

-

### Estimated Effort

**Estimate**:

**Breakdown**:
- Design & Planning:
- Implementation:
- Testing & Polish:

**Confidence Level**:

### Out of Scope

-

### Risks & Mitigations

**Risk 1**:
- Likelihood:
- Impact:
- Mitigation:

### Acceptance Process

1.
2.

---

## Epic 3: [Epic Name]

<!-- Add as many epics as needed to cover all PRD requirements -->
<!-- Typical PRD decomposes into 3-7 epics -->
<!-- If you have >10 epics, consider whether they're properly sized -->

<!-- Repeat epic structure -->

---

## Epic Dependencies & Sequencing

<!-- This section visualizes how epics relate and the recommended order -->
<!-- Understanding dependencies helps with sprint planning and parallel work -->

### Dependency Diagram

\`\`\`
Epic 1: [Name] (Foundational - no dependencies)
  │
  ├─→ Epic 2: [Name] (Depends on Epic 1)
  │     │
  │     └─→ Epic 4: [Name] (Depends on Epic 2)
  │
  └─→ Epic 3: [Name] (Depends on Epic 1)

Epic 5: [Name] (Independent - can be done in parallel)
\`\`\`

### Recommended Sequence

<!-- Provide a concrete plan for tackling epics -->
<!-- Consider: dependencies, team capacity, business priorities, risk reduction -->

**Phase 1** (Sprints 1-3):
- Epic 1: [Name]
  - Rationale: [Why this comes first]
  - Example: "Must complete foundational authentication before other features can build on it"

**Phase 2** (Sprints 4-6):
- Epic 2: [Name] (Depends on Epic 1)
- Epic 3: [Name] (Depends on Epic 1) - Can run in parallel with Epic 2
  - Rationale: [Why these are next and can be parallel]

**Phase 3** (Sprints 7-9):
- Epic 4: [Name]
- Epic 5: [Name] - Can run in parallel with Epic 4
  - Rationale: [Why these come last]

**Critical Path**: Epic 1 → Epic 2 → Epic 4
<!-- The critical path determines minimum timeline -->

---

## Requirements Traceability Matrix

<!-- This ensures 100% coverage of PRD requirements across epics -->
<!-- Every requirement from the PRD must map to at least one epic -->

### Functional Requirements Coverage

| Requirement | Epic(s) | Coverage | Notes |
|-------------|---------|----------|-------|
| FR1: [Name] | Epic 1 | 100% | Fully covered |
| FR2: [Name] | Epic 1, Epic 2 | 100% | Split across two epics |
| FR3: [Name] | Epic 3 | 100% | |
| FR4: [Name] | Epic 2 | 50% | Partial: MVP only, full implementation in Phase 2 |

<!-- Add rows for all functional requirements from PRD -->

### Non-Functional Requirements Coverage

| Requirement | Epic(s) | Coverage | Notes |
|-------------|---------|----------|-------|
| NFR1: Performance | All Epics | 100% | Each epic includes performance testing |
| NFR2: Security | Epic 1, Epic 2 | 100% | Auth & data protection |
| NFR3: Reliability | All Epics | 100% | Error handling in each epic |
| NFR4: Usability | Epic 3, Epic 4 | 100% | |
| NFR5: Scalability | Epic 5 | 100% | Dedicated infrastructure epic |

<!-- Add rows for all non-functional requirements from PRD -->

### Coverage Summary

- **Total Functional Requirements**: [Count from PRD]
- **Requirements Fully Covered**: [Count]
- **Requirements Partially Covered**: [Count] - [Explain which and why]
- **Requirements Not Covered**: [Count] - [Explain which and why]
- **Overall Coverage**: [Percentage]

**Target**: 100% coverage of all "Must Have" requirements

---

## Sprint Planning Guidance

<!-- This section helps transition from epics to sprint execution -->

### Estimated Timeline

- **Total Epics**: [Count]
- **Estimated Duration**: [Total sprints needed]
  - Example: "5 epics, 12 sprints (24 weeks)"
- **Target Completion**: [Date based on sprint cadence]

### Team Capacity Assumptions

<!-- What assumptions about team capacity went into estimates? -->

- **Team Size**: [Number of engineers]
- **Sprint Length**: [Weeks per sprint]
- **Velocity**: [Story points or similar per sprint]
- **Availability**: [Any known constraints]
  - Example: "Assumes full team availability, accounts for holidays"

### Prerequisites for Sprint Planning

<!-- What needs to happen before we can start sprinting? -->

- [ ] All epics reviewed and approved by stakeholders
- [ ] Dependencies identified and coordinated
- [ ] Team capacity confirmed
- [ ] Technical approach validated for high-risk epics
- [ ] [Other prerequisites]

---

## Next Steps

<!-- Clear actions to move from epic breakdown to execution -->

### Immediate Actions

1. **Review with Stakeholders**
   - Schedule: [When]
   - Attendees: [Who needs to review]
   - Goal: [What you're seeking approval for]
   - Example: "Present epic breakdown to product leadership on [date] for approval"

2. **Refine Epic Boundaries**
   - Identify any overlaps or gaps between epics
   - Ensure each epic is independently deliverable
   - Validate effort estimates with engineering team

3. **Begin Spec Authoring**
   - Use SynthesisFlow spec-authoring skill to create detailed specs
   - Start with Epic 1 (foundational/highest priority)
   - Create one spec per epic or per major user story

4. **Coordinate Dependencies**
   - [Action for specific dependency]
   - Example: "Schedule kickoff with security team for Epic 1 review"
   - [Action for specific dependency]

### Transition to Execution

**Once epics are approved:**

1. Use **spec-authoring** skill to write detailed specifications for Epic 1
2. Use **sprint-planner** skill to decompose specs into GitHub issues
3. Begin Sprint 1 execution using **issue-executor** skill
4. After each epic completion, use **change-integrator** skill to update documentation

**Success Criteria for This Document**:
- [ ] All PRD requirements mapped to epics (100% coverage)
- [ ] Epic dependencies clearly identified and sequenced
- [ ] Effort estimates reviewed by engineering team
- [ ] Stakeholder approval obtained
- [ ] Ready to begin spec authoring for Epic 1

EOF

    echo "Successfully created epic decomposition at $epics_file"
    echo ""
    echo "Next steps:"
    echo "1. Review PRD requirements and group into logical epics"
    echo "2. Edit $epics_file to define each epic"
    echo "3. Map dependencies between epics"
    echo "4. Verify 100% requirements coverage"
    echo "5. Transition to spec-authoring workflow for each epic"
}

# --- GENERATE-SPEC COMMAND ---

function generate-spec() {
    local project_name=$1
    local epic_name=$2

    if [ -z "$project_name" ] || [ -z "$epic_name" ]; then
        echo "Error: Project name and epic name required for 'generate-spec' command." >&2
        echo "Usage: $0 generate-spec <project-name> <epic-name>" >&2
        exit 1
    fi

    check_prd_directory
    check_project_exists "$project_name"

    local project_dir="docs/prds/$project_name"
    local prd_file="$project_dir/prd.md"
    local epics_file="$project_dir/epics.md"

    # Validate PRD and epics exist
    if ! check_file_exists "$prd_file" "PRD"; then
        echo "Run 'create-prd' command first to create the PRD." >&2
        exit 1
    fi

    if ! check_file_exists "$epics_file" "Epic decomposition"; then
        echo "Run 'decompose' command first to create epic decomposition." >&2
        exit 1
    fi

    # Normalize epic name to kebab-case
    local epic_dir_name=$(to_kebab_case "$epic_name")
    local changes_dir="docs/changes/$epic_dir_name"

    echo "Generating spec proposal for epic: $epic_name"

    # Check if changes directory exists
    if [ ! -d "docs/changes" ]; then
        echo "Creating docs/changes directory..."
        mkdir -p "docs/changes"
    fi

    # Check if spec proposal already exists
    if [ -d "$changes_dir" ]; then
        echo "Error: Spec proposal directory '$changes_dir' already exists." >&2
        echo "Either use a different epic name or delete the existing directory." >&2
        exit 1
    fi

    # Create changes directory
    mkdir -p "$changes_dir"

    local today=$(get_date)

    # Extract epic information from epics.md
    # This is a simplified extraction - looks for the epic by searching for the epic name in headers
    local epic_found=0

    # Try to find the epic section in epics.md
    # We'll look for patterns like "## Epic N: <epic-name>" or just the epic name in headers
    if grep -qi "^## .*$epic_name" "$epics_file"; then
        epic_found=1
        echo "Found epic '$epic_name' in $epics_file"
    else
        echo "Warning: Could not find epic '$epic_name' in $epics_file" >&2
        echo "Generating generic spec proposal template. Please populate manually." >&2
    fi

    # Generate proposal.md
    cat > "$changes_dir/proposal.md" << EOF
---
title: $epic_name
type: spec-proposal
status: draft
prd: docs/prds/$project_name/prd.md
epic: $epic_name
created: $today
updated: $today
---

# Proposal: $epic_name

## Problem Statement

<!-- Extract from PRD and epic scope -->
<!-- What specific problem does this epic solve? -->
<!-- Reference the PRD objectives this epic supports -->

## Proposed Solution

<!-- High-level overview of what will be built -->
<!-- Based on the epic scope and requirements coverage -->

## Benefits

<!-- User benefits and business value -->
<!-- Connect to PRD success criteria -->

- **User Impact**: [How this improves user experience]
- **Business Value**: [How this supports business objectives]
- **Technical Impact**: [How this improves system architecture/quality]

## Success Criteria

<!-- Pull from epic success criteria in epics.md -->
<!-- Must be specific, measurable, and testable -->

**Functional Success**:
- [ ] [Criterion from epic]
- [ ] [Criterion from epic]

**Quality Success**:
- [ ] [Performance/quality target]
- [ ] [Security/reliability requirement]

**Business Success** (Measured post-launch):
- [ ] [Business metric target]

## Scope

**In Scope**:
<!-- Core features from epic scope -->
- [Feature/capability 1]
- [Feature/capability 2]
- [Feature/capability 3]

**Out of Scope**:
<!-- Explicitly excluded from this epic -->
- [Excluded feature/capability]
- [Deferred to future phase]

## Dependencies

<!-- From epic dependencies section -->

**Epic Dependencies**:
- [Other epic or requirement]

**Technical Dependencies**:
- [System/service/API requirement]

**Team Dependencies**:
- [Required reviews or approvals]

## Risks

<!-- From epic risks & mitigations section -->

**Risk 1**: [Description]
- Likelihood: [High/Medium/Low]
- Impact: [High/Medium/Low]
- Mitigation: [Strategy]

## Traceability

**PRD Reference**: docs/prds/$project_name/prd.md

**Requirements Coverage**:
<!-- List specific PRD requirements this epic addresses -->
- FR[N]: [Requirement name]
- NFR[N]: [Non-functional requirement]

**Success Metrics Mapping**:
<!-- Map to PRD success criteria -->
- [PRD metric]: [How this epic contributes]

EOF

    # Generate spec-delta.md
    cat > "$changes_dir/spec-delta.md" << EOF
---
title: $epic_name Specification
type: spec-delta
status: draft
prd: docs/prds/$project_name/prd.md
epic: $epic_name
created: $today
updated: $today
---

# Spec Delta: $epic_name

## Overview

<!-- High-level description of what this spec defines -->
<!-- Based on epic objective and scope -->

This specification defines the implementation requirements for the "$epic_name" epic from the $project_name PRD.

## Requirements

### Functional Requirements

<!-- Extract from PRD functional requirements that this epic covers -->
<!-- Each requirement from the epic's "Requirements Coverage" section should be detailed here -->

#### FR1: [Requirement Name]
- **Description**: [What this functionality does]
- **Inputs**: [What data or actions trigger this]
- **Outputs**: [What results or changes occur]
- **Business Rules**: [Constraints or special conditions]
- **Acceptance Criteria**:
  - [ ] [Specific, testable criterion]
  - [ ] [Specific, testable criterion]
  - [ ] [Specific, testable criterion]
- **Priority**: [Must Have / Should Have / Could Have]
- **PRD Reference**: FR[N] in docs/prds/$project_name/prd.md

#### FR2: [Requirement Name]
- **Description**:
- **Inputs**:
- **Outputs**:
- **Business Rules**:
- **Acceptance Criteria**:
  - [ ]
  - [ ]
- **Priority**:
- **PRD Reference**:

### Non-Functional Requirements

<!-- Extract from PRD non-functional requirements relevant to this epic -->

#### NFR1: Performance
- [Performance target from PRD]
- [Measurement method]
- **PRD Reference**: NFR[N] in docs/prds/$project_name/prd.md

#### NFR2: Security
- [Security requirement from PRD]
- [Compliance requirement]
- **PRD Reference**: NFR[N] in docs/prds/$project_name/prd.md

#### NFR3: Reliability
- [Reliability requirement from PRD]
- [Error handling requirement]
- **PRD Reference**: NFR[N] in docs/prds/$project_name/prd.md

#### NFR4: Usability
- [Usability requirement from PRD]
- [User experience requirement]
- **PRD Reference**: NFR[N] in docs/prds/$project_name/prd.md

## Design Decisions

<!-- Document key architectural and design choices -->

### DD1: [Decision Name]
**Decision**: [What was decided]

**Rationale**:
- [Reason for this approach]
- [How it supports epic objectives]

**Alternatives Considered**:
- [Alternative approach]: [Why rejected]

**Impact**: [Effect on system architecture or user experience]

### DD2: [Decision Name]
**Decision**:

**Rationale**:
-

**Alternatives Considered**:
-

**Impact**:

## Implementation Approach

<!-- High-level technical approach -->
<!-- Based on "Technical Approach" section from epic if present -->

### Architecture

[Describe component architecture, data flow, integration points]

### Components

**Component 1**: [Name/Purpose]
- Responsibilities: [What it does]
- Interfaces: [APIs or contracts]
- Dependencies: [What it depends on]

**Component 2**: [Name/Purpose]
- Responsibilities:
- Interfaces:
- Dependencies:

### Data Model

<!-- If applicable, describe data structures, database schema changes, API contracts -->

### Integration Points

<!-- External systems, APIs, services this integrates with -->

- [System/Service]: [Integration type and purpose]

## Testing Strategy

<!-- How this will be validated -->

### Unit Testing
- [What will be unit tested]
- Target coverage: [Percentage]

### Integration Testing
- [What integration scenarios to test]
- [Key workflows to validate]

### End-to-End Testing
- [User workflows to test]
- [Success criteria validation]

### Performance Testing
- [Performance benchmarks to validate]
- [Load testing approach]

## Migration Path

<!-- If applicable, how existing systems/data will be migrated -->

### For New Installations
[Approach for greenfield deployments]

### For Existing Systems
[Upgrade path, data migration, backward compatibility]

## Dependencies

<!-- Detailed dependency information -->

### Upstream Dependencies
<!-- What must exist before this can be implemented -->
- [Dependency]: [What's required and why]

### Downstream Impact
<!-- What will be affected by this implementation -->
- [Affected system/component]: [Nature of impact]

## Success Metrics

<!-- Specific metrics for this epic -->
<!-- Derived from epic success criteria and PRD metrics -->

### Launch Criteria
- [ ] [Specific launch requirement]
- [ ] [Specific launch requirement]

### Post-Launch Metrics
- **[Metric name]**: [Baseline] → [Target] within [timeframe]
- **[Metric name]**: [Baseline] → [Target] within [timeframe]

## Risks and Mitigations

<!-- From epic risks section -->

### Technical Risks
- **Risk**: [Description]
  - Likelihood: [High/Medium/Low]
  - Impact: [High/Medium/Low]
  - Mitigation: [Strategy]
  - Contingency: [Fallback plan]

### Schedule Risks
- **Risk**: [Description]
  - Mitigation: [Strategy]

## Traceability Matrix

<!-- Map spec requirements back to PRD -->

| Spec Requirement | PRD Requirement | Epic Section | Coverage |
|------------------|-----------------|--------------|----------|
| FR1 | FR[N] | [Section] | Complete |
| FR2 | FR[N] | [Section] | Partial |
| NFR1 | NFR[N] | [Section] | Complete |

**Coverage Summary**:
- Total PRD requirements in epic: [Count]
- Requirements addressed in spec: [Count]
- Coverage percentage: [Percentage]

EOF

    # Generate tasks.md
    cat > "$changes_dir/tasks.md" << EOF
---
title: $epic_name Tasks
type: task-breakdown
status: draft
prd: docs/prds/$project_name/prd.md
epic: $epic_name
created: $today
updated: $today
---

# Tasks: $epic_name

<!-- This task breakdown will be refined during sprint planning -->
<!-- Use epic "User Stories" section and requirements to identify tasks -->

## Overview

**Epic**: $epic_name
**PRD**: docs/prds/$project_name/prd.md
**Estimated Effort**: [From epic] sprints ([N] weeks)

## Task Breakdown

<!-- Break epic into implementable tasks -->
<!-- Each task should be completable in a few hours to a few days -->
<!-- Tasks should align with spec requirements -->

---

## Task 1: [Task Name]

<!-- Foundation or setup task -->

**Description**: [What needs to be done]

**Subtasks**:
- [ ] [Specific subtask]
- [ ] [Specific subtask]
- [ ] [Specific subtask]

**Acceptance Criteria**:
- [Specific, testable criterion]
- [Specific, testable criterion]

**Dependencies**:
- [What must be complete first]

**Estimated Effort**: [Hours or days]

**Related Requirements**: FR[N], NFR[N]

---

## Task 2: [Task Name]

<!-- Core implementation task -->

**Description**:

**Subtasks**:
- [ ]
- [ ]
- [ ]

**Acceptance Criteria**:
-
-

**Dependencies**:
- Task 1

**Estimated Effort**:

**Related Requirements**:

---

## Task 3: [Task Name]

<!-- Testing or integration task -->

**Description**:

**Subtasks**:
- [ ]
- [ ]

**Acceptance Criteria**:
-
-

**Dependencies**:
- Task 2

**Estimated Effort**:

**Related Requirements**:

---

## Task 4: [Task Name]

<!-- Documentation or polish task -->

**Description**:

**Subtasks**:
- [ ]
- [ ]

**Acceptance Criteria**:
-
-

**Dependencies**:
- Task 3

**Estimated Effort**:

**Related Requirements**:

---

## Summary

**Total Tasks**: [Count]
**Total Estimated Effort**: [Sum] hours/days
**Sprint Allocation**: [How tasks map to sprints]

### Task Dependencies

\`\`\`
Task 1 (Foundation)
  │
  ├─→ Task 2 (Core Implementation)
  │     │
  │     └─→ Task 3 (Integration)
  │
  └─→ Task 4 (Documentation) - Can run in parallel
\`\`\`

### Milestones

1. **Foundation Complete** (Task 1): [Description]
2. **Core Features** (Task 2): [Description]
3. **Integration Ready** (Task 3): [Description]
4. **Launch Ready** (Task 4): [Description]

## Next Steps

<!-- Actions to transition from tasks to execution -->

1. **Review and Refine**
   - Review task breakdown with team
   - Validate effort estimates
   - Identify any missing tasks

2. **Sprint Planning**
   - Use sprint-planner skill to create GitHub issues
   - Allocate tasks across sprint(s)
   - Assign team members

3. **Begin Execution**
   - Use issue-executor skill to start implementation
   - Track progress through GitHub issues
   - Update task status as work completes

## Traceability

**Epic**: $epic_name in docs/prds/$project_name/epics.md
**PRD**: docs/prds/$project_name/prd.md
**Spec**: docs/changes/$epic_dir_name/spec-delta.md

**Requirements Covered**:
<!-- List all PRD requirements addressed by these tasks -->
- FR[N]: [Requirement name] - Tasks [N, N, N]
- NFR[N]: [Requirement name] - Tasks [N, N]

EOF

    echo "Successfully generated spec proposal in $changes_dir"
    echo ""
    echo "Generated files:"
    echo "  - $changes_dir/proposal.md"
    echo "  - $changes_dir/spec-delta.md"
    echo "  - $changes_dir/tasks.md"
    echo ""
    echo "Next steps:"
    echo "1. Review and populate the generated files with epic details from $epics_file"
    echo "2. Extract requirements from the epic section in epics.md"
    echo "3. Link spec requirements back to PRD requirements"
    echo "4. Validate traceability from spec to PRD"
    echo "5. Open a Spec PR using spec-authoring workflow"
}

# --- MAIN ---

COMMAND=$1
shift || true

case "$COMMAND" in
    status)
        status "$@"
        ;;
    brief)
        brief "$@"
        ;;
    research)
        research "$@"
        ;;
    create-prd)
        create-prd "$@"
        ;;
    validate-prd)
        validate-prd "$@"
        ;;
    decompose)
        decompose "$@"
        ;;
    generate-spec)
        generate-spec "$@"
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'" >&2
        echo "Usage: $0 {status|brief|research|create-prd|validate-prd|decompose|generate-spec} ..." >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  status [project-name]                      - Assess project readiness and show next steps" >&2
        echo "  brief <project-name>                       - Create product brief template" >&2
        echo "  research <project-name>                    - Create research template" >&2
        echo "  create-prd <project-name>                  - Create PRD template" >&2
        echo "  validate-prd <project-name> [--lenient]    - Validate PRD quality" >&2
        echo "  decompose <project-name>                   - Break PRD into epics" >&2
        echo "  generate-spec <project-name> <epic-name>   - Generate spec proposal from epic" >&2
        exit 1
        ;;
esac
