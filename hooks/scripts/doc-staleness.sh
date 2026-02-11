#!/usr/bin/env bash
# MiniSpec Hook: doc-staleness
# Checks if documentation might be stale after code changes
#
# Usage: ./doc-staleness.sh [changed-files...]
# Exit 0 = docs appear fresh, Exit 1 = docs may need update (prompting only)

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
    exit 0
fi

KNOWLEDGE_DIR="$MINISPEC_DIR/knowledge"

# Patterns that indicate architectural/structural changes
STRUCTURAL_PATTERNS=(
    "src/core/"
    "src/lib/"
    "src/infrastructure/"
    "/models/"
    "/schemas/"
    "/types/"
    "/interfaces/"
    "index.ts"
    "index.js"
    "index.py"
    "__init__.py"
    "config/"
    "docker-compose"
    "Dockerfile"
)

# Check if any changed files match structural patterns
STRUCTURAL_CHANGES=()
for file in $CHANGED_FILES; do
    for pattern in "${STRUCTURAL_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            STRUCTURAL_CHANGES+=("$file")
            break
        fi
    done
done

if [[ ${#STRUCTURAL_CHANGES[@]} -eq 0 ]]; then
    exit 0
fi

# Check documentation freshness
STALE_DOCS=()

# Check architecture.md
if [[ -f "$KNOWLEDGE_DIR/architecture.md" ]]; then
    ARCH_MTIME=$(stat -c %Y "$KNOWLEDGE_DIR/architecture.md" 2>/dev/null || stat -f %m "$KNOWLEDGE_DIR/architecture.md" 2>/dev/null || echo "0")
    for file in "${STRUCTURAL_CHANGES[@]}"; do
        if [[ -f "$file" ]]; then
            FILE_MTIME=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0")
            if [[ "$FILE_MTIME" -gt "$ARCH_MTIME" ]]; then
                STALE_DOCS+=("architecture.md")
                break
            fi
        fi
    done
fi

# Check conventions.md
if [[ -f "$KNOWLEDGE_DIR/conventions.md" ]]; then
    CONV_MTIME=$(stat -c %Y "$KNOWLEDGE_DIR/conventions.md" 2>/dev/null || stat -f %m "$KNOWLEDGE_DIR/conventions.md" 2>/dev/null || echo "0")
    # Conventions might be stale if core files changed
    for file in "${STRUCTURAL_CHANGES[@]}"; do
        if [[ "$file" == *"core"* ]] || [[ "$file" == *"lib"* ]]; then
            if [[ -f "$file" ]]; then
                FILE_MTIME=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0")
                if [[ "$FILE_MTIME" -gt "$CONV_MTIME" ]]; then
                    STALE_DOCS+=("conventions.md")
                    break
                fi
            fi
        fi
    done
fi

if [[ ${#STALE_DOCS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}MiniSpec: Documentation May Need Update${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Structural changes detected in:"
    for file in "${STRUCTURAL_CHANGES[@]}"; do
        echo -e "  ${CYAN}$file${NC}"
    done
    echo ""
    echo "The following docs may need updating:"
    for doc in "${STALE_DOCS[@]}"; do
        echo -e "  ${YELLOW}$KNOWLEDGE_DIR/$doc${NC}"
    done
    echo ""
    echo "Consider running: /minispec.validate-docs"
    echo ""
    # This is a prompting hook, not blocking
    exit 0
fi

exit 0
