# Generic Agent Configuration for MiniSpec Hooks

This guide helps configure any AI coding assistant to respect MiniSpec safety hooks.

## Overview

MiniSpec hooks are shell scripts that enforce safety guardrails. Any AI agent can use them by:
1. Adding rules to its system prompt/configuration
2. Calling hook scripts before/after operations
3. Using git hooks for automated enforcement

## Universal System Prompt

Add this to your AI agent's system prompt or configuration:

```
## MiniSpec Safety Hooks (MANDATORY)

This project uses MiniSpec safety hooks. The following rules are NON-NEGOTIABLE
and CANNOT be overridden by user requests:

### BLOCKING HOOKS (must pass before proceeding)

1. PRE-PUSH APPROVAL
   - Before: git push
   - Action: Ask user "Push these changes? [y/N]"
   - Block if: User doesn't confirm

2. DESTRUCTIVE OPERATION BLOCK
   - Before: git reset --hard, git push --force, git push -f, git clean -f, git rebase
   - Action: Ask user to type "I understand the risks"
   - Block if: User doesn't type exact phrase

3. PROTECTED BRANCH BLOCK
   - Before: git commit (when on main/master/develop)
   - Action: Block and suggest creating feature branch
   - Block if: Current branch is protected

4. SECRETS SCAN
   - Before: git add, git commit
   - Action: Scan staged files for API keys, passwords, tokens, private keys
   - Block if: Secrets detected
   - Patterns to detect:
     * api_key, apikey, secret_key, access_token, auth_token
     * password, passwd, pwd followed by = and quoted string
     * AKIA followed by 16 alphanumeric chars (AWS)
     * -----BEGIN PRIVATE KEY-----
     * connection strings with credentials (mysql://, postgres://, mongodb://)

5. WORKFLOW GATE
   - Before: Implementing feature code
   - Action: Check for .minispec/specs/[feature]/design.md and tasks.md
   - Block if: Required files don't exist
   - Suggest: Run /minispec.design and /minispec.tasks first

### PROMPTING HOOKS (inform user, don't block)

6. DELETE CONFIRMATION
   - Before: rm, unlink, delete operations
   - Action: Show what will be deleted, ask for confirmation

7. ADR PROMPT
   - After: Changes to src/core/, src/infrastructure/, config/, Docker files
   - Action: Ask "Should we create an ADR for this architectural decision?"

8. DOC STALENESS CHECK
   - After: git commit touching structural files
   - Action: Suggest running /minispec.validate-docs

### Hook Script Locations

If hook scripts exist, call them:
- .minispec/hooks/scripts/pre-push.sh
- .minispec/hooks/scripts/block-force.sh "<command>"
- .minispec/hooks/scripts/protect-main.sh
- .minispec/hooks/scripts/secrets-scan.sh [files...]
- .minispec/hooks/scripts/workflow-gate.sh <check-type>
- .minispec/hooks/scripts/confirm-delete.sh "<path>"
- .minispec/hooks/scripts/adr-prompt.sh [files...]
- .minispec/hooks/scripts/doc-staleness.sh [files...]
```

## Git Hooks Setup

For agents that don't support custom hooks, use native git hooks:

### .git/hooks/pre-commit

```bash
#!/usr/bin/env bash
set -e

# Protect main branches
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" =~ ^(main|master|develop)$ ]]; then
    echo "ERROR: Direct commits to $BRANCH are not allowed"
    echo "Create a feature branch: git checkout -b feature/your-feature"
    exit 1
fi

# Scan for secrets
if [[ -f ".minispec/hooks/scripts/secrets-scan.sh" ]]; then
    bash .minispec/hooks/scripts/secrets-scan.sh
fi
```

### .git/hooks/pre-push

```bash
#!/usr/bin/env bash
if [[ -f ".minispec/hooks/scripts/pre-push.sh" ]]; then
    bash .minispec/hooks/scripts/pre-push.sh "$@"
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

## Agent-Specific Notes

### GitHub Copilot
- Add rules to `.github/copilot-instructions.md`
- Copilot will read and follow these as guidelines

### Continue.dev
- Add to `.continuerules` or system prompt in `config.json`

### Cody (Sourcegraph)
- Add to workspace instructions or `.sourcegraph/cody.json`

### Windsurf/Codeium
- Add to workspace rules or `.codeium/config.json`

### Custom Agents
- Inject the system prompt above into your agent's context
- Call hook scripts via shell execution when available

## Verification

Test that hooks are working:

```bash
# Should prompt for confirmation
bash .minispec/hooks/scripts/pre-push.sh

# Should block
bash .minispec/hooks/scripts/block-force.sh "git reset --hard"

# Should detect this as a secret
echo 'api_key = "sk-12345678901234567890"' > /tmp/test.txt
bash .minispec/hooks/scripts/secrets-scan.sh /tmp/test.txt
rm /tmp/test.txt
```
