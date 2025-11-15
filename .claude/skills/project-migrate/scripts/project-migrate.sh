#!/bin/bash
# Project Migrate Script
# Migrates existing (brownfield) projects to SynthesisFlow structure

set -e

# Configuration
DRY_RUN=false
AUTO_APPROVE=false
INTERACTIVE=true
BACKUP_DIR=""
MIGRATION_MANIFEST=""

# Global arrays for discovered files
declare -a DISCOVERED_FILES=()
declare -A FILE_TYPES=()
declare -A FILE_CATEGORIES=()
declare -A FILE_TARGETS=()
declare -A FILE_RATIONALES=()
declare -A FILE_CONFLICTS=()

# Function to prompt for phase continuation
prompt_phase_continue() {
  local phase_name="$1"
  local phase_description="$2"

  if [ "$INTERACTIVE" = false ] || [ "$DRY_RUN" = true ]; then
    return 0
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Ready to proceed to: $phase_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$phase_description"
  echo ""
  read -p "Continue to $phase_name? [Y/n]: " response

  case "$response" in
    n|N|no|No|NO)
      echo ""
      echo "Migration paused. You can:"
      echo "  • Review the output above"
      echo "  • Run with --dry-run to see the complete plan"
      echo "  • Run again when ready to continue"
      echo ""
      exit 0
      ;;
    *)
      echo ""
      return 0
      ;;
  esac
}

# Function to show progress indicator
show_progress() {
  local current="$1"
  local total="$2"
  local description="$3"

  local percentage=$((current * 100 / total))
  local filled=$((percentage / 5))
  local empty=$((20 - filled))

  printf "\r[%-20s] %3d%% - %s" \
    "$(printf '#%.0s' $(seq 1 $filled))$(printf ' %.0s' $(seq 1 $empty))" \
    "$percentage" \
    "$description"

  if [ "$current" -eq "$total" ]; then
    echo ""
  fi
}

# Function to detect documentation type using Gemini
detect_file_type() {
  local file="$1"
  local basename=$(basename "$file")

  # Handle README as a special case based on filename, not content
  if [[ "$basename" =~ ^README\.md$ ]] || [[ "$basename" =~ ^readme\.md$ ]]; then
    echo "readme"
    return
  fi

  echo "Analyzing $file with Gemini to determine type..." >&2

  # Use a temporary file for the prompt to handle special characters
  local prompt_file=$(mktemp)
  echo "Analyze the following document and determine its type. The type must be one of: 'spec', 'proposal', 'adr', 'design', 'plan', 'retrospective', or 'doc'. Return only the type as a single word." > "$prompt_file"
  
  # Call Gemini with the file and the prompt
  local detected_type=$(gemini -p "@${prompt_file} @${file}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  rm "$prompt_file"

  # Validate the output from Gemini
  case "$detected_type" in
    spec|proposal|adr|design|plan|retrospective|doc)
      echo "$detected_type"
      ;;
    *)
      echo "doc" # Default if Gemini returns an invalid type or fails
      ;;
  esac
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
      INTERACTIVE=false
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
  echo "🔍 Mode: DRY RUN"
  echo "   No changes will be made to your files."
  echo "   Review the complete migration plan safely."
elif [ "$AUTO_APPROVE" = true ]; then
  echo "⚡ Mode: AUTO-APPROVE"
  echo "   Migration will proceed with minimal prompts."
  echo "   Conflicts will be skipped automatically."
  echo "   Frontmatter generation will be skipped (requires manual review)."
else
  echo "👤 Mode: INTERACTIVE"
  echo "   You'll review and approve each phase."
  echo "   Prompts will guide you through the process."
  echo "   You can pause at any time."
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Discovery complete! Found ${#DISCOVERED_FILES[@]} markdown file(s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

# Prompt to continue to Analysis phase
prompt_phase_continue "Phase 2: Analysis" \
  "This phase will categorize discovered files and generate migration targets.
   Files will be assigned to docs/specs/, docs/changes/, or docs/ based on type.
   Conflicts with existing files will be detected."

# Phase 2: Analysis
echo "Phase 2: Analysis"
echo "-----------------"
echo "Categorizing discovered content..."
echo ""

# Run analysis
analyze_files

# Display analysis results with rationale
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Analysis complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

# Prompt to continue to Planning phase
prompt_phase_continue "Phase 3: Planning" \
  "This phase will generate a detailed migration plan showing all file movements.
   You'll be able to review, modify, or save the plan before execution.
   The plan will be saved to a manifest file for reference."

# Function to generate JSON migration plan
generate_migration_plan_json() {
  echo "{"
  echo "  \"timestamp\": \"$(date -Iseconds)\","
  echo "  \"total_files\": ${#DISCOVERED_FILES[@]},"
  echo "  \"conflict_count\": $conflict_count,"
  echo "  \"in_place_count\": $in_place_count,"
  echo "  \"migrations\": ["

  local first=true
  for file in "${DISCOVERED_FILES[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      echo ","
    fi

    local file_type="${FILE_TYPES[$file]}"
    local category="${FILE_CATEGORIES[$file]}"
    local target="${FILE_TARGETS[$file]}"
    local rationale="${FILE_RATIONALES[$file]}"
    local has_conflict="${FILE_CONFLICTS[$file]}"

    # Escape double quotes in strings for JSON
    file_escaped=$(echo "$file" | sed 's/"/\\"/g')
    target_escaped=$(echo "$target" | sed 's/"/\\"/g')
    rationale_escaped=$(echo "$rationale" | sed 's/"/\\"/g')

    echo -n "    {"
    echo -n "\"source\": \"$file_escaped\", "
    echo -n "\"target\": \"$target_escaped\", "
    echo -n "\"type\": \"$file_type\", "
    echo -n "\"category\": \"$category\", "
    echo -n "\"rationale\": \"$rationale_escaped\", "
    echo -n "\"conflict\": \"$has_conflict\""
    echo -n "}"
  done

  echo ""
  echo "  ]"
  echo "}"
}

# Function to display human-readable plan summary
display_plan_summary() {
  echo "Migration Plan Summary"
  echo "======================"
  echo ""
  echo "Total files discovered: ${#DISCOVERED_FILES[@]}"
  echo "Files to migrate: $((${#DISCOVERED_FILES[@]} - in_place_count))"
  echo "Files already in place: $in_place_count"
  echo "Conflicts detected: $conflict_count"
  echo ""

  if [ $conflict_count -gt 0 ]; then
    echo "⚠️  CONFLICTS REQUIRING RESOLUTION:"
    for file in "${DISCOVERED_FILES[@]}"; do
      if [ "${FILE_CONFLICTS[$file]}" = "true" ]; then
        printf "  • %s → %s\n" "$file" "${FILE_TARGETS[$file]}"
        printf "    Resolution: Will prompt for action (skip/rename/overwrite)\n"
      fi
    done
    echo ""
  fi

  echo "MIGRATION ACTIONS:"
  echo ""

  # Group by action type
  local move_count=0
  local skip_count=0

  for file in "${DISCOVERED_FILES[@]}"; do
    if [ "${FILE_CONFLICTS[$file]}" = "in_place" ]; then
      skip_count=$((skip_count + 1))
    else
      move_count=$((move_count + 1))
    fi
  done

  echo "Files to move: $move_count"
  if [ $move_count -gt 0 ]; then
    for file in "${DISCOVERED_FILES[@]}"; do
      if [ "${FILE_CONFLICTS[$file]}" != "in_place" ]; then
        local target="${FILE_TARGETS[$file]}"
        local conflict_marker=""
        if [ "${FILE_CONFLICTS[$file]}" = "true" ]; then
          conflict_marker=" ⚠️"
        fi
        printf "  %s → %s%s\n" "$file" "$target" "$conflict_marker"
      fi
    done
  fi
  echo ""

  echo "Files to skip (already in place): $skip_count"
  if [ $skip_count -gt 0 ]; then
    for file in "${DISCOVERED_FILES[@]}"; do
      if [ "${FILE_CONFLICTS[$file]}" = "in_place" ]; then
        printf "  ✓ %s\n" "$file"
      fi
    done
  fi
  echo ""
}

# Function to prompt for plan approval
prompt_plan_approval() {
  if [ "$AUTO_APPROVE" = true ]; then
    echo "Auto-approve enabled, proceeding with migration..."
    return 0
  fi

  echo ""
  echo "Review the migration plan above."
  echo ""
  echo "Options:"
  echo "  a) Approve and proceed"
  echo "  m) Modify plan (adjust target paths)"
  echo "  s) Save plan and exit (for review)"
  echo "  c) Cancel migration"
  echo ""
  read -p "Choose [a/m/s/c]: " choice

  case "$choice" in
    a|A)
      echo "Plan approved. Proceeding with migration..."
      return 0
      ;;
    m|M)
      echo "Plan modification selected."
      modify_plan_interactive
      return $?
      ;;
    s|S)
      echo "Saving plan to manifest..."
      generate_migration_plan_json > "$MIGRATION_MANIFEST"
      echo "Plan saved to: $MIGRATION_MANIFEST"
      echo "Review the plan and run the migration again when ready."
      exit 0
      ;;
    c|C)
      echo "Migration cancelled."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      prompt_plan_approval
      ;;
  esac
}

# Function to modify plan interactively
modify_plan_interactive() {
  echo ""
  echo "Plan Modification Mode"
  echo "======================"
  echo ""
  echo "You can adjust target paths for individual files."
  echo "Type 'done' when finished, or 'cancel' to abort."
  echo ""

  while true; do
    echo "Files available for modification:"
    local index=1
    for file in "${DISCOVERED_FILES[@]}"; do
      printf "%2d) %s → %s\n" "$index" "$file" "${FILE_TARGETS[$file]}"
      index=$((index + 1))
    done
    echo ""
    echo "Type the number of the file to modify (or 'done'/'cancel'):"
    read -p "> " input

    case "$input" in
      done|DONE|d|D)
        echo "Modifications complete."
        return 0
        ;;
      cancel|CANCEL|c|C)
        echo "Modifications cancelled. Returning to plan review..."
        prompt_plan_approval
        return $?
        ;;
      ''|*[!0-9]*)
        echo "Invalid input. Please enter a number, 'done', or 'cancel'."
        continue
        ;;
      *)
        if [ "$input" -ge 1 ] && [ "$input" -le ${#DISCOVERED_FILES[@]} ]; then
          local file="${DISCOVERED_FILES[$((input - 1))]}"
          local current_target="${FILE_TARGETS[$file]}"

          echo ""
          echo "File: $file"
          echo "Current target: $current_target"
          echo ""
          read -p "Enter new target path (or press Enter to keep current): " new_target

          if [ -n "$new_target" ]; then
            FILE_TARGETS["$file"]="$new_target"
            echo "Updated target to: $new_target"

            # Re-check conflict status with new target
            local has_conflict=$(check_conflict "$file" "$new_target")
            FILE_CONFLICTS["$file"]="$has_conflict"

            if [ "$has_conflict" = "true" ]; then
              echo "⚠️  Warning: New target conflicts with existing file!"
            fi
          else
            echo "Target unchanged."
          fi
          echo ""
        else
          echo "Invalid number. Please choose between 1 and ${#DISCOVERED_FILES[@]}."
        fi
        ;;
    esac
  done
}

# Function to save migration plan
save_migration_plan() {
  echo "Saving migration plan to manifest..."

  # Generate manifest filename with timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  MIGRATION_MANIFEST=".project-migrate-manifest-${timestamp}.json"

  generate_migration_plan_json > "$MIGRATION_MANIFEST"

  if [ -f "$MIGRATION_MANIFEST" ]; then
    echo "✓ Migration plan saved to: $MIGRATION_MANIFEST"
    echo ""
    echo "Manifest contains:"
    echo "  - Timestamp: $(date -Iseconds)"
    echo "  - Total files: ${#DISCOVERED_FILES[@]}"
    echo "  - Source → target mappings"
    echo "  - Conflict information"
    echo "  - File types and categories"
    echo ""
  else
    echo "⚠️  Error: Failed to save migration plan!"
    return 1
  fi
}

# Phase 3: Planning
echo "Phase 3: Planning"
echo "-----------------"
echo "Generating migration plan..."
echo ""

# Display human-readable plan summary
display_plan_summary

# Save plan to manifest file
save_migration_plan

# Prompt for plan approval (unless dry-run)
if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Plan generated but no actions will be taken."
  echo "Review the plan above and the manifest file: $MIGRATION_MANIFEST"
  echo ""
else
  prompt_plan_approval
fi

echo ""

# Prompt to continue to Backup phase
prompt_phase_continue "Phase 4: Backup" \
  "This phase will create a complete backup of your docs/ directory.
   A timestamped backup directory will be created with rollback scripts.
   This ensures you can safely restore the original state if needed."

# Function to create backup
create_backup() {
  # Generate timestamped backup directory name
  local timestamp=$(date +%Y%m%d-%H%M%S)
  BACKUP_DIR=".synthesisflow-backup-${timestamp}"

  echo "Creating backup directory: $BACKUP_DIR"

  # Create backup directory
  if ! mkdir -p "$BACKUP_DIR"; then
    echo "⚠️  Error: Failed to create backup directory!"
    return 1
  fi

  # Copy existing docs/ directory to backup location if it exists
  if [ -d "docs" ]; then
    echo "Backing up existing docs/ directory..."
    if ! cp -r docs "$BACKUP_DIR/docs"; then
      echo "⚠️  Error: Failed to backup docs/ directory!"
      return 1
    fi
    echo "✓ Backed up docs/ directory"
  else
    echo "ℹ️  No existing docs/ directory to backup"
  fi

  # Store migration manifest in backup directory
  if [ -f "$MIGRATION_MANIFEST" ]; then
    echo "Storing migration manifest in backup..."
    if ! cp "$MIGRATION_MANIFEST" "$BACKUP_DIR/migration-manifest.json"; then
      echo "⚠️  Error: Failed to store migration manifest!"
      return 1
    fi
    echo "✓ Stored migration manifest"
  fi

  # Create backup README with restoration instructions
  echo "Creating backup README..."
  cat > "$BACKUP_DIR/README.md" <<'EOF'
# SynthesisFlow Migration Backup

This directory contains a backup of your project documentation before SynthesisFlow migration.

## Backup Contents

- `docs/` - Complete backup of your original docs/ directory (if it existed)
- `migration-manifest.json` - The migration plan that was executed
- `rollback.sh` - Script to restore the original state

## Restoration Procedure

If you need to rollback the migration and restore your original documentation:

### Option 1: Use the Rollback Script

Run the provided rollback script from your project root:

```bash
bash BACKUP_DIR/rollback.sh
```

This will:
1. Create a safety backup of the current state (before rollback)
2. Restore the original docs/ directory from backup
3. Remove SynthesisFlow additions (docs/specs/, docs/changes/) if they're empty
4. Preserve any non-empty directories to prevent data loss
5. Clean up empty directories

### Option 2: Manual Restoration

If you prefer manual control:

1. **Backup current state** (in case you want to keep some changes):
   ```bash
   mv docs docs-after-migration
   ```

2. **Restore original docs/**:
   ```bash
   cp -r BACKUP_DIR/docs .
   ```

3. **Clean up** (if desired):
   ```bash
   rm -rf docs-after-migration
   ```

## Safety Notes

- This backup is READ-ONLY - never modify files in this directory
- Keep this backup until you're confident the migration was successful
- The rollback script is safe to run - it won't delete this backup
- You can manually inspect files in this backup at any time

## Backup Metadata

- Created: TIMESTAMP
- Migration manifest: migration-manifest.json
- Original location: PROJECT_ROOT

## Questions?

Refer to the SynthesisFlow documentation or the project-migrate skill documentation.
EOF

  # Replace placeholders in README
  sed -i "s|BACKUP_DIR|$BACKUP_DIR|g" "$BACKUP_DIR/README.md"
  sed -i "s|TIMESTAMP|$(date -Iseconds)|g" "$BACKUP_DIR/README.md"
  sed -i "s|PROJECT_ROOT|$(pwd)|g" "$BACKUP_DIR/README.md"

  echo "✓ Created backup README"

  # Generate rollback script
  echo "Generating rollback script..."
  cat > "$BACKUP_DIR/rollback.sh" <<'ROLLBACK_SCRIPT'
#!/bin/bash
# SynthesisFlow Migration Rollback Script
# This script restores your project to its pre-migration state

set -e

echo "========================================"
echo " SynthesisFlow Migration Rollback"
echo "========================================"
echo ""
echo "⚠️  WARNING: This will restore your project to its pre-migration state."
echo "   Any changes made after migration will be lost!"
echo ""

# Get the backup directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$(basename "$SCRIPT_DIR")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Backup directory: $BACKUP_DIR"
echo "Project root: $PROJECT_ROOT"
echo ""

read -p "Are you sure you want to rollback? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Rollback cancelled."
  exit 0
fi

echo ""
echo "Starting rollback..."
echo ""

cd "$PROJECT_ROOT"

# Step 1: Backup current state (safety measure)
echo "Step 1: Creating safety backup of current state..."

SAFETY_BACKUP_DIR="${BACKUP_DIR}_current_state_$(date +%Y%m%d-%H%M%S)"

if [ -d "docs" ]; then
  echo "  Backing up current docs/ to $SAFETY_BACKUP_DIR..."
  mkdir -p "$SAFETY_BACKUP_DIR"
  cp -r docs "$SAFETY_BACKUP_DIR/docs"
  echo "✓ Current state backed up (just in case)"
else
  echo "ℹ️  No current docs/ directory to backup"
fi

echo ""

# Step 2: Restore original docs/ directory
echo "Step 2: Restoring original docs/ directory from backup..."

if [ -d "$BACKUP_DIR/docs" ]; then
  # Remove current docs/ directory if it exists
  if [ -d "docs" ]; then
    echo "  Removing current docs/ directory..."
    rm -rf docs
  fi

  echo "  Copying backup docs/ to project root..."
  cp -r "$BACKUP_DIR/docs" .
  echo "✓ Original docs/ directory restored"
else
  echo "ℹ️  No original docs/ directory to restore"
  echo "  This suggests the project had no docs/ before migration"
fi

echo ""

# Step 3: Remove SynthesisFlow additions (only if they're now empty or were created by migration)
echo "Step 3: Cleaning up SynthesisFlow-specific directories..."

# Load the migration manifest to determine what was created
if [ -f "$BACKUP_DIR/migration-manifest.json" ]; then
  echo "  Using migration manifest to identify SynthesisFlow additions..."
fi

# Check if docs/specs should be removed (empty or only contains migrated files)
if [ -d "docs/specs" ]; then
  # Check if directory is empty
  if [ -z "$(ls -A docs/specs 2>/dev/null)" ]; then
    echo "  Removing empty docs/specs/..."
    rmdir docs/specs
  else
    # Directory has content - check if it existed in original backup
    if [ -d "$BACKUP_DIR/docs/specs" ]; then
      echo "  ℹ️  docs/specs/ existed before migration, keeping it"
    else
      echo "  ⚠️  docs/specs/ has content and wasn't in original backup"
      echo "     Keeping it to prevent data loss (manual review recommended)"
    fi
  fi
fi

# Check if docs/changes should be removed (empty or only contains migrated files)
if [ -d "docs/changes" ]; then
  # Check if directory is empty
  if [ -z "$(ls -A docs/changes 2>/dev/null)" ]; then
    echo "  Removing empty docs/changes/..."
    rmdir docs/changes
  else
    # Directory has content - check if it existed in original backup
    if [ -d "$BACKUP_DIR/docs/changes" ]; then
      echo "  ℹ️  docs/changes/ existed before migration, keeping it"
    else
      echo "  ⚠️  docs/changes/ has content and wasn't in original backup"
      echo "     Keeping it to prevent data loss (manual review recommended)"
    fi
  fi
fi

# Remove docs/ only if it's now completely empty
if [ -d "docs" ] && [ -z "$(ls -A docs 2>/dev/null)" ]; then
  echo "  Removing empty docs/ directory..."
  rmdir docs
fi

echo "✓ SynthesisFlow directory cleanup complete"
echo ""

# Step 4: Clean up empty parent directories (but preserve structure)
echo "Step 4: Cleaning up empty directories..."

# Only clean up directories that are truly empty (not .git or hidden)
find . -type d -empty -not -path "./.git/*" -not -path "*/\.*" -delete 2>/dev/null || true

echo "✓ Cleanup complete"
echo ""

echo "========================================"
echo " Rollback Complete!"
echo "========================================"
echo ""
echo "Your project has been restored to its pre-migration state."
echo ""
echo "Backup information:"
echo "  • Original backup: $BACKUP_DIR (preserved)"
echo "  • Safety backup of pre-rollback state: $SAFETY_BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Verify your documentation is restored correctly"
echo "  2. Review any warnings above about non-empty directories"
echo "  3. Delete backups when confident:"
echo "     rm -rf $BACKUP_DIR"
echo "     rm -rf $SAFETY_BACKUP_DIR"
echo ""
ROLLBACK_SCRIPT

  # Make rollback script executable
  chmod +x "$BACKUP_DIR/rollback.sh"
  echo "✓ Generated rollback script"

  echo ""
  echo "✓ Backup complete!"
  echo ""
  echo "Backup location: $BACKUP_DIR"
  echo "  - Original docs/: $BACKUP_DIR/docs/"
  echo "  - Migration plan: $BACKUP_DIR/migration-manifest.json"
  echo "  - Restoration guide: $BACKUP_DIR/README.md"
  echo "  - Rollback script: $BACKUP_DIR/rollback.sh"
  echo ""
  echo "To rollback this migration: bash $BACKUP_DIR/rollback.sh"
  echo ""

  return 0
}

# Phase 4: Backup
echo "Phase 4: Backup"
echo "---------------"
echo "Creating backup before migration..."
echo ""

# Skip backup in dry-run mode
if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Backup would be created here"
  echo "  Backup directory name would be: .synthesisflow-backup-$(date +%Y%m%d-%H%M%S)"
  echo "  Would backup: docs/ directory (if exists)"
  echo "  Would include: migration manifest, README, rollback script"
  echo ""
else
  # Create backup
  if ! create_backup; then
    echo "⚠️  Error: Backup failed! Migration aborted."
    exit 1
  fi
fi

echo ""

# Prompt to continue to Migration phase
prompt_phase_continue "Phase 5: Migration" \
  "This phase will execute the file migrations using git mv when possible.
   Files will be moved to their target locations and links will be updated.
   You'll be prompted to resolve any conflicts that occur."

# Function to create SynthesisFlow directory structure
create_directory_structure() {
  echo "Creating SynthesisFlow directory structure..."

  local dirs=("docs" "docs/specs" "docs/changes")

  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      if ! mkdir -p "$dir"; then
        echo "⚠️  Error: Failed to create directory: $dir"
        return 1
      fi
      echo "✓ Created directory: $dir"
    else
      echo "ℹ️  Directory already exists: $dir"
    fi
  done

  echo ""
  return 0
}

# Function to calculate relative path from one file to another
calculate_relative_path() {
  local from_file="$1"
  local to_file="$2"

  # Get directories containing the files
  local from_dir=$(dirname "$from_file")
  local to_dir=$(dirname "$to_file")
  local to_base=$(basename "$to_file")

  # Normalize . to empty string for easier comparison
  if [ "$from_dir" = "." ]; then from_dir=""; fi
  if [ "$to_dir" = "." ]; then to_dir=""; fi

  # If both in same directory, just return the filename
  if [ "$from_dir" = "$to_dir" ]; then
    echo "$to_base"
    return
  fi

  # Convert paths to arrays for comparison
  IFS='/' read -ra from_parts <<< "$from_dir"
  IFS='/' read -ra to_parts <<< "$to_dir"

  # Find common prefix length
  local common_length=0
  local max_length=${#from_parts[@]}
  if [ ${#to_parts[@]} -lt $max_length ]; then
    max_length=${#to_parts[@]}
  fi

  for ((i=0; i<max_length; i++)); do
    if [ "${from_parts[$i]}" = "${to_parts[$i]}" ]; then
      ((common_length++))
    else
      break
    fi
  done

  # Calculate number of "../" needed
  local up_count=$((${#from_parts[@]} - common_length))
  local result=""
  for ((i=0; i<up_count; i++)); do
    result="${result}../"
  done

  # Add the remaining path from common to target
  for ((i=common_length; i<${#to_parts[@]}; i++)); do
    result="${result}${to_parts[$i]}/"
  done

  # Add the filename
  echo "${result}${to_base}"
}

# Function to update relative links in a markdown file
update_markdown_links() {
  local file="$1"
  local old_location="$2"
  local new_location="$3"

  # Skip if file is in same location
  if [ "$old_location" = "$new_location" ]; then
    return 0
  fi

  # Track statistics
  local links_found=0
  local links_updated=0
  local links_broken=0

  # Get directories for path calculations
  local old_dir=$(dirname "$old_location")
  local new_dir=$(dirname "$new_location")

  # Create temporary file for updated content
  local temp_file=$(mktemp)

  # Read file line by line and update links
  while IFS= read -r line; do
    local updated_line="$line"

    # Find all markdown links: [text](path) and ![alt](path)
    # Use grep to find lines with links, then process each link
    if echo "$line" | grep -qE '\[[^]]*\]\([^)]+\)'; then
      # Extract and process each link on the line using a simpler approach
      local temp_line="$line"
      local link_pattern='\[([^]]*)\]\(([^)]+)\)'

      while [[ "$temp_line" =~ $link_pattern ]]; do
        local link_text="${BASH_REMATCH[1]}"
        local link_path="${BASH_REMATCH[2]}"

        # Skip absolute URLs (http://, https://, etc.)
        if [[ "$link_path" =~ ^https?:// ]] || [[ "$link_path" =~ ^mailto: ]] || [[ "$link_path" =~ ^# ]]; then
          # Remove this match from temp_line to find next link
          temp_line="${temp_line#*]($link_path)}"
          continue
        fi

        links_found=$((links_found + 1))

        # Calculate the absolute path of the linked file from old location
        local linked_file_abs=""
        if [[ "$link_path" = /* ]]; then
          # Absolute path from project root
          linked_file_abs="$link_path"
        else
          # Relative path from old location
          if [ "$old_dir" = "." ]; then
            linked_file_abs="$link_path"
          else
            linked_file_abs="$old_dir/$link_path"
          fi
        fi

        # Normalize path (remove ./ and resolve ..)
        linked_file_abs=$(echo "$linked_file_abs" | sed 's|/\./|/|g')

        # Calculate new relative path from new location to linked file
        local new_link_path=$(calculate_relative_path "$new_location" "$linked_file_abs")

        # Update the link in the line if it changed
        if [ "$link_path" != "$new_link_path" ]; then
          updated_line=$(echo "$updated_line" | sed "s|]($link_path)|]($new_link_path)|")
          links_updated=$((links_updated + 1))

          # Validate that the linked file exists
          if [ ! -f "$linked_file_abs" ] && [ ! -d "$linked_file_abs" ]; then
            links_broken=$((links_broken + 1))
            if [ "$DRY_RUN" = false ]; then
              echo "    ⚠️  Warning: Link target not found: $link_path → $new_link_path (target: $linked_file_abs)" >&2
            fi
          fi
        fi

        # Remove this match from temp_line to find next link
        temp_line="${temp_line#*]($link_path)}"
      done
    fi

    echo "$updated_line" >> "$temp_file"
  done < "$file"

  # Replace original file with updated content if changes were made
  if [ "$links_updated" -gt 0 ]; then
    if [ "$DRY_RUN" = false ]; then
      mv "$temp_file" "$file"
      echo "    Updated $links_updated link(s) in $(basename "$file") (found: $links_found, broken: $links_broken)"
    else
      echo "    [DRY RUN] Would update $links_updated link(s) in $(basename "$file") (found: $links_found, broken: $links_broken)"
      rm "$temp_file"
    fi
  else
    rm "$temp_file"
    if [ "$links_found" -gt 0 ]; then
      echo "    No link updates needed in $(basename "$file") ($links_found link(s) already correct)"
    fi
  fi

  return 0
}

# Function to move a single file
migrate_file() {
  local source="$1"
  local target="$2"
  local use_git_mv="${3:-true}"

  # Normalize paths
  local normalized_source="${source#./}"
  local normalized_target="${target#./}"

  # Check if source and target are the same
  if [ "$normalized_source" = "$normalized_target" ]; then
    echo "  ✓ $source (already in place)"
    return 0
  fi

  # Create target directory if it doesn't exist
  local target_dir=$(dirname "$target")
  if [ ! -d "$target_dir" ]; then
    if ! mkdir -p "$target_dir"; then
      echo "  ⚠️  Error: Failed to create directory: $target_dir"
      return 1
    fi
  fi

  # Check if target already exists
  if [ -f "$target" ]; then
    echo "  ⚠️  Conflict: Target already exists: $target"

    # In auto-approve mode, skip conflicts
    if [ "$AUTO_APPROVE" = true ]; then
      echo "     Auto-approve mode: Skipping conflicted file"
      return 0
    fi

    # Prompt for resolution
    echo "     Options: (s)kip, (r)ename source, (o)verwrite"
    read -p "     Choose [s/r/o]: " resolution

    case "$resolution" in
      r|R)
        # Rename by adding numeric suffix
        local base="${target%.*}"
        local ext="${target##*.}"
        local counter=1
        local new_target="${base}-${counter}.${ext}"

        while [ -f "$new_target" ]; do
          counter=$((counter + 1))
          new_target="${base}-${counter}.${ext}"
        done

        echo "     Renaming to: $new_target"
        target="$new_target"
        ;;
      o|O)
        echo "     Overwriting target file..."
        rm -f "$target"
        ;;
      s|S|*)
        echo "     Skipping file"
        return 0
        ;;
    esac
  fi

  # Perform the move
  if [ "$use_git_mv" = true ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Use git mv to preserve history
    if git mv "$source" "$target" 2>/dev/null; then
      echo "  ✓ $source → $target (git mv)"
      return 0
    else
      # Fall back to regular mv if git mv fails
      if mv "$source" "$target"; then
        echo "  ✓ $source → $target (mv)"
        return 0
      else
        echo "  ⚠️  Error: Failed to move file: $source"
        return 1
      fi
    fi
  else
    # Use regular mv
    if mv "$source" "$target"; then
      echo "  ✓ $source → $target (mv)"
      return 0
    else
      echo "  ⚠️  Error: Failed to move file: $source"
      return 1
    fi
  fi
}

# Function to execute migration
execute_migration() {
  echo "Creating SynthesisFlow directory structure..."
  if ! create_directory_structure; then
    echo "⚠️  Error: Failed to create directory structure!"
    return 1
  fi
  echo ""

  echo "Migrating files..."
  echo ""

  local success_count=0
  local skip_count=0
  local error_count=0
  local total_to_migrate=0

  # Count files that need migration
  for file in "${DISCOVERED_FILES[@]}"; do
    local normalized_source="${file#./}"
    local target="${FILE_TARGETS[$file]}"
    local normalized_target="${target#./}"

    if [ "$normalized_source" != "$normalized_target" ]; then
      total_to_migrate=$((total_to_migrate + 1))
    fi
  done

  echo "Files to migrate: $total_to_migrate"
  echo ""

  # Migrate each file
  for file in "${DISCOVERED_FILES[@]}"; do
    local target="${FILE_TARGETS[$file]}"
    local conflict="${FILE_CONFLICTS[$file]}"

    # Skip files already in place
    if [ "$conflict" = "in_place" ]; then
      skip_count=$((skip_count + 1))
      continue
    fi

    # Migrate the file
    if migrate_file "$file" "$target" true; then
      success_count=$((success_count + 1))

      # Update links in the migrated file
      update_markdown_links "$target" "$file" "$target"
    else
      error_count=$((error_count + 1))
    fi
  done

  echo ""
  echo "Migration Results:"
  echo "  ✓ Migrated: $success_count file(s)"
  echo "  ⊘ Skipped: $skip_count file(s) (already in place)"

  if [ $error_count -gt 0 ]; then
    echo "  ⚠️  Errors: $error_count file(s)"
    return 1
  fi

  echo ""
  return 0
}

# Phase 5: Migration
echo "Phase 5: Migration"
echo "------------------"
echo "Executing file migrations..."
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Migration would execute here"
  echo ""
  echo "Would create directories:"
  echo "  - docs/"
  echo "  - docs/specs/"
  echo "  - docs/changes/"
  echo ""
  echo "Would migrate $((${#DISCOVERED_FILES[@]} - in_place_count)) file(s):"
  for file in "${DISCOVERED_FILES[@]}"; do
    target="${FILE_TARGETS[$file]}"
    conflict="${FILE_CONFLICTS[$file]}"

    if [ "$conflict" != "in_place" ]; then
      conflict_marker=""
      if [ "$conflict" = "true" ]; then
        conflict_marker=" ⚠️"
      fi
      echo "  $file → $target$conflict_marker"
    fi
  done
  echo ""
else
  # Execute migration
  if ! execute_migration; then
    echo "⚠️  Error: Migration failed!"
    echo ""
    echo "To rollback: bash $BACKUP_DIR/rollback.sh"
    exit 1
  fi
fi

echo ""

# Prompt to continue to Frontmatter phase
prompt_phase_continue "Phase 6: Frontmatter Generation" \
  "This phase will add YAML frontmatter to files that don't have it.
   You'll review each suggested frontmatter (title, type, metadata).
   You can accept, edit, skip individual files, or batch-apply to all."

# Function to generate frontmatter for a file using Gemini
generate_frontmatter() {
  local file="$1"
  echo "Generating frontmatter for $file with Gemini..." >&2

  # Get git metadata if available
  local git_metadata_prompt=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local creation_date=$(git log --follow --format=%aI --reverse "$file" 2>/dev/null | head -n 1)
    local author=$(git log --follow --format='%an' --reverse "$file" 2>/dev/null | head -n 1)
    if [ -n "$creation_date" ] && [ -n "$author" ]; then
      git_metadata_prompt="The file was created on '${creation_date}' by '${author}'. Use these for the 'created' and 'author' fields."
    fi
  fi

  local prompt_file=$(mktemp)
  cat > "$prompt_file" <<EOF
Analyze the following document and generate a complete YAML frontmatter for it.
The frontmatter must include:
- 'title': A concise, descriptive title based on the content.
- 'type': One of 'spec', 'proposal', 'adr', 'design', 'plan', 'retrospective', or 'doc'.
- 'description': A one-sentence summary of the document's purpose.
- 'created': The creation date.
- 'author': The original author.

${git_metadata_prompt}

Return *only* the complete YAML block starting with '---' and ending with '---'. Do not include any other text or explanation.
EOF

  # Call Gemini with the file and the prompt
  local generated_frontmatter=$(gemini -p "@${prompt_file} @${file}")
  rm "$prompt_file"

  # Basic validation and fallback
  if echo "$generated_frontmatter" | head -n 1 | grep -q '^---$'; then
    echo "$generated_frontmatter"
  else
    # Fallback to a very basic frontmatter if Gemini fails
    echo "---"
    echo "title: $(basename "$file")"
    echo "type: doc"
    echo "description: (migration placeholder)"
    echo "---"
  fi
}

# Function to check if file has frontmatter
has_frontmatter() {
  local file="$1"

  # Check if file starts with ---
  if head -n 1 "$file" 2>/dev/null | grep -q '^---$'; then
    return 0  # Has frontmatter
  else
    return 1  # No frontmatter
  fi
}

# Function to validate YAML syntax (basic check)
validate_yaml_frontmatter() {
  local frontmatter="$1"

  # Check basic structure: starts and ends with ---
  if ! echo "$frontmatter" | head -n 1 | grep -q '^---$'; then
    return 1
  fi

  if ! echo "$frontmatter" | tail -n 1 | grep -q '^---$'; then
    return 1
  fi

  # Check for key: value pattern in middle lines
  local middle=$(echo "$frontmatter" | sed '1d;$d')
  if [ -n "$middle" ]; then
    # Each line should be "key: value" format
    if echo "$middle" | grep -qv '^[a-zA-Z_][a-zA-Z0-9_]*: '; then
      return 1
    fi
  fi

  return 0
}

# Function to insert frontmatter at top of file
insert_frontmatter() {
  local file="$1"
  local frontmatter="$2"

  # Create temporary file
  local temp_file=$(mktemp)

  # Write frontmatter
  echo "$frontmatter" > "$temp_file"
  echo "" >> "$temp_file"

  # Append original content
  cat "$file" >> "$temp_file"

  # Replace original file
  mv "$temp_file" "$file"

  return 0
}

# Function to display frontmatter suggestion and get user approval
review_frontmatter_suggestion() {
  local file="$1"
  local suggested_frontmatter="$2"
  local batch_mode="${3:-false}"

  echo ""
  echo "File: $file"
  echo ""
  echo "Suggested frontmatter:"
  echo "$suggested_frontmatter"
  echo ""

  if [ "$batch_mode" = "true" ]; then
    # In batch mode, auto-apply
    return 0
  fi

  echo "Options:"
  echo "  a) Accept and insert"
  echo "  e) Edit before inserting"
  echo "  s) Skip this file"
  echo "  b) Batch apply to all remaining files"
  echo ""
  read -p "Choose [a/e/s/b]: " choice

  case "$choice" in
    a|A)
      return 0  # Accept
      ;;
    e|E)
      return 2  # Edit
      ;;
    s|S)
      return 1  # Skip
      ;;
    b|B)
      return 3  # Batch mode
      ;;
    *)
      echo "Invalid choice. Skipping file..."
      return 1
      ;;
  esac
}

# Function to edit frontmatter interactively
edit_frontmatter() {
  local original="$1"

  # Create temp file with original
  local temp_file=$(mktemp)
  echo "$original" > "$temp_file"

  # Use editor (EDITOR env var or nano as fallback)
  ${EDITOR:-nano} "$temp_file"

  # Read edited content
  local edited=$(cat "$temp_file")
  rm "$temp_file"

  echo "$edited"
}

# Function to run frontmatter generation phase
generate_frontmatter_phase() {
  local batch_mode=false
  local files_processed=0
  local files_updated=0
  local files_skipped=0
  local files_already_compliant=0

  echo "Scanning for files without frontmatter..."
  echo ""

  # Collect all markdown files in docs/
  local -a files_to_process=()

  if [ -d "docs" ]; then
    while IFS= read -r -d '' file; do
      # Skip hidden files and directories
      if [[ "$file" =~ /\. ]]; then
        continue
      fi

      # Check if file has frontmatter
      if ! has_frontmatter "$file"; then
        files_to_process+=("$file")
      else
        files_already_compliant=$((files_already_compliant + 1))
      fi
    done < <(find docs -name "*.md" -type f -print0)
  fi

  echo "Found ${#files_to_process[@]} file(s) without frontmatter"
  echo "Found $files_already_compliant file(s) already compliant"
  echo ""

  if [ ${#files_to_process[@]} -eq 0 ]; then
    echo "✓ All files already have frontmatter!"
    return 0
  fi

  # Process each file
  for file in "${files_to_process[@]}"; do
    files_processed=$((files_processed + 1))

    # Generate suggested frontmatter
    local suggested=$(generate_frontmatter "$file")

    # Validate YAML syntax
    if ! validate_yaml_frontmatter "$suggested"; then
      echo "⚠️  Warning: Generated frontmatter has invalid YAML syntax for: $file"
      echo "Skipping this file..."
      files_skipped=$((files_skipped + 1))
      continue
    fi

    # Review suggestion
    review_frontmatter_suggestion "$file" "$suggested" "$batch_mode"
    local review_result=$?

    case $review_result in
      0)
        # Accept - insert frontmatter
        if insert_frontmatter "$file" "$suggested"; then
          echo "✓ Frontmatter inserted into: $file"
          files_updated=$((files_updated + 1))
        else
          echo "⚠️  Error: Failed to insert frontmatter into: $file"
          files_skipped=$((files_skipped + 1))
        fi
        ;;
      1)
        # Skip
        echo "Skipped: $file"
        files_skipped=$((files_skipped + 1))
        ;;
      2)
        # Edit
        echo "Opening editor for frontmatter..."
        local edited=$(edit_frontmatter "$suggested")

        # Validate edited frontmatter
        if ! validate_yaml_frontmatter "$edited"; then
          echo "⚠️  Error: Edited frontmatter has invalid YAML syntax. Skipping..."
          files_skipped=$((files_skipped + 1))
          continue
        fi

        # Insert edited frontmatter
        if insert_frontmatter "$file" "$edited"; then
          echo "✓ Custom frontmatter inserted into: $file"
          files_updated=$((files_updated + 1))
        else
          echo "⚠️  Error: Failed to insert frontmatter into: $file"
          files_skipped=$((files_skipped + 1))
        fi
        ;;
      3)
        # Batch mode - apply to this and all remaining
        echo "Batch mode enabled. Applying to all remaining files..."
        batch_mode=true

        # Insert frontmatter for current file
        if insert_frontmatter "$file" "$suggested"; then
          echo "✓ Frontmatter inserted into: $file"
          files_updated=$((files_updated + 1))
        else
          echo "⚠️  Error: Failed to insert frontmatter into: $file"
          files_skipped=$((files_skipped + 1))
        fi
        ;;
    esac
  done

  echo ""
  echo "Frontmatter Generation Results:"
  echo "  Files processed: $files_processed"
  echo "  Files updated: $files_updated"
  echo "  Files skipped: $files_skipped"
  echo "  Files already compliant: $files_already_compliant"
  echo ""

  # Run doc-indexer scan to confirm compliance
  if command -v bash >/dev/null 2>&1 && [ -f "skills/doc-indexer/scripts/scan-docs.sh" ]; then
    echo "Running doc-indexer compliance check..."
    echo ""
    bash skills/doc-indexer/scripts/scan-docs.sh | grep -E "^\[WARNING\]|^---" | head -20
    echo ""
  fi

  return 0
}

# Phase 6: Frontmatter Generation
echo "Phase 6: Frontmatter Generation"
echo "-------------------------------"
echo "Adding YAML frontmatter to files..."
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Frontmatter generation would execute here"
  echo ""
  echo "Would scan docs/ for files without frontmatter"
  echo "Would generate suggested frontmatter for each file:"
  echo "  - Extract title from first # heading or filename"
  echo "  - Detect file type (spec, proposal, design, adr, etc.)"
  echo "  - Extract git metadata (creation date, author)"
  echo "  - Generate YAML frontmatter"
  echo "  - Validate YAML syntax"
  echo "  - Prompt for review and approval"
  echo ""
elif [ "$AUTO_APPROVE" = true ]; then
  echo "Auto-approve mode: Skipping frontmatter generation (requires manual review)"
  echo "Run without --auto-approve to interactively add frontmatter"
  echo ""
else
  # Execute frontmatter generation
  generate_frontmatter_phase
fi

echo ""

# Prompt to continue to Validation phase
prompt_phase_continue "Phase 7: Validation" \
  "This phase will verify the migration was successful.
   It checks directory structure, file locations, counts, and link integrity.
   A comprehensive validation report will be generated."

# Function to validate migration
validate_migration() {
  echo "Running post-migration validation..."
  echo ""

  local validation_errors=0
  local validation_warnings=0

  # Validation 1: Check SynthesisFlow directory structure exists
  echo "1. Checking SynthesisFlow directory structure..."
  local required_dirs=("docs" "docs/specs" "docs/changes")
  local missing_dirs=0

  for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
      echo "  ✓ $dir exists"
    else
      echo "  ⚠️  $dir NOT FOUND"
      missing_dirs=$((missing_dirs + 1))
      validation_errors=$((validation_errors + 1))
    fi
  done

  if [ $missing_dirs -eq 0 ]; then
    echo "  ✓ All required directories exist"
  else
    echo "  ⚠️  Missing $missing_dirs required director(ies)"
  fi
  echo ""

  # Validation 2: Check all source files are in target locations
  echo "2. Verifying file migrations..."
  local files_verified=0
  local files_missing=0
  local files_skipped=0

  for file in "${DISCOVERED_FILES[@]}"; do
    local target="${FILE_TARGETS[$file]}"
    local normalized_source="${file#./}"
    local normalized_target="${target#./}"

    # Check if file was supposed to stay in place
    if [ "$normalized_source" = "$normalized_target" ]; then
      if [ -f "$file" ]; then
        files_verified=$((files_verified + 1))
        files_skipped=$((files_skipped + 1))
      else
        echo "  ⚠️  File missing: $file (should have been preserved in place)"
        files_missing=$((files_missing + 1))
        validation_errors=$((validation_errors + 1))
      fi
    else
      # File should have been moved to target
      if [ -f "$target" ]; then
        files_verified=$((files_verified + 1))
      else
        echo "  ⚠️  Target file missing: $target (source: $file)"
        files_missing=$((files_missing + 1))
        validation_errors=$((validation_errors + 1))
      fi
    fi
  done

  echo "  ✓ Files verified in target locations: $files_verified"
  if [ $files_skipped -gt 0 ]; then
    echo "    (includes $files_skipped file(s) that stayed in place)"
  fi

  if [ $files_missing -gt 0 ]; then
    echo "  ⚠️  Missing files: $files_missing"
  fi
  echo ""

  # Validation 3: Compare file counts (discovered vs migrated)
  echo "3. Comparing file counts..."
  local discovered_count=${#DISCOVERED_FILES[@]}
  local expected_migrated=$((discovered_count - in_place_count))

  echo "  Files discovered: $discovered_count"
  echo "  Files expected to migrate: $expected_migrated"
  echo "  Files that stayed in place: $in_place_count"
  echo "  Files verified: $files_verified"

  local count_mismatch=$((discovered_count - files_verified))
  if [ $count_mismatch -eq 0 ]; then
    echo "  ✓ All discovered files accounted for"
  else
    echo "  ⚠️  File count mismatch: $count_mismatch file(s) unaccounted for"
    validation_errors=$((validation_errors + 1))
  fi
  echo ""

  # Validation 4: Validate link integrity in migrated files
  echo "4. Validating link integrity..."
  local total_links=0
  local broken_links=0
  local files_with_links=0

  for file in "${DISCOVERED_FILES[@]}"; do
    local target="${FILE_TARGETS[$file]}"
    local file_to_check=""

    # Determine which file to check (target if moved, source if in place)
    local normalized_source="${file#./}"
    local normalized_target="${target#./}"

    if [ "$normalized_source" = "$normalized_target" ]; then
      file_to_check="$file"
    else
      file_to_check="$target"
    fi

    # Check if file exists before validating links
    if [ ! -f "$file_to_check" ]; then
      continue
    fi

    # Parse markdown links in the file
    local file_has_links=false
    while IFS= read -r line; do
      # Find markdown links: [text](path) and ![alt](path)
      if echo "$line" | grep -qE '\[[^]]*\]\([^)]+\)'; then
        local temp_line="$line"
        local link_pattern='\[([^]]*)\]\(([^)]+)\)'

        while [[ "$temp_line" =~ $link_pattern ]]; do
          local link_path="${BASH_REMATCH[2]}"

          # Skip absolute URLs and anchors
          if [[ "$link_path" =~ ^https?:// ]] || [[ "$link_path" =~ ^mailto: ]] || [[ "$link_path" =~ ^# ]]; then
            temp_line="${temp_line#*]($link_path)}"
            continue
          fi

          file_has_links=true
          total_links=$((total_links + 1))

          # Calculate absolute path of linked file
          local file_dir=$(dirname "$file_to_check")
          local linked_file_abs=""

          if [[ "$link_path" = /* ]]; then
            # Absolute path from project root
            linked_file_abs="$link_path"
          else
            # Relative path from file location
            if [ "$file_dir" = "." ]; then
              linked_file_abs="$link_path"
            else
              linked_file_abs="$file_dir/$link_path"
            fi
          fi

          # Normalize path
          linked_file_abs=$(echo "$linked_file_abs" | sed 's|/\./|/|g' | sed 's|^\./||')

          # Check if linked file/directory exists
          if [ ! -f "$linked_file_abs" ] && [ ! -d "$linked_file_abs" ]; then
            echo "  ⚠️  Broken link in $file_to_check: $link_path → $linked_file_abs"
            broken_links=$((broken_links + 1))
            validation_warnings=$((validation_warnings + 1))
          fi

          # Remove this match to find next link
          temp_line="${temp_line#*]($link_path)}"
        done
      fi
    done < "$file_to_check"

    if [ "$file_has_links" = true ]; then
      files_with_links=$((files_with_links + 1))
    fi
  done

  echo "  Files with links: $files_with_links"
  echo "  Total links found: $total_links"

  if [ $broken_links -eq 0 ]; then
    echo "  ✓ No broken links detected"
  else
    echo "  ⚠️  Broken links found: $broken_links"
    echo "  Note: Some links may point to files outside the migration scope"
  fi
  echo ""

  # Validation 5: Generate validation report summary
  echo "========================================
Validation Report Summary
========================================"
  echo ""

  if [ $validation_errors -eq 0 ] && [ $validation_warnings -eq 0 ]; then
    echo "✅ VALIDATION PASSED"
    echo ""
    echo "All checks passed successfully!"
    echo "  • SynthesisFlow directory structure exists"
    echo "  • All discovered files accounted for ($discovered_count)"
    echo "  • File counts match expectations"
    echo "  • No broken links detected"
  elif [ $validation_errors -eq 0 ]; then
    echo "⚠️  VALIDATION PASSED WITH WARNINGS"
    echo ""
    echo "Migration completed but with $validation_warnings warning(s):"
    if [ $broken_links -gt 0 ]; then
      echo "  • $broken_links broken link(s) detected"
      echo "    Suggestion: Review and update broken links manually"
    fi
  else
    echo "❌ VALIDATION FAILED"
    echo ""
    echo "Migration completed with $validation_errors error(s) and $validation_warnings warning(s):"
    if [ $missing_dirs -gt 0 ]; then
      echo "  • $missing_dirs required director(ies) missing"
      echo "    Suggestion: Run migration again or create directories manually"
    fi
    if [ $files_missing -gt 0 ]; then
      echo "  • $files_missing file(s) missing from target locations"
      echo "    Suggestion: Check backup and restore missing files"
    fi
    if [ $count_mismatch -ne 0 ]; then
      echo "  • File count mismatch: $count_mismatch file(s) unaccounted for"
      echo "    Suggestion: Compare discovered files with migrated files"
    fi
    if [ $broken_links -gt 0 ]; then
      echo "  • $broken_links broken link(s) detected"
      echo "    Suggestion: Review and update broken links manually"
    fi
  fi
  echo ""

  return $validation_errors
}

# Phase 7: Validation
echo "Phase 7: Validation"
echo "-------------------"
echo "Verifying migration success..."
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN: Validation would execute here"
  echo ""
  echo "Would verify:"
  echo "  1. SynthesisFlow directory structure exists (docs/, docs/specs/, docs/changes/)"
  echo "  2. All source files are in target locations"
  echo "  3. File counts match (discovered: ${#DISCOVERED_FILES[@]}, to migrate: $((${#DISCOVERED_FILES[@]} - in_place_count)))"
  echo "  4. Link integrity (no broken links)"
  echo "  5. Generate comprehensive validation report"
  echo ""
else
  # Execute validation
  if ! validate_migration; then
    echo "⚠️  Validation detected errors. Please review the report above."
    echo ""
    if [ -n "$BACKUP_DIR" ]; then
      echo "To rollback: bash $BACKUP_DIR/rollback.sh"
    fi
    echo ""
  fi
fi

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

# Display backup information if backup was created
if [ -n "$BACKUP_DIR" ] && [ "$DRY_RUN" != true ]; then
  echo "Backup location: $BACKUP_DIR"
  echo "To rollback: bash $BACKUP_DIR/rollback.sh"
else
  echo "Backup location: [dry-run mode - no backup created]"
  echo "To rollback: [dry-run mode - no rollback script generated]"
fi
echo ""
