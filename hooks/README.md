# MiniSpec Hard Hooks

This directory contains **hard hooks**—safety guardrails that help prevent mistakes during development. Unlike soft rules in the constitution (which guide AI behavior), hard hooks enforce constraints through scripts and configuration.

## Two-Tier Enforcement

| Tier | Location | Enforcement | Override |
|------|----------|-------------|----------|
| **Soft Rules** | `constitution.md` | AI reads & follows | Can override with explanation |
| **Hard Hooks** | This directory | Scripts + config | Requires explicit user action |

## Directory Structure

```text
hooks/
├── hooks.yaml              # Canonical hook definitions
├── README.md               # This file
├── scripts/                # Portable shell scripts
│   ├── pre-push.sh         # Push approval
│   ├── block-force.sh      # Block destructive ops
│   ├── protect-main.sh     # Branch protection
│   ├── confirm-delete.sh   # Delete confirmation
│   ├── secrets-scan.sh     # Secrets detection
│   ├── workflow-gate.sh    # MiniSpec workflow checks
│   ├── doc-staleness.sh    # Doc freshness check
│   └── adr-prompt.sh       # ADR suggestion
└── adapters/               # Agent-specific configs
    ├── claude-code.json    # Claude Code settings
    ├── cursor.md           # Cursor rules
    ├── aider.md            # Aider configuration
    └── generic.md          # Any other agent
```

## Available Hooks

| Hook | Purpose | Best Enforcement Method |
|------|---------|------------------------|
| `pre-push` | Human approval before pushing | Git hook |
| `block-force` | Block `reset --hard`, `push -f`, etc. | Git hook + AI prompt |
| `protect-main` | Prevent commits to main/master | Git hook |
| `secrets-scan` | Detect hardcoded secrets | Git pre-commit hook |
| `workflow-gate` | Verify design.md/tasks.md exist | AI prompt |
| `confirm-delete` | Confirm before deleting files | AI prompt |
| `doc-staleness` | Check if docs need update | Manual / AI prompt |
| `adr-prompt` | Suggest ADR for architectural changes | AI prompt |

## Enforcement Methods

### 1. Git Hooks (Strongest)

Git hooks run automatically and can block operations. This is the most reliable enforcement.

```bash
# Install git hooks
cp scripts/secrets-scan.sh .git/hooks/pre-commit
cp scripts/pre-push.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

**Supported git hooks:**

- `pre-commit` → secrets-scan, protect-main
- `pre-push` → pre-push approval

### 2. AI Agent Configuration (Medium)

AI agents can be configured to run hooks or follow safety rules. However, each agent has different capabilities.

#### Claude Code

Claude Code hooks use the PreToolUse JSON protocol — each script reads the pending command from stdin and returns a `permissionDecision` via stdout.

The `adapters/claude-code.json` registers three PreToolUse hooks:

- `claude-protect-main.sh` — Denies commits on protected branches
- `claude-block-force.sh` — Denies destructive git commands
- `claude-secrets-scan.sh` — Denies staging/committing files containing secrets

For additional enforcement, combine with git hooks.

#### Cursor

Add rules from `adapters/cursor.md` to your `.cursorrules` file. Cursor respects these as behavioral guidelines.

#### Other Agents

See `adapters/generic.md` for system prompt additions that work with any AI agent.

### 3. Manual Execution (On-Demand)

Run hooks manually when needed:

```bash
# Before committing
.minispec/hooks/scripts/secrets-scan.sh

# Before pushing
.minispec/hooks/scripts/pre-push.sh

# Check protected branch
.minispec/hooks/scripts/protect-main.sh
```

## Recommended Setup

For maximum protection, use multiple layers:

```bash
# 1. Install git hooks (automatic enforcement)
cp .minispec/hooks/scripts/secrets-scan.sh .git/hooks/pre-commit
cp .minispec/hooks/scripts/pre-push.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push

# 2. Keep AI agent config (behavioral guidance)
# Claude Code: .claude/settings.json already configured
# Cursor: Add adapters/cursor.md content to .cursorrules

# 3. Manual checks available in .minispec/hooks/scripts/
```

## Customization

### Modifying Protected Branches

Edit `scripts/protect-main.sh`:

```bash
PROTECTED_BRANCHES=("main" "master" "develop" "production" "release/*")
```

### Modifying Secret Patterns

Edit `scripts/secrets-scan.sh` `PATTERNS` array to add/remove patterns.

### Disabling Hooks

**Git hooks:** Remove from `.git/hooks/`

**Claude Code:** Remove from `.claude/settings.json`

**Cursor:** Remove from `.cursorrules`

## Philosophy

> **Soft rules guide, hard hooks guard.**

- Constitution constraints are suggestions the AI follows
- Hard hooks are gates that provide additional protection
- Git hooks are the strongest enforcement mechanism
- AI agent hooks provide behavioral guidance but aren't foolproof

Use multiple layers for defense in depth. No single mechanism is perfect.

## Troubleshooting

### Hook not running?

1. Check the script is executable: `chmod +x scripts/*.sh`
2. For git hooks, ensure they're in `.git/hooks/` and executable
3. For Claude Code, check `.claude/settings.json` syntax with `claude --version`

### Hook runs but doesn't block?

1. Git hooks block by exiting non-zero. Check the script's exit code.
2. AI agent hooks are behavioral guidance, not hard blocks. Use git hooks for enforcement.

### False positives in secrets scan?

Edit `scripts/secrets-scan.sh` to:

- Add patterns to `EXCLUDE_PATTERNS`
- Rename test files to match exclusion patterns (e.g., `*.test.js`)
