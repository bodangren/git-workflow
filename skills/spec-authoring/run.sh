#!/bin/bash
# This script manages the authoring of specification proposals.

set -e

PROPOSAL_NAME=$2

if [ -z "$PROPOSAL_NAME" ]; then
    echo "Error: Proposal name not provided."
    echo "Usage: $0 propose <proposal-name>"
    exit 1
fi

# Sanitize the proposal name to be used as a directory name
DIR_NAME=$(echo "$PROPOSAL_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PROPOSAL_DIR="docs/changes/$DIR_NAME"

# --- COMMANDS ---

function propose() {
    echo "Creating new change proposal: $PROPOSAL_NAME"

    if [ -d "$PROPOSAL_DIR" ]; then
        echo "Error: Proposal directory '$PROPOSAL_DIR' already exists."
        exit 1
    fi

    mkdir -p "$PROPOSAL_DIR"

    touch "$PROPOSAL_DIR/proposal.md"
    touch "$PROPOSAL_DIR/spec-delta.md"
    touch "$PROPOSAL_DIR/tasks.md"

    echo "Successfully created proposal in $PROPOSAL_DIR"
    echo "Next step: Populate the new markdown files and open a Spec PR."
}

function update() {
    echo "Error: The 'update' command is not yet implemented." >&2
    exit 1
}

# --- MAIN --- 

case "$1" in
    propose)
        propose
        ;;
    update)
        update
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo "Usage: $0 {propose|update} <proposal-name>"
        exit 1
        ;;
esac
