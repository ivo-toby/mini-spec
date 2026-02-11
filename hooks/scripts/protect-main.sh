#!/usr/bin/env bash
# MiniSpec Hook: protect-main
# Prevents direct commits to protected branches
#
# Usage: ./protect-main.sh
# Exit 0 = allow, Exit 1 = block

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Protected branches (customize as needed)
PROTECTED_BRANCHES=("main" "master" "develop" "production")

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "Not in a git repository"
    exit 0
fi

# Check if current branch is protected
for branch in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$CURRENT_BRANCH" == "$branch" ]]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}MiniSpec: Direct Commit to Protected Branch Blocked${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Branch '$CURRENT_BRANCH' is protected."
        echo ""
        echo "Please:"
        echo "  1. Create a feature branch: git checkout -b feature/your-feature"
        echo "  2. Make your changes"
        echo "  3. Create a pull request"
        echo ""
        exit 1
    fi
done

exit 0
