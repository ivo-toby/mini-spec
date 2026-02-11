#!/usr/bin/env bash
# test-local.sh - Create a clean test environment for MiniSpec
#
# Usage:
#   ./scripts/test-local.sh              # Default: Claude + sh
#   ./scripts/test-local.sh copilot      # Specific agent
#   ./scripts/test-local.sh cursor ps    # Agent + script type
#   ./scripts/test-local.sh --open       # Open Claude Code after setup
#
# Options:
#   --open    Open Claude Code in the test directory after setup
#   --help    Show this help message

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Defaults
TEST_DIR="/tmp/minispec-test"
OPEN_CLAUDE=false

# Parse arguments: separate flags from positional args
POSITIONAL=()
for arg in "$@"; do
    case $arg in
        --open)
            OPEN_CLAUDE=true
            ;;
        --help|-h)
            echo "Usage: $0 [agent] [script-type] [--open]"
            echo ""
            echo "Arguments:"
            echo "  agent        AI agent: claude, copilot, cursor-agent, gemini, etc. (default: claude)"
            echo "  script-type  Script type: sh or ps (default: sh)"
            echo ""
            echo "Options:"
            echo "  --open       Open Claude Code in test directory after setup"
            echo "  --help       Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Claude + sh"
            echo "  $0 copilot            # Copilot + sh"
            echo "  $0 cursor-agent ps    # Cursor + PowerShell"
            echo "  $0 --open             # Claude + sh, then open Claude Code"
            exit 0
            ;;
        *)
            POSITIONAL+=("$arg")
            ;;
    esac
done

AGENT="${POSITIONAL[0]:-claude}"
SCRIPT_TYPE="${POSITIONAL[1]:-sh}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}MiniSpec Local Test Environment${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Agent:       ${GREEN}$AGENT${NC}"
echo -e "Script type: ${GREEN}$SCRIPT_TYPE${NC}"
echo -e "Test dir:    ${GREEN}$TEST_DIR${NC}"
echo ""

# Step 1: Clean up existing test directory
if [[ -d "$TEST_DIR" ]]; then
    echo -e "${YELLOW}Removing existing test directory...${NC}"
    rm -rf "$TEST_DIR"
fi

# Step 2: Clean up old build artifacts
echo -e "${CYAN}Cleaning build artifacts...${NC}"
rm -rf "$PROJECT_ROOT/.genreleases"

# Step 3: Build template locally
echo -e "${CYAN}Building template package...${NC}"
pushd "$PROJECT_ROOT" > /dev/null

# Suppress warnings, capture errors
BUILD_OUTPUT=$(AGENTS="$AGENT" SCRIPTS="$SCRIPT_TYPE" \
    "$PROJECT_ROOT/.github/workflows/scripts/create-release-packages.sh" v0.0.1 2>&1) || {
    # Check if it's just the zip command missing (which is OK)
    if [[ "$BUILD_OUTPUT" == *"zip: command not found"* ]]; then
        echo -e "${YELLOW}Note: zip not installed, using uncompressed build${NC}"
    else
        echo -e "${RED}Build failed:${NC}"
        echo "$BUILD_OUTPUT"
        exit 1
    fi
}

popd > /dev/null

# Step 4: Find and copy the built package
PACKAGE_DIR="$PROJECT_ROOT/.genreleases/minispec-${AGENT}-package-${SCRIPT_TYPE}"

if [[ ! -d "$PACKAGE_DIR" ]]; then
    echo -e "${RED}Error: Package not found at $PACKAGE_DIR${NC}"
    echo "Available packages:"
    ls -la "$PROJECT_ROOT/.genreleases/" 2>/dev/null || echo "  (none)"
    exit 1
fi

echo -e "${CYAN}Copying to test directory...${NC}"
mkdir -p "$TEST_DIR"
cp -r "$PACKAGE_DIR/." "$TEST_DIR/"

# Step 5: Initialize git
echo -e "${CYAN}Initializing git repository...${NC}"
git -C "$TEST_DIR" init --quiet

# Step 6: Make scripts executable
echo -e "${CYAN}Setting script permissions...${NC}"
find "$TEST_DIR" -name "*.sh" -type f -exec chmod +x {} \;

# Step 7: Create a simple test file
cat > "$TEST_DIR/README.md" << 'EOF'
# MiniSpec Test Project

This is a test project for MiniSpec local development.

## Quick Hook Tests

```bash
# Test secrets scan (should BLOCK)
echo 'api_key = "sk-secret123"' > secret.txt
.minispec/hooks/scripts/secrets-scan.sh secret.txt

# Test protected branch (should BLOCK on main)
.minispec/hooks/scripts/protect-main.sh

# Test pre-push (interactive)
.minispec/hooks/scripts/pre-push.sh origin https://github.com/test/repo

# Test destructive op block (interactive)
.minispec/hooks/scripts/block-force.sh "git reset --hard"

# Test workflow gate (should fail - no design.md)
.minispec/hooks/scripts/workflow-gate.sh design
```

## MiniSpec Commands

Run `/minispec.constitution` to set up project principles.
EOF

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Test environment ready!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Location: ${CYAN}$TEST_DIR${NC}"
echo ""
echo "Contents:"
echo "  .claude/commands/     - MiniSpec slash commands"
echo "  .claude/settings.json - Claude Code hooks config"
echo "  .minispec/hooks/      - Safety hook scripts"
echo "  .minispec/memory/     - Constitution template"
echo ""
echo "To test:"
echo -e "  ${CYAN}cd $TEST_DIR${NC}"
echo ""
echo "Quick hook tests:"
echo -e "  ${CYAN}.minispec/hooks/scripts/secrets-scan.sh${NC}     # Run on staged files"
echo -e "  ${CYAN}.minispec/hooks/scripts/protect-main.sh${NC}     # Check branch protection"
echo -e "  ${CYAN}.minispec/hooks/scripts/pre-push.sh${NC}         # Test push approval"
echo ""

# Optionally open Claude Code
if [[ "$OPEN_CLAUDE" == true ]]; then
    echo -e "${CYAN}Opening Claude Code...${NC}"
    if command -v claude &> /dev/null; then
        (cd "$TEST_DIR" && claude)
    else
        echo -e "${YELLOW}Claude Code not found in PATH${NC}"
        echo "Run manually: cd $TEST_DIR && claude"
    fi
fi
