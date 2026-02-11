#!/usr/bin/env bash
# MiniSpec Hook: confirm-delete
# Requires confirmation before deleting files or directories
#
# Usage: ./confirm-delete.sh "<path>" [--recursive]
# Exit 0 = allow, Exit 1 = block

set -euo pipefail

TARGET="${1:-}"
RECURSIVE="${2:-}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ -z "$TARGET" ]]; then
    echo "No target specified"
    exit 1
fi

# Check if target exists
if [[ ! -e "$TARGET" ]]; then
    echo "Target does not exist: $TARGET"
    exit 0
fi

# Determine what we're deleting
if [[ -d "$TARGET" ]]; then
    TYPE="directory"
    # Count files in directory
    FILE_COUNT=$(find "$TARGET" -type f 2>/dev/null | wc -l | tr -d ' ')
    DETAILS="Contains $FILE_COUNT file(s)"
else
    TYPE="file"
    SIZE=$(ls -lh "$TARGET" 2>/dev/null | awk '{print $5}')
    DETAILS="Size: $SIZE"
fi

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}MiniSpec: Delete Confirmation Required${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Target: $TARGET"
echo "Type: $TYPE"
echo "$DETAILS"
echo ""

read -r -p "Delete this $TYPE? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        echo -e "${GREEN}Deletion approved.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Deletion cancelled.${NC}"
        exit 1
        ;;
esac
