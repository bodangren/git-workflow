#!/bin/bash
# This script manages the authoring of specification proposals.

set -e

# --- COMMANDS ---

function propose() {
    local proposal_name=$1
    if [ -z "$proposal_name" ]; then
        echo "Error: Proposal name not provided for 'propose' command." >&2
        echo "Usage: $0 propose <proposal-name>" >&2
        exit 1
    fi

    local dir_name=$(echo "$proposal_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local proposal_dir="docs/changes/$dir_name"

    echo "Generating draft specification for: $proposal_name"

    if [ -d "$proposal_dir" ]; then
        echo "Error: Proposal directory '$proposal_dir' already exists." >&2
        exit 1
    fi

    mkdir -p "$proposal_dir"

    echo "Generating draft files with Gemini (chained calls for better coherence)..."

    # Step 1: Generate proposal.md and capture its content
    echo "Step 1/3: Generating proposal.md..."
    gemini -p "Generate a high-level project proposal in markdown for a feature called '${proposal_name}'. Include sections for Problem Statement, Proposed Solution, Benefits, and Success Criteria." > "$proposal_dir/proposal.md"
    local proposal_content=$(cat "$proposal_dir/proposal.md")

    # Step 2: Generate spec-delta.md using proposal.md as context
    echo "Step 2/3: Generating spec-delta.md (using proposal as context)..."
    gemini -p "Generate a detailed technical specification delta in markdown for a feature called '${proposal_name}'.

Use the following proposal as context to ensure alignment and coherence:

---
${proposal_content}
---

Based on the proposal above, create a specification delta that includes sections for:
- Overview (aligned with the proposal's problem statement and solution)
- Detailed Requirements (elaborating on the proposed solution)
- Key Design Decisions (technical choices to implement the solution)
- Potential Migration Path (if applicable)

Ensure the spec-delta directly supports and elaborates on the proposal's goals." > "$proposal_dir/spec-delta.md"
    local spec_delta_content=$(cat "$proposal_dir/spec-delta.md")

    # Step 3: Generate tasks.yml using both proposal.md and spec-delta.md as context
    echo "Step 3/3: Generating tasks.yml (using proposal and spec-delta as context)..."
    gemini -p "Generate a preliminary task breakdown in YAML format for implementing a feature called '${proposal_name}'.

Use the following proposal and specification delta as context:

**Proposal:**
---
${proposal_content}
---

**Specification Delta:**
---
${spec_delta_content}
---

Based on the proposal and spec-delta above, generate a task breakdown that follows this exact YAML structure:

epic: \"Feature: ${proposal_name}\"
tasks:
  - title: \"Task: Backend API Implementation\"
    description: \"Implement the core backend API endpoints and business logic for the ${proposal_name} feature.\"
    labels:
      type: \"feature\"
      component: \"backend\"
      priority: \"P0\"
  - title: \"Task: Frontend UI Development\"
    description: \"Create the user interface components and pages for the ${proposal_name} feature.\"
    labels:
      type: \"feature\"
      component: \"frontend\"
      priority: \"P1\"
  - title: \"Task: Database Schema\"
    description: \"Design and implement the database schema changes required for ${proposal_name}.\"
    labels:
      type: \"refactor\"
      component: \"database\"
      priority: \"P1\"
  - title: \"Task: Testing\"
    description: \"Write comprehensive unit and integration tests for the ${proposal_name} feature.\"
    labels:
      type: \"test\"
      component: \"testing\"
      priority: \"P2\"

Generate additional relevant tasks following the same structure, based on the specific requirements in the proposal and spec-delta. Each task must have title, description, and labels with type and component. The type should be one of: feature, enhancement, refactor, bug, chore, docs, test. The component should indicate which part of the system this task belongs to.

Ensure the tasks directly implement the requirements specified in the spec-delta and align with the proposal's goals." > "$proposal_dir/tasks.yml"

    echo "Successfully generated draft proposal in $proposal_dir"
    echo "Next step: Review and refine the generated markdown files, then open a Spec PR."
}

function update() {
    local pr_number=$1
    if [ -z "$pr_number" ]; then
        echo "Error: Pull request number not provided for 'update' command." >&2
        echo "Usage: $0 update <pr-number>" >&2
        exit 1
    fi

    echo "Fetching PR details and synthesizing review feedback for PR #$pr_number..."

    # Get the branch name from the PR
    local branch_name=$(gh pr view "$pr_number" --json headRefName -q '.headRefName')
    if [ -z "$branch_name" ]; then
        echo "Error: Could not determine branch name for PR #$pr_number." >&2
        exit 1
    fi

    # The directory name is derived from the branch name (e.g., spec/feature-name -> feature-name)
    local dir_name=$(echo "$branch_name" | sed 's/spec\///')
    local proposal_dir="docs/changes/$dir_name"

    if [ ! -d "$proposal_dir" ]; then
        echo "Error: Could not find proposal directory '$proposal_dir' associated with branch '$branch_name'." >&2
        echo "Please ensure you have checked out the correct branch and the proposal exists." >&2
        exit 1
    fi

    local proposal_file="$proposal_dir/proposal.md"
    local spec_delta_file="$proposal_dir/spec-delta.md"
    local tasks_file="$proposal_dir/tasks.yml"

    # Fetch all comments
    local all_comments=$(gh pr view "$pr_number" --comments)

    local gemini_prompt="Here are three specification documents and a list of review comments from a Pull Request. Please analyze the feedback and suggest how to update the documents. For each document, provide a concise summary of the suggested changes.

**Original Proposal:**
@${proposal_file}

**Original Spec Delta:**
@${spec_delta_file}

**Original Tasks:**
@${tasks_file}

**Review Comments:**
${all_comments}

Based on the feedback, provide a summary of recommended changes for each file. Structure your output with headings for each file (e.g., '### Recommended Changes for proposal.md')."

    echo "------------------------- GEMINI FEEDBACK ANALYSIS -------------------------"
    gemini -p "$gemini_prompt"
    echo "----------------------------------------------------------------------------"
    echo "Use the analysis above to update the files in '$proposal_dir'."
}

# --- MAIN --- 

COMMAND=$1
shift

case "$COMMAND" in
    propose)
        propose "$@"
        ;;
    update)
        update "$@"
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'" >&2
        echo "Usage: $0 {propose|update} ..." >&2
        exit 1
        ;;
esac