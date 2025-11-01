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

    echo "Creating new change proposal: $proposal_name"

    if [ -d "$proposal_dir" ]; then
        echo "Error: Proposal directory '$proposal_dir' already exists." >&2
        exit 1
    fi

    mkdir -p "$proposal_dir"
    touch "$proposal_dir/proposal.md"
    touch "$proposal_dir/spec-delta.md"
    touch "$proposal_dir/tasks.md"

    echo "Successfully created proposal in $proposal_dir"
    echo "Next step: Populate the new markdown files and open a Spec PR."
}

function update() {
    local pr_number=$1
    if [ -z "$pr_number" ]; then
        echo "Error: Pull request number not provided for 'update' command." >&2
        echo "Usage: $0 update <pr-number>" >&2
        exit 1
    fi

    echo "Fetching review comments for PR #$pr_number..."
    gh pr view "$pr_number" --comments
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