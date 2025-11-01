#!/bin/bash
# Validate SynthesisFlow skills for Claude Code compliance
# This script checks all skills in the skills/ directory for proper structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Directories
SKILLS_DIR="skills"

# Usage
usage() {
    echo "Usage: $0 [-v]"
    echo "  -v: Verbose mode (show all checks)"
    exit 1
}

# Verbose mode
VERBOSE=false
while getopts ":v" opt; do
    case ${opt} in
        v ) VERBOSE=true;;
        \? ) usage;;
    esac
done

echo "================================"
echo "SynthesisFlow Skill Validation"
echo "================================"
echo ""

# Check if skills directory exists
if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "${RED}✗ Skills directory not found: $SKILLS_DIR${NC}"
    exit 1
fi

# Function to check a single skill
validate_skill() {
    local skill_name=$1
    local skill_path="$SKILLS_DIR/$skill_name"
    local skill_passed=true

    echo "Checking skill: $skill_name"
    echo "---"

    # Check 1: SKILL.md exists
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -f "$skill_path/SKILL.md" ]; then
        echo -e "${GREEN}✓${NC} SKILL.md exists"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} SKILL.md missing"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        skill_passed=false
    fi

    # Check 2: SKILL.md has frontmatter
    if [ -f "$skill_path/SKILL.md" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        if head -1 "$skill_path/SKILL.md" | grep -q "^---$"; then
            # Check that frontmatter is properly closed
            if sed -n '2,10p' "$skill_path/SKILL.md" | grep -q "^---$"; then
                echo -e "${GREEN}✓${NC} SKILL.md has proper frontmatter"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            else
                echo -e "${RED}✗${NC} SKILL.md frontmatter not properly closed"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
                skill_passed=false
            fi
        else
            echo -e "${RED}✗${NC} SKILL.md missing frontmatter (should start with ---)"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    # Check 3: SKILL.md frontmatter has required fields
    if [ -f "$skill_path/SKILL.md" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        local has_name=false
        local has_description=false

        # Extract frontmatter (lines between first two ---)
        local frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_path/SKILL.md" | sed '1d;$d')

        if echo "$frontmatter" | grep -q "^name:"; then
            has_name=true
        fi

        if echo "$frontmatter" | grep -q "^description:"; then
            has_description=true
        fi

        if $has_name && $has_description; then
            echo -e "${GREEN}✓${NC} SKILL.md frontmatter has name and description"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            if ! $has_name; then
                echo -e "${RED}✗${NC} SKILL.md frontmatter missing 'name' field"
            fi
            if ! $has_description; then
                echo -e "${RED}✗${NC} SKILL.md frontmatter missing 'description' field"
            fi
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    # Check 4: SKILL.md length (50-300 lines)
    if [ -f "$skill_path/SKILL.md" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        local line_count=$(wc -l < "$skill_path/SKILL.md")
        if [ $line_count -ge 50 ] && [ $line_count -le 300 ]; then
            echo -e "${GREEN}✓${NC} SKILL.md length is appropriate ($line_count lines)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            if [ $line_count -lt 50 ]; then
                echo -e "${YELLOW}⚠${NC} SKILL.md is short ($line_count lines, expected 50-300)"
            else
                echo -e "${YELLOW}⚠${NC} SKILL.md is long ($line_count lines, expected 50-300)"
            fi
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    # Check 5: scripts/ directory exists
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -d "$skill_path/scripts" ]; then
        echo -e "${GREEN}✓${NC} scripts/ directory exists"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} scripts/ directory missing"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        skill_passed=false
    fi

    # Check 6: No run.sh in skill root
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ ! -f "$skill_path/run.sh" ]; then
        echo -e "${GREEN}✓${NC} No run.sh in skill root (properly moved to scripts/)"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} run.sh still exists in skill root (should be in scripts/)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        skill_passed=false
    fi

    # Check 7: scripts/ directory has at least one script
    if [ -d "$skill_path/scripts" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        local script_count=$(find "$skill_path/scripts" -name "*.sh" | wc -l)
        if [ $script_count -gt 0 ]; then
            echo -e "${GREEN}✓${NC} scripts/ directory contains $script_count script(s)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${YELLOW}⚠${NC} scripts/ directory is empty"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    # Check 8: Basic imperative form check (heuristic)
    if [ -f "$skill_path/SKILL.md" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        # Check for common non-imperative patterns
        local non_imperative_count=0

        # Look for "You should", "You can", "You must", etc.
        non_imperative_count=$(grep -c "You should\|You can\|You must\|You will\|You need" "$skill_path/SKILL.md" || true)

        if [ $non_imperative_count -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Uses imperative form (no 'You should/can/must' patterns found)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            echo -e "${YELLOW}⚠${NC} May not use imperative form ($non_imperative_count instances of 'You should/can/must')"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    # Check 9: SKILL.md has required sections
    if [ -f "$skill_path/SKILL.md" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        local has_purpose=false
        local has_when_to_use=false
        local has_workflow=false

        if grep -q "^## Purpose" "$skill_path/SKILL.md"; then
            has_purpose=true
        fi

        if grep -q "^## When to Use" "$skill_path/SKILL.md"; then
            has_when_to_use=true
        fi

        if grep -q "^## Workflow" "$skill_path/SKILL.md"; then
            has_workflow=true
        fi

        if $has_purpose && $has_when_to_use && $has_workflow; then
            echo -e "${GREEN}✓${NC} SKILL.md has required sections (Purpose, When to Use, Workflow)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            local missing=""
            if ! $has_purpose; then
                missing="$missing Purpose"
            fi
            if ! $has_when_to_use; then
                missing="$missing WhenToUse"
            fi
            if ! $has_workflow; then
                missing="$missing Workflow"
            fi
            echo -e "${RED}✗${NC} SKILL.md missing required sections:$missing"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            skill_passed=false
        fi
    fi

    echo ""

    if $skill_passed; then
        echo -e "${GREEN}✓ $skill_name: PASSED${NC}"
    else
        echo -e "${RED}✗ $skill_name: FAILED${NC}"
    fi

    echo ""
}

# Find all skill directories
skill_dirs=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

if [ -z "$skill_dirs" ]; then
    echo -e "${RED}No skills found in $SKILLS_DIR${NC}"
    exit 1
fi

# Validate each skill
for skill in $skill_dirs; do
    validate_skill "$skill"
done

# Summary
echo "================================"
echo "Validation Summary"
echo "================================"
echo "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ All skills passed validation!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some skills failed validation${NC}"
    exit 1
fi
