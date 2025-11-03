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
