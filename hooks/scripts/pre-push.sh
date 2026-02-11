#!/usr/bin/env bash
# MiniSpec Hook: pre-push
# Requires human approval before pushing to remote
#
# Usage: ./pre-push.sh [remote] [url]
# Exit 0 = allow push, Exit 1 = block push

set -euo pipefail

REMOTE="${1:-origin}"
URL="${2:-}"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}MiniSpec: Push Approval Required${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Remote: $REMOTE"
[ -n "$URL" ] && echo "URL: $URL"
echo ""

# Show what will be pushed
echo "Commits to push:"
git log --oneline @{u}..HEAD 2>/dev/null || echo "  (new branch or no upstream)"
echo ""

# Interactive confirmation
read -r -p "Push these changes? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        echo -e "${GREEN}Push approved.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Push cancelled.${NC}"
        exit 1
        ;;
esac
