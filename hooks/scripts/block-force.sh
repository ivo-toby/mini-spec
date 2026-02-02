#!/usr/bin/env bash
# MiniSpec Hook: block-force
# Blocks destructive git operations unless explicitly confirmed
#
# Usage: ./block-force.sh "<command>"
# Exit 0 = allow, Exit 1 = block

set -euo pipefail

COMMAND="${1:-}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Patterns to block
DANGEROUS_PATTERNS=(
    "git reset --hard"
    "git push --force"
    "git push -f"
    "git clean -f"
    "git checkout ."
    "git restore ."
)

# Check if command matches any dangerous pattern
is_dangerous() {
    local cmd="$1"
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if [[ "$cmd" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

if is_dangerous "$COMMAND"; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}MiniSpec: Destructive Operation Blocked${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Command: $COMMAND"
    echo ""
    echo "This operation can cause irreversible data loss."
    echo ""

    # Allow override with explicit confirmation
    read -r -p "Type 'I understand the risks' to proceed: " response
    if [[ "$response" == "I understand the risks" ]]; then
        echo -e "${YELLOW}Proceeding with destructive operation...${NC}"
        exit 0
    else
        echo -e "${RED}Operation cancelled.${NC}"
        exit 1
    fi
fi

# Command is safe
exit 0
