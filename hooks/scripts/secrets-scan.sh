#!/usr/bin/env bash
# MiniSpec Hook: secrets-scan
# Scans staged files for hardcoded secrets before committing
#
# Usage: ./secrets-scan.sh [file...]
# Exit 0 = no secrets found, Exit 1 = secrets detected

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Files to scan (staged files if no args)
if [[ $# -eq 0 ]]; then
    FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")
else
    FILES="$*"
fi

if [[ -z "$FILES" ]]; then
    exit 0
fi

# Patterns that indicate secrets (regex)
PATTERNS=(
    # API Keys
    '(api[_-]?key|apikey)\s*[=:]\s*["\x27][^"\x27]{10,}["\x27]'
    '(secret[_-]?key|secretkey)\s*[=:]\s*["\x27][^"\x27]{10,}["\x27]'
    '(access[_-]?token|accesstoken)\s*[=:]\s*["\x27][^"\x27]{10,}["\x27]'
    '(auth[_-]?token|authtoken)\s*[=:]\s*["\x27][^"\x27]{10,}["\x27]'
    # Passwords
    '(password|passwd|pwd)\s*[=:]\s*["\x27][^"\x27]{4,}["\x27]'
    # AWS
    'AKIA[0-9A-Z]{16}'
    'aws[_-]?secret[_-]?access[_-]?key'
    # Private keys
    '-----BEGIN (RSA |DSA |EC |OPENSSH )?PRIVATE KEY-----'
    # Connection strings with credentials
    '(mysql|postgres|postgresql|mongodb|redis)://[^:]+:[^@]+@'
    # Generic tokens
    'bearer\s+[a-zA-Z0-9_-]{20,}'
    # GitHub tokens
    'ghp_[a-zA-Z0-9]{36}'
    'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}'
    # Slack tokens
    'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*'
)

# Files to exclude
EXCLUDE_PATTERNS=(
    '\.example$'
    '\.sample$'
    '\.template$'
    '_test\.go$'
    '_test\.py$'
    '\.test\.[jt]sx?$'
    '\.spec\.[jt]sx?$'
    'test_.*\.py$'
    '\.md$'
    'package-lock\.json$'
    'yarn\.lock$'
    'pnpm-lock\.yaml$'
)

FOUND_SECRETS=0
FINDINGS=()

should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" =~ $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Scan each file
for file in $FILES; do
    if should_exclude "$file"; then
        continue
    fi

    if [[ ! -f "$file" ]]; then
        continue
    fi

    for pattern in "${PATTERNS[@]}"; do
        matches=$(grep -nEi "$pattern" "$file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            FOUND_SECRETS=1
            while IFS= read -r match; do
                FINDINGS+=("$file: $match")
            done <<< "$matches"
        fi
    done
done

if [[ $FOUND_SECRETS -eq 1 ]]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}MiniSpec: Potential Secrets Detected${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "The following lines may contain hardcoded secrets:"
    echo ""
    for finding in "${FINDINGS[@]}"; do
        echo -e "  ${YELLOW}$finding${NC}"
    done
    echo ""
    echo "Recommendations:"
    echo "  1. Use environment variables instead of hardcoded values"
    echo "  2. Store secrets in .env files (add to .gitignore)"
    echo "  3. Use a secrets manager (Vault, AWS Secrets Manager, etc.)"
    echo ""
    echo "If these are false positives (test data, examples), you can:"
    echo "  - Rename file to *.example or *.sample"
    echo "  - Add to test files (*_test.*, *.test.*)"
    echo ""
    exit 1
fi

echo -e "${GREEN}No secrets detected in staged files.${NC}"
exit 0
