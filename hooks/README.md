# MiniSpec Hard Hooks

This directory contains **hard hooks**—non-negotiable safety guardrails that AI agents must respect. Unlike soft rules in the constitution (which guide behavior), hard hooks enforce constraints.

## Two-Tier Enforcement

| Tier | Location | Enforcement | Override |
|------|----------|-------------|----------|
| **Soft Rules** | `constitution.md` | Agent reads & follows | Can override with explanation |
| **Hard Hooks** | This directory | Scripts + agent config | Requires explicit user action |

## Directory Structure

```
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

### Blocking Hooks (must pass)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-push` | Before `git push` | Require human approval |
| `block-force` | Destructive git ops | Block `reset --hard`, `push -f`, etc. |
| `protect-main` | Commit to main/master | Prevent direct commits |
| `secrets-scan` | Before `git add` | Detect hardcoded secrets |
| `workflow-gate` | Before implementation | Verify design.md/tasks.md exist |

### Prompting Hooks (inform, don't block)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `confirm-delete` | Before file deletion | Confirm before deleting |
| `doc-staleness` | After structural changes | Check if docs need update |
| `adr-prompt` | After architectural changes | Suggest ADR creation |

## Setup by Agent

### Claude Code

Copy adapter to your project:

```bash
cp adapters/claude-code.json .claude/settings.json
```

Or merge with existing settings.

### Cursor

Add content from `adapters/cursor.md` to your `.cursorrules` file.

### Aider

Follow instructions in `adapters/aider.md`.

### Other Agents

See `adapters/generic.md` for universal setup instructions.

## Manual Usage

Scripts can be run directly:

```bash
# Check for secrets
bash scripts/secrets-scan.sh src/config.ts

# Check protected branch
bash scripts/protect-main.sh

# Simulate pre-push
bash scripts/pre-push.sh origin https://github.com/user/repo
```

## Customization

### Modifying Protected Branches

Edit `scripts/protect-main.sh`:

```bash
PROTECTED_BRANCHES=("main" "master" "develop" "production" "release/*")
```

### Modifying Secret Patterns

Edit `scripts/secrets-scan.sh` `PATTERNS` array.

### Disabling a Hook

In agent config, set `enabled: false` for the hook, or remove it from adapter files.

## Git Hooks Integration

For maximum enforcement, install as git hooks:

```bash
# Create git hooks
cp scripts/pre-push.sh .git/hooks/pre-push
cp scripts/secrets-scan.sh .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-push .git/hooks/pre-commit
```

This provides enforcement even outside AI agent sessions.

## Philosophy

> **Soft rules guide, hard hooks guard.**

- Constitution constraints are suggestions the AI follows
- Hard hooks are gates the AI cannot bypass
- Together they create defense in depth

Use hard hooks sparingly—only for truly non-negotiable safety requirements.
