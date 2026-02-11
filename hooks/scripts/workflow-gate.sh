#!/usr/bin/env bash
# MiniSpec Hook: workflow-gate
# Verifies MiniSpec workflow requirements are met before implementation
#
# Usage: ./workflow-gate.sh <check-type> [feature-name]
# Check types: design, tasks, both
# Exit 0 = requirements met, Exit 1 = requirements not met

set -euo pipefail

CHECK_TYPE="${1:-both}"
FEATURE_NAME="${2:-}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Find .minispec directory
MINISPEC_DIR=""
SEARCH_DIR="$(pwd)"
while [[ "$SEARCH_DIR" != "/" ]]; do
    if [[ -d "$SEARCH_DIR/.minispec" ]]; then
        MINISPEC_DIR="$SEARCH_DIR/.minispec"
        break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [[ -z "$MINISPEC_DIR" ]]; then
    echo -e "${YELLOW}Warning: .minispec directory not found. Skipping workflow gate.${NC}"
    exit 0
fi

SPECS_DIR="$MINISPEC_DIR/specs"
MISSING=()

# Determine feature directory
if [[ -n "$FEATURE_NAME" ]]; then
    FEATURE_DIR="$SPECS_DIR/$FEATURE_NAME"
elif [[ -n "${MINISPEC_FEATURE:-}" ]]; then
    FEATURE_DIR="$SPECS_DIR/$MINISPEC_FEATURE"
else
    # Try to find the most recently modified feature
    if [[ -d "$SPECS_DIR" ]]; then
        FEATURE_DIR=$(ls -td "$SPECS_DIR"/*/ 2>/dev/null | head -1)
    fi
fi

check_design() {
    if [[ -z "$FEATURE_DIR" ]] || [[ ! -f "$FEATURE_DIR/design.md" ]]; then
        MISSING+=("design.md")
        return 1
    fi
    return 0
}

check_tasks() {
    if [[ -z "$FEATURE_DIR" ]] || [[ ! -f "$FEATURE_DIR/tasks.md" ]]; then
        MISSING+=("tasks.md")
        return 1
    fi
    return 0
}

case "$CHECK_TYPE" in
    design)
        check_design || true
        ;;
    tasks)
        check_tasks || true
        ;;
    both|*)
        check_design || true
        check_tasks || true
        ;;
esac

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}MiniSpec: Workflow Requirements Not Met${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Missing required files:"
    for file in "${MISSING[@]}"; do
        echo -e "  ${YELLOW}✗ $file${NC}"
    done
    echo ""
    echo "Before implementing, please run:"
    if [[ " ${MISSING[*]} " =~ " design.md " ]]; then
        echo "  /minispec.design     - Create feature design"
    fi
    if [[ " ${MISSING[*]} " =~ " tasks.md " ]]; then
        echo "  /minispec.tasks      - Break design into tasks"
    fi
    echo ""
    echo "This ensures you have a clear plan before writing code."
    echo ""
    exit 1
fi

echo -e "${GREEN}Workflow requirements met.${NC}"
exit 0
