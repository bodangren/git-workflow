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

    cat > "$brief_file" << EOF
---
title: $project_name
type: product-brief
status: draft
created: $today
updated: $today
---

# Product Brief: $project_name

## Problem Statement

<!-- Describe the problem this project solves -->
<!-- What's broken or missing? -->
<!-- Who experiences this problem and how often? -->
<!-- What's the business impact? -->

## Target Users

<!-- Who will use this solution? -->
<!-- List primary and secondary user personas -->
<!-- What are their goals and pain points? -->

## Proposed Solution

<!-- High-level description of the solution -->
<!-- What will we build? -->
<!-- How does it solve the problem? -->

## Value Proposition

<!-- Why is this valuable? -->
<!-- Benefits for users -->
<!-- Benefits for business -->
<!-- Competitive advantages -->

## Success Metrics

<!-- How will we measure success? -->
<!-- Include specific, measurable targets -->
<!-- Example: "80% reduction in checkout abandonment rate" -->
<!-- Example: "95% of payments processed within 3 seconds" -->

EOF

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

    cat > "$research_file" << EOF
---
title: $project_name Research
type: research
status: in-progress
created: $today
updated: $today
---

# Research: $project_name

## Competitive Analysis

<!-- Identify 3-5 direct competitors -->
<!-- For each competitor, document: -->

### Competitor 1: [Name]
- **Strengths**: [What they do well]
- **Weaknesses**: [What they do poorly]
- **Key Features**: [Notable features]
- **Market Position**: [Their positioning]

### Competitor 2: [Name]
- **Strengths**:
- **Weaknesses**:
- **Key Features**:
- **Market Position**:

<!-- Add more competitors as needed -->

## Market Insights

<!-- Market size and trends -->
<!-- Target market segments -->
<!-- Regulatory or compliance requirements -->
<!-- Industry standards and best practices -->

## User Feedback Analysis

<!-- Common pain points with existing solutions -->
<!-- Desired features from user research -->
<!-- User preferences and expectations -->

## Technical Considerations

<!-- Technical approaches used by competitors -->
<!-- Architecture patterns and trade-offs -->
<!-- Integration requirements -->
<!-- Performance and scalability considerations -->

## Recommendations

<!-- Based on research, what should we prioritize? -->
<!-- Which features are table stakes vs differentiators? -->
<!-- What technical approach is recommended? -->
<!-- What constraints exist (compliance, budget, timeline)? -->

EOF

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

    cat > "$prd_file" << EOF
---
title: $project_name PRD
type: prd
status: draft
created: $today
updated: $today
---

# Product Requirements Document: $project_name

## Objectives

<!-- Define clear, measurable project objectives -->
<!-- Objectives should be SMART: Specific, Measurable, Achievable, Relevant, Time-bound -->

### Primary Objectives

1. **[Objective 1]**
   - [Specific goal]
   - [Measurable target]
   - [Timeline]

2. **[Objective 2]**
   - [Specific goal]
   - [Measurable target]
   - [Timeline]

### Secondary Objectives

1. [Future phase objectives]
2. [Stretch goals]

## Success Criteria

<!-- Define measurable criteria that indicate project success -->

### Launch Criteria (Must-Have)

- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

### Success Metrics (Post-Launch)

- [ ] [Measurable metric with target value]
- [ ] [Measurable metric with target value]
- [ ] [Measurable metric with target value]

### Stretch Goals

- [ ] [Ambitious but achievable goals]

## Functional Requirements

<!-- List specific, testable functional requirements -->

### FR1: [Requirement Name]
- **Description**: [What this requirement does]
- **Inputs**: [What inputs are needed]
- **Outputs**: [What outputs are produced]
- **Acceptance Criteria**:
  - [Specific, testable criterion]
  - [Specific, testable criterion]
  - [Specific, testable criterion]

### FR2: [Requirement Name]
- **Description**:
- **Inputs**:
- **Outputs**:
- **Acceptance Criteria**:
  -
  -

<!-- Add more functional requirements as needed -->

## Non-Functional Requirements

<!-- Specify quality attributes and constraints -->

### NFR1: Performance
- [Specific performance targets]
- [Response time requirements]
- [Throughput requirements]

### NFR2: Security
- [Security requirements]
- [Compliance requirements]
- [Authentication/authorization needs]

### NFR3: Reliability
- [Uptime requirements]
- [Error handling]
- [Data integrity]

### NFR4: Usability
- [User experience requirements]
- [Accessibility requirements]
- [Mobile responsiveness]

### NFR5: Scalability
- [Scaling requirements]
- [Capacity planning]
- [Performance under load]

## Constraints

<!-- Be explicit about limitations and dependencies -->

- [Technical constraints]
- [Business constraints]
- [Timeline constraints]
- [Budget constraints]
- [Integration constraints]

## Assumptions

<!-- Document assumptions that underpin the PRD -->

- [Assumption about users]
- [Assumption about technical environment]
- [Assumption about business context]
- [Assumption about resources]

## Out of Scope

<!-- Clearly state what will NOT be included -->

- [Feature/capability explicitly excluded]
- [Feature deferred to future phase]
- [Feature out of scope]

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

<!-- Break down the PRD into independently deliverable epics -->
<!-- Each epic should: -->
<!--   - Align with one or more PRD objectives -->
<!--   - Be completable in 2-4 sprints -->
<!--   - Have clear scope boundaries -->
<!--   - Provide standalone value -->

## Epic 1: [Epic Name]

**Objective**: [What this epic achieves]

**Scope**:
- [Feature/capability 1]
- [Feature/capability 2]
- [Feature/capability 3]

**Requirements Coverage**:
- [PRD requirement covered by this epic]
- [PRD requirement covered by this epic]

**Success Criteria**:
- [ ] [Measurable criterion from PRD]
- [ ] [Measurable criterion from PRD]

**Dependencies**:
- [Dependency on other epic, or "None" if foundational]

**Estimated Effort**: [Number of sprints]

**Out of Scope**:
- [What this epic does NOT include]

---

## Epic 2: [Epic Name]

**Objective**:

**Scope**:
-
-

**Requirements Coverage**:
-

**Success Criteria**:
- [ ]

**Dependencies**:
-

**Estimated Effort**:

**Out of Scope**:
-

---

## Epic Dependencies

<!-- Visualize dependencies between epics -->

\`\`\`
Epic 1: [Name] (Foundational)
  │
  ├─→ Epic 2: [Name] (Depends on Epic 1)
  └─→ Epic 3: [Name] (Depends on Epic 1)

Recommended Sequence:
1. Epic 1 (Sprint 1-3)
2. Epic 2 and Epic 3 in parallel (Sprint 4-6)
\`\`\`

## Requirements Traceability

<!-- Ensure all PRD requirements are covered -->

| Requirement | Epic(s) | Coverage |
|-------------|---------|----------|
| [PRD Req] | Epic 1 | 100% |
| [PRD Req] | Epic 2 | 100% |
| [PRD Req] | Epic 1, Epic 3 | 100% |

Total Coverage: [XX]%

## Next Steps

1. Review epic breakdown with stakeholders
2. Refine epic boundaries and dependencies
3. Use spec-authoring skill to create detailed specs for each epic
4. Transition to sprint planning once specs are approved

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
    *)
        echo "Error: Unknown command '$COMMAND'" >&2
        echo "Usage: $0 {status|brief|research|create-prd|validate-prd|decompose} ..." >&2
        echo "" >&2
        echo "Commands:" >&2
        echo "  status [project-name]        - Assess project readiness and show next steps" >&2
        echo "  brief <project-name>         - Create product brief template" >&2
        echo "  research <project-name>      - Create research template" >&2
        echo "  create-prd <project-name>    - Create PRD template" >&2
        echo "  validate-prd <project-name>  - Validate PRD quality" >&2
        echo "  decompose <project-name>     - Break PRD into epics" >&2
        exit 1
        ;;
esac
