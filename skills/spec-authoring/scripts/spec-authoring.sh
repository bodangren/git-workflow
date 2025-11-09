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

    echo "Generating draft files with Gemini..."

    # Generate proposal.md
    gemini -p "Generate a high-level project proposal in markdown for a feature called '${proposal_name}'. Include sections for Problem Statement, Proposed Solution, Benefits, and Success Criteria." > "$proposal_dir/proposal.md" &
    
    # Generate spec-delta.md
    gemini -p "Generate a detailed technical specification delta in markdown for a feature called '${proposal_name}'. Include sections for Overview, detailed Requirements, key Design Decisions, and a potential Migration Path." > "$proposal_dir/spec-delta.md" &

    # Generate tasks.md
    gemini -p "Generate a preliminary task breakdown in markdown for implementing a feature called '${proposal_name}'. Group tasks by component (e.g., 'Backend API', 'Frontend UI') and include sub-tasks as a checklist. Also include a section for high-level Acceptance Criteria." > "$proposal_dir/tasks.md" &

    wait # Wait for all background Gemini processes to finish

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
    local tasks_file="$proposal_dir/tasks.md"

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