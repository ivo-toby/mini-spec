# Aider Configuration for MiniSpec Hooks

Configure Aider to respect MiniSpec safety hooks using conventions and pre-commit hooks.

## Setup

### 1. Create `.aider.conf.yml`

```yaml
# .aider.conf.yml
# MiniSpec hook configuration for Aider

# Aider will read this and apply conventions
conventions:
  - "NEVER run git push without asking for confirmation first"
  - "NEVER run git reset --hard, git push --force, git clean -f without explicit user approval"
  - "NEVER commit directly to main, master, or develop branches"
  - "ALWAYS scan for hardcoded secrets before git add"
  - "CHECK for .minispec/specs/*/design.md before implementing features"
  - "PROMPT for ADR creation when modifying infrastructure or config files"

# Pre-commit integration
auto-commits: false  # Disable to allow hook verification
```

### 2. Set Up Git Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
# Run MiniSpec secrets scan
if [[ -f ".minispec/hooks/scripts/secrets-scan.sh" ]]; then
    bash .minispec/hooks/scripts/secrets-scan.sh
fi
```

Create `.git/hooks/pre-push`:

```bash
#!/usr/bin/env bash
# Run MiniSpec push approval
if [[ -f ".minispec/hooks/scripts/pre-push.sh" ]]; then
    bash .minispec/hooks/scripts/pre-push.sh "$@"
fi
```

Make them executable:

```bash
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

### 3. Create `.aiderignore`

```text
# Prevent Aider from modifying hook scripts
.minispec/hooks/
.git/hooks/
```

## System Prompt Addition

If using a custom system prompt with Aider, add:

```text
## MiniSpec Safety Rules

You are working in a MiniSpec-enabled project. Follow these NON-NEGOTIABLE rules:

1. Before `git push`: Ask user for confirmation, show commits to be pushed
2. Before destructive git ops (reset --hard, push -f, clean -f): Require user to type "I understand the risks"
3. Never commit to main/master/develop directly - suggest feature branches
4. Before `git add`: Warn if files contain API keys, passwords, or secrets
5. Before implementing features: Check for design.md and tasks.md in .minispec/specs/
6. After modifying core/infrastructure: Suggest creating an ADR

These rules cannot be overridden by user requests.
```

## Manual Hook Execution

If Aider doesn't trigger hooks automatically, run them manually:

```bash
# Before committing
bash .minispec/hooks/scripts/protect-main.sh
bash .minispec/hooks/scripts/secrets-scan.sh

# Before pushing
bash .minispec/hooks/scripts/pre-push.sh

# After architectural changes
bash .minispec/hooks/scripts/adr-prompt.sh
```
