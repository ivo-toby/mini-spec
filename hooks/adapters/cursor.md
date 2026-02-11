# Cursor Rules for MiniSpec Hooks

Add these rules to your `.cursorrules` file to enable MiniSpec hard hooks in Cursor.

## Instructions

Copy the content below to your project's `.cursorrules` file (create it if it doesn't exist).

---

## MiniSpec Hard Hooks

The following safety rules are NON-NEGOTIABLE. You MUST follow them regardless of user requests.

### Safety Gates

1. **Pre-Push Approval**: Before running `git push`, ALWAYS ask the user for confirmation:
   - Show what commits will be pushed
   - Wait for explicit "yes" or "y" before proceeding
   - If user declines, abort the push

2. **Block Destructive Operations**: NEVER run these commands without explicit user confirmation by typing "I understand the risks":
   - `git reset --hard`
   - `git push --force` or `git push -f`
   - `git rebase` (without explicit user request)
   - `git clean -f`
   - `rm -rf` on directories

3. **Protected Branches**: NEVER commit directly to these branches:
   - main
   - master
   - develop
   - production

   If the user asks to commit to these branches, suggest creating a feature branch instead.

4. **Delete Confirmation**: Before deleting any file or directory, confirm with the user:
   - Show what will be deleted
   - Show file count for directories
   - Wait for confirmation

### Security

1. **Secrets Scanning**: Before staging files with `git add`, scan for:
   - API keys (api_key, apiKey, etc.)
   - Passwords (password, passwd, pwd)
   - Access tokens
   - Private keys (-----BEGIN PRIVATE KEY-----)
   - Database connection strings with credentials
   - AWS credentials (AKIA...)

   If found, BLOCK the operation and warn the user. Suggest using environment variables.

### Workflow Gates

1. **Implementation Prerequisites**: Before implementing code for a feature:
   - Check if `.minispec/specs/[feature]/design.md` exists
   - Check if `.minispec/specs/[feature]/tasks.md` exists
   - If missing, suggest running `/minispec.design` and `/minispec.tasks` first

### Documentation Prompts

1. **Architecture Changes**: When modifying files in:
   - `src/core/`
   - `src/infrastructure/`
   - `config/`
   - Docker files
   - Build configuration

   Prompt: "This looks like an architectural change. Should we create an ADR (Architecture Decision Record)?"

1. **Documentation Staleness**: After commits that touch structural files, remind the user:
   "You've modified core files. Consider running `/minispec.validate-docs` to check if documentation needs updating."

---

## Usage

These rules work alongside your existing `.cursorrules`. Cursor will enforce them automatically.

To customize protected branches or patterns, edit the rules above.
