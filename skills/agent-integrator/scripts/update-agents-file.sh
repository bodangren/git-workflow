#!/bin/bash
# This script idempotently creates or updates a SynthesisFlow agent guide in a markdown file.

set -e

usage() {
    echo "Usage: $0 [-f <filepath>]"
    echo "  -f <filepath>: The path to the markdown file to update. Defaults to AGENTS.md in the project root."
    exit 1
}

TARGET_FILE="AGENTS.md"

while getopts ":f:" opt; do
  case ${opt} in
    f )
      TARGET_FILE=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      usage
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      usage
      ;;
  esac
done

# Define the content block to be inserted/updated
read -r -d '' AGENT_CONTENT << EOM
<!-- SYNTHESIS_FLOW_START -->
# SynthesisFlow Agent Guide

This project uses SynthesisFlow, a modular, spec-driven development methodology. The workflow is broken down into several discrete skills located in the `.claude/skills/` directory.

## Core Philosophy
1.  **Specs as Code:** All specification changes are proposed and approved via Pull Requests.
2.  **Just-in-Time Context:** Use the `doc-indexer` skill to get a real-time map of all project documentation.
3.  **Sprint-Based:** Work is organized into GitHub Milestones and planned via the `sprint-planner` skill.
4.  **Atomic Issues:** Implementation is done via atomic GitHub Issues, which are executed by the `issue-executor` skill.

## Available Skillsets
- **`.claude/skills/project-init/`**: For initial project scaffolding.
- **`.claude/skills/doc-indexer/`**: For real-time documentation discovery.
- **`.claude/skills/spec-authoring/`**: For proposing and refining new specifications.
- **`.claude/skills/sprint-planner`**: For creating GitHub issues from approved specs.
- **`.claude/skills/issue-executor/`**: For implementing code for a single issue.
- **`.claude/skills/change-integrator/`**: For finalizing and archiving a completed change.
- **`.claude/skills/agent-integrator/`**: For creating or updating this guide in `AGENTS.md`.

To begin, always assess the current state by checking the git branch and running the `doc-indexer`.
<!-- SYNTHESIS_FLOW_END -->
EOM

# Ensure the target file exists
touch "$TARGET_FILE"

# Check if the markers exist in the file
if grep -q "<!-- SYNTHESIS_FLOW_START -->" "$TARGET_FILE"; then
    echo "Updating existing SynthesisFlow guide in $TARGET_FILE..."
    # Use awk to replace the content between the markers
    awk -v content="$AGENT_CONTENT" ' 
        /<!-- SYNTHESIS_FLOW_START -->/ { print content; in_block=1 }
        /<!-- SYNTHESIS_FLOW_END -->/ { in_block=0; next }
        !in_block { print }
    ' "$TARGET_FILE" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
else
    echo "Adding SynthesisFlow guide to $TARGET_FILE..."
    # Append the content to the end of the file
    echo -e "\n$AGENT_CONTENT" >> "$TARGET_FILE"
fi

echo "$TARGET_FILE has been updated successfully."