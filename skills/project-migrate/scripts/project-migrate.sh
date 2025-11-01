#!/bin/bash
# Project Migrate Script
# Migrates existing (brownfield) projects to SynthesisFlow structure

set -e

# Configuration
DRY_RUN=false
AUTO_APPROVE=false
BACKUP_DIR=""
MIGRATION_MANIFEST=""

# Global arrays for discovered files
declare -a DISCOVERED_FILES=()
declare -A FILE_TYPES=()
declare -A FILE_CATEGORIES=()

# Function to detect documentation type from file path and name
detect_file_type() {
  local file="$1"
  local basename=$(basename "$file")
  local lowercase=$(echo "$file" | tr '[:upper:]' '[:lower:]')

  # ADR (Architectural Decision Record)
  if [[ "$lowercase" =~ adr-[0-9]+ ]] || [[ "$lowercase" =~ /decisions/ ]] || [[ "$lowercase" =~ decision.*record ]]; then
    echo "adr"
    return
  fi

  # Retrospective
  if [[ "$lowercase" =~ retrospective ]]; then
    echo "retrospective"
    return
  fi

  # Spec / Specification
  if [[ "$lowercase" =~ spec ]] || [[ "$lowercase" =~ specification ]] || [[ "$lowercase" =~ requirements ]]; then
    echo "spec"
    return
  fi

  # Proposal / RFC / Draft
  if [[ "$lowercase" =~ proposal ]] || [[ "$lowercase" =~ rfc ]] || [[ "$lowercase" =~ draft ]]; then
    echo "proposal"
    return
  fi

  # Design doc
  if [[ "$lowercase" =~ design ]] || [[ "$lowercase" =~ architecture ]]; then
    echo "design"
    return
  fi

  # Plan
  if [[ "$lowercase" =~ plan ]] || [[ "$lowercase" =~ roadmap ]]; then
    echo "plan"
    return
  fi

  # README (special case - keep in place)
  if [[ "$basename" =~ ^README\.md$ ]] || [[ "$basename" =~ ^readme\.md$ ]]; then
    echo "readme"
    return
  fi

  # Default: general documentation
  echo "doc"
}

# Function to discover markdown files
discover_files() {
  local search_paths=(
    "docs"
    "documentation"
    "wiki"
    "."  # Root level for READMEs and other top-level docs
  )

  echo "Scanning for markdown files..."

  for search_path in "${search_paths[@]}"; do
    if [ ! -d "$search_path" ]; then
      continue
    fi

    # Find all .md files, excluding .git directory and node_modules
    while IFS= read -r -d '' file; do
      # Skip files in .git, node_modules, and hidden directories (except root level)
      if [[ "$file" =~ /\. ]] || [[ "$file" =~ node_modules ]] || [[ "$file" =~ /\.git/ ]]; then
        continue
      fi

      # For root search, only include direct .md files, not in subdirectories
      if [ "$search_path" = "." ]; then
        # Normalize path (remove leading ./)
        normalized="${file#./}"
        # Skip if file is in a subdirectory (contains /)
        if [[ "$normalized" =~ / ]]; then
          continue
        fi
      fi

      DISCOVERED_FILES+=("$file")

      # Detect and store file type
      local file_type=$(detect_file_type "$file")
      FILE_TYPES["$file"]="$file_type"

    done < <(find "$search_path" -maxdepth $([ "$search_path" = "." ] && echo "1" || echo "10") -name "*.md" -type f -print0 2>/dev/null)
  done

  # Sort discovered files for consistent output
  IFS=$'\n' DISCOVERED_FILES=($(sort <<<"${DISCOVERED_FILES[*]}"))
  unset IFS
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--auto-approve]"
      exit 1
      ;;
  esac
done

echo "========================================"
echo " Project Migrate: Brownfield to SynthesisFlow"
echo "========================================"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "Mode: DRY RUN (no changes will be made)"
elif [ "$AUTO_APPROVE" = true ]; then
  echo "Mode: AUTO-APPROVE (minimal prompts)"
else
  echo "Mode: INTERACTIVE (review each phase)"
fi
echo ""

# Phase 1: Discovery
echo "Phase 1: Discovery"
echo "------------------"
echo "Scanning project for existing documentation..."
echo ""

# Run discovery
discover_files

# Display inventory summary
echo "Discovery complete! Found ${#DISCOVERED_FILES[@]} markdown file(s)"
echo ""

if [ ${#DISCOVERED_FILES[@]} -eq 0 ]; then
  echo "No markdown files found. Nothing to migrate."
  exit 0
fi

# Group files by type for summary
declare -A type_counts=()
for file in "${DISCOVERED_FILES[@]}"; do
  file_type="${FILE_TYPES[$file]}"
  type_counts["$file_type"]=$((${type_counts[$file_type]:-0} + 1))
done

echo "Inventory by type:"
for file_type in $(echo "${!type_counts[@]}" | tr ' ' '\n' | sort); do
  count="${type_counts[$file_type]}"
  printf "  %-15s %3d file(s)\n" "$file_type:" "$count"
done
echo ""

echo "Discovered files:"
for file in "${DISCOVERED_FILES[@]}"; do
  file_type="${FILE_TYPES[$file]}"
  printf "  [%-13s] %s\n" "$file_type" "$file"
done
echo ""

# Phase 2: Analysis
echo "Phase 2: Analysis"
echo "-----------------"
echo "Categorizing discovered content..."
echo ""
# TODO: Implement analysis logic (Task 3)
echo "[Not yet implemented]"
echo ""

# Phase 3: Planning
echo "Phase 3: Planning"
echo "-----------------"
echo "Generating migration plan..."
echo ""
# TODO: Implement planning logic (Task 4)
echo "[Not yet implemented]"
echo ""

# Phase 4: Backup
echo "Phase 4: Backup"
echo "---------------"
echo "Creating backup before migration..."
echo ""
# TODO: Implement backup logic (Task 5)
echo "[Not yet implemented]"
echo ""

# Phase 5: Migration
echo "Phase 5: Migration"
echo "------------------"
echo "Executing file migrations..."
echo ""
# TODO: Implement migration logic (Task 6)
echo "[Not yet implemented]"
echo ""

# Phase 6: Frontmatter Generation
echo "Phase 6: Frontmatter Generation"
echo "-------------------------------"
echo "Adding YAML frontmatter to files..."
echo ""
# TODO: Implement frontmatter generation logic (Task 9)
echo "[Not yet implemented]"
echo ""

# Phase 7: Validation
echo "Phase 7: Validation"
echo "-------------------"
echo "Verifying migration success..."
echo ""
# TODO: Implement validation logic (Task 8)
echo "[Not yet implemented]"
echo ""

echo "========================================"
echo " Migration Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Review migrated files"
echo "  2. Run doc-indexer to catalog documentation"
echo "  3. Begin using SynthesisFlow workflow"
echo ""
echo "Backup location: [not yet created]"
echo "To rollback: [rollback script not yet generated]"
echo ""
