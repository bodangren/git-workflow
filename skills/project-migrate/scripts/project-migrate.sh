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
declare -A FILE_TARGETS=()
declare -A FILE_RATIONALES=()
declare -A FILE_CONFLICTS=()

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

# Function to determine target category based on file type
categorize_file() {
  local file="$1"
  local file_type="$2"

  case "$file_type" in
    spec)
      echo "spec"
      ;;
    proposal)
      echo "proposal"
      ;;
    adr)
      echo "spec"  # ADRs are architectural specs
      ;;
    design)
      echo "spec"  # Design docs are architectural specs
      ;;
    plan)
      echo "spec"  # Plans are planning specs
      ;;
    retrospective)
      echo "root"  # Retrospectives stay at root
      ;;
    readme)
      echo "preserve"  # READMEs stay in place
      ;;
    doc)
      echo "doc"  # General documentation
      ;;
    *)
      echo "doc"  # Default to general documentation
      ;;
  esac
}

# Function to generate target path for a file
generate_target_path() {
  local file="$1"
  local category="$2"
  local file_type="$3"
  local basename=$(basename "$file")
  local dirname=$(dirname "$file")

  case "$category" in
    spec)
      # Check if already in docs/specs/
      if [[ "$dirname" == "docs/specs" ]]; then
        echo "$file"
      else
        # Preserve subdirectory structure to avoid name collisions
        if [[ "$dirname" == docs/changes/* ]]; then
          # Extract subdirectory name from docs/changes/subdir/file.md
          local subdir=$(echo "$dirname" | sed 's|docs/changes/||')
          echo "docs/specs/$subdir/$basename"
        else
          echo "docs/specs/$basename"
        fi
      fi
      ;;
    proposal)
      # Check if already in docs/changes/
      if [[ "$dirname" == docs/changes/* ]]; then
        echo "$file"
      else
        echo "docs/changes/$basename"
      fi
      ;;
    doc)
      # Check if already in docs/ (but not docs/specs or docs/changes)
      if [[ "$dirname" == "docs" ]]; then
        echo "$file"
      else
        # Preserve subdirectory structure to avoid name collisions
        if [[ "$dirname" == docs/changes/* ]]; then
          # Extract subdirectory name from docs/changes/subdir/file.md
          local subdir=$(echo "$dirname" | sed 's|docs/changes/||')
          echo "docs/$subdir/$basename"
        else
          echo "docs/$basename"
        fi
      fi
      ;;
    root)
      # Retrospectives become RETROSPECTIVE.md at root
      if [ "$file_type" = "retrospective" ]; then
        echo "RETROSPECTIVE.md"
      else
        echo "$basename"
      fi
      ;;
    preserve)
      # Keep in original location
      echo "$file"
      ;;
    *)
      echo "docs/$basename"
      ;;
  esac
}

# Function to get rationale for categorization
get_categorization_rationale() {
  local file="$1"
  local file_type="$2"
  local category="$3"
  local target="$4"

  # Check if file is already in target location
  if [ "$file" = "$target" ]; then
    echo "Already in correct location (no move needed)"
    return
  fi

  case "$category" in
    spec)
      if [ "$file_type" = "spec" ]; then
        echo "Specification → docs/specs/ (SynthesisFlow source-of-truth)"
      elif [ "$file_type" = "adr" ]; then
        echo "ADR → docs/specs/ (architectural decisions are specs)"
      elif [ "$file_type" = "design" ]; then
        echo "Design doc → docs/specs/ (architectural documentation)"
      elif [ "$file_type" = "plan" ]; then
        echo "Plan → docs/specs/ (planning documentation)"
      else
        echo "→ docs/specs/"
      fi
      ;;
    proposal)
      echo "Proposal → docs/changes/ (proposed changes under review)"
      ;;
    doc)
      echo "General documentation → docs/"
      ;;
    root)
      echo "Retrospective → root/RETROSPECTIVE.md (SynthesisFlow convention)"
      ;;
    preserve)
      echo "README preserved in original location"
      ;;
    *)
      echo "→ docs/"
      ;;
  esac
}

# Function to check for conflicts
check_conflict() {
  local source="$1"
  local target="$2"

  # Normalize paths for comparison (remove leading ./)
  local normalized_source="${source#./}"
  local normalized_target="${target#./}"

  # If source and target are the same, no conflict (already in place)
  if [ "$normalized_source" = "$normalized_target" ]; then
    echo "in_place"
    return
  fi

  # Check if target already exists and is not the source
  if [ -f "$target" ] && [ "$normalized_source" != "$normalized_target" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# Function to analyze discovered files
analyze_files() {
  echo "Categorizing files and detecting conflicts..."
  echo ""

  for file in "${DISCOVERED_FILES[@]}"; do
    local file_type="${FILE_TYPES[$file]}"

    # Determine category
    local category=$(categorize_file "$file" "$file_type")
    FILE_CATEGORIES["$file"]="$category"

    # Generate target path
    local target=$(generate_target_path "$file" "$category" "$file_type")
    FILE_TARGETS["$file"]="$target"

    # Get rationale (now includes file and target for "already in place" detection)
    local rationale=$(get_categorization_rationale "$file" "$file_type" "$category" "$target")
    FILE_RATIONALES["$file"]="$rationale"

    # Check for conflicts (now includes source to detect "already in place")
    local has_conflict=$(check_conflict "$file" "$target")
    FILE_CONFLICTS["$file"]="$has_conflict"
  done
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

# Run analysis
analyze_files

# Display analysis results with rationale
echo "Analysis complete!"
echo ""

# Count conflicts and in-place files
conflict_count=0
in_place_count=0
for file in "${DISCOVERED_FILES[@]}"; do
  if [ "${FILE_CONFLICTS[$file]}" = "true" ]; then
    conflict_count=$((conflict_count + 1))
  elif [ "${FILE_CONFLICTS[$file]}" = "in_place" ]; then
    in_place_count=$((in_place_count + 1))
  fi
done

if [ $conflict_count -gt 0 ]; then
  echo "⚠️  WARNING: $conflict_count conflict(s) detected"
  echo ""
fi

if [ $in_place_count -gt 0 ]; then
  echo "ℹ️  INFO: $in_place_count file(s) already in correct location"
  echo ""
fi

# Group by category for summary
declare -A category_counts=()
for file in "${DISCOVERED_FILES[@]}"; do
  category="${FILE_CATEGORIES[$file]}"
  category_counts["$category"]=$((${category_counts[$category]:-0} + 1))
done

echo "Migration plan by category:"
for category in $(echo "${!category_counts[@]}" | tr ' ' '\n' | sort); do
  count="${category_counts[$category]}"
  case "$category" in
    spec)
      target_desc="docs/specs/"
      ;;
    proposal)
      target_desc="docs/changes/"
      ;;
    doc)
      target_desc="docs/"
      ;;
    root)
      target_desc="root/"
      ;;
    preserve)
      target_desc="(preserved in place)"
      ;;
    *)
      target_desc="$category"
      ;;
  esac
  printf "  %-10s → %-25s %3d file(s)\n" "$category" "$target_desc" "$count"
done
echo ""

echo "Detailed migration plan:"
for file in "${DISCOVERED_FILES[@]}"; do
  file_type="${FILE_TYPES[$file]}"
  target="${FILE_TARGETS[$file]}"
  rationale="${FILE_RATIONALES[$file]}"
  has_conflict="${FILE_CONFLICTS[$file]}"

  # Format output with status indicator
  if [ "$has_conflict" = "true" ]; then
    conflict_marker="⚠️ "
  elif [ "$has_conflict" = "in_place" ]; then
    conflict_marker="✓  "
  else
    conflict_marker="   "
  fi

  printf "%s%-40s → %-40s\n" "$conflict_marker" "$file" "$target"
  printf "   %s\n" "$rationale"

  if [ "$has_conflict" = "true" ]; then
    printf "   WARNING: Target file already exists - will need conflict resolution!\n"
  fi
  echo ""
done
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
