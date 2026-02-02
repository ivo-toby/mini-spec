#!/usr/bin/env bash
# MiniSpec Hook: adr-prompt
# Prompts for ADR creation when touching architectural code
#
# Usage: ./adr-prompt.sh [changed-files...]
# Exit 0 always (prompting only, never blocks)

set -euo pipefail

YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get changed files from args or git
if [[ $# -gt 0 ]]; then
    CHANGED_FILES="$*"
else
    CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "")
fi

if [[ -z "$CHANGED_FILES" ]]; then
    exit 0
fi

# Patterns that indicate architectural changes
ARCH_PATTERNS=(
    "src/core/"
    "src/infrastructure/"
    "src/framework/"
    "/config/"
    "docker-compose"
    "Dockerfile"
    ".config.js"
    ".config.ts"
    "webpack.config"
    "vite.config"
    "tsconfig"
    "package.json"  # Only for major dependency changes
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
)

# Check if any changed files match architectural patterns
ARCH_CHANGES=()
for file in $CHANGED_FILES; do
    for pattern in "${ARCH_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            ARCH_CHANGES+=("$file")
            break
        fi
    done
done

if [[ ${#ARCH_CHANGES[@]} -eq 0 ]]; then
    exit 0
fi

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

DECISIONS_DIR="${MINISPEC_DIR:-$(pwd)/.minispec}/knowledge/decisions"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}MiniSpec: Consider Creating an ADR${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Architectural changes detected in:"
for file in "${ARCH_CHANGES[@]}"; do
    echo -e "  ${CYAN}$file${NC}"
done
echo ""
echo "If this change involves a significant decision, consider documenting it:"
echo ""
echo "  1. What problem does this solve?"
echo "  2. What alternatives were considered?"
echo "  3. What are the trade-offs?"
echo ""
echo "ADRs help future developers (including future you) understand WHY"
echo "decisions were made, not just what was done."
echo ""
if [[ -d "$DECISIONS_DIR" ]]; then
    ADR_COUNT=$(find "$DECISIONS_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "Current ADRs: $ADR_COUNT in $DECISIONS_DIR"
fi
echo ""

exit 0
