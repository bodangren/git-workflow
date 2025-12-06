#!/bin/bash
# This script scaffolds the basic directory structure for a AgenticDev project.

set -e

usage() {
    echo "Usage: $0 [-d <directory>]"
    echo "  -d <directory>: The root directory of the project to initialize. Defaults to the current directory."
    exit 1
}

PROJECT_DIR="."

while getopts ":d:" opt; do
  case ${opt} in
    d )
      PROJECT_DIR=$OPTARG
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
shift $((OPTIND -1))

# Ensure the project directory exists
mkdir -p "$PROJECT_DIR"

# Check if docs directory already exists with content
if [ -d "$PROJECT_DIR/docs" ]; then
    # Count markdown files in docs/ (excluding docs/specs/ and docs/changes/)
    EXISTING_DOCS=$(find "$PROJECT_DIR/docs" -type f -name "*.md" ! -path "*/specs/*" ! -path "*/changes/*" 2>/dev/null | wc -l)

    if [ "$EXISTING_DOCS" -gt 0 ]; then
        echo "⚠️  Existing documentation detected in $PROJECT_DIR/docs/"
        echo ""
        echo "Found $EXISTING_DOCS markdown file(s) that may need migration."
        echo ""
        echo "💡 Recommendation: Use the 'project-migrate' skill instead!"
        echo ""
        echo "The project-migrate skill will:"
        echo "  • Discover and catalog your existing documentation"
        echo "  • Suggest appropriate locations (specs/, changes/, or root)"
        echo "  • Migrate files while preserving git history"
        echo "  • Update relative links automatically"
        echo "  • Add doc-indexer compliant frontmatter"
        echo "  • Create backups for safe rollback"
        echo ""
        echo "To use project-migrate:"
        echo "  bash skills/project-migrate/scripts/project-migrate.sh"
        echo ""
        echo "Or continue with basic initialization (existing docs will be preserved)..."
        read -p "Continue with project-init anyway? (y/N): " CONTINUE

        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo "Initialization cancelled. Use project-migrate skill to migrate existing docs."
            exit 0
        fi
    fi
fi

echo "Initializing AgenticDev structure in $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR/docs/specs"
mkdir -p "$PROJECT_DIR/docs/changes"
echo "✓ Done."