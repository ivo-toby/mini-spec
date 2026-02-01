# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spec Kit** is a toolkit for Spec-Driven Development (SDD) - a methodology where specifications drive implementation rather than the reverse. The **Specify CLI** (`specify`) bootstraps projects with templates, scripts, and AI agent integrations for structured development.

## Commands

### Development

```bash
# Install dependencies
uv sync

# Run CLI directly (fastest feedback during development)
python -m src.specify_cli --help
python -m src.specify_cli init demo --ai claude --ignore-agent-tools

# Editable install (isolated environment)
uv venv && source .venv/bin/activate
uv pip install -e .
specify --help

# Run from anywhere using uvx
uvx --from . specify init demo --ai copilot --script sh
```

### Testing Template Changes

```bash
# Generate release packages locally
./.github/workflows/scripts/create-release-packages.sh v1.0.0

# Copy package to test project
cp -r .genreleases/sdd-copilot-package-sh/. <path-to-test-project>/
```

### Build

```bash
uv build
```

## Architecture

### Source Structure

- `src/specify_cli/__init__.py` - Single-file CLI implementation using Typer
- `templates/` - Markdown templates for specs, plans, tasks, checklists
- `templates/commands/` - Slash command definitions (specify.md, plan.md, tasks.md, etc.)
- `scripts/bash/` and `scripts/powershell/` - Shell scripts for feature creation, agent context updates
- `memory/constitution.md` - Template for project governance principles

### Agent Configuration

All supported AI agents are defined in `AGENT_CONFIG` dict in `__init__.py`:
- Key: actual CLI tool name (e.g., `"cursor-agent"`, not `"cursor"`)
- Fields: `name`, `folder`, `install_url`, `requires_cli`

When adding new agents, use the exact executable name as the key to avoid special-case mappings throughout the codebase.

### CLI Commands

- `specify init <project>` - Initialize new project from GitHub release template
- `specify check` - Verify installed tools (git, AI agents, VS Code)
- `specify version` - Display CLI and template version info

### Slash Commands (Generated)

After `specify init`, projects get these AI agent commands:
- `/speckit.constitution` - Establish project principles
- `/speckit.specify` - Create feature specification
- `/speckit.plan` - Generate implementation plan
- `/speckit.tasks` - Break plan into tasks
- `/speckit.implement` - Execute implementation
- `/speckit.clarify`, `/speckit.analyze`, `/speckit.checklist` - Optional quality commands

## Key Conventions

### Version Management

Changes to `__init__.py` require:
1. Version bump in `pyproject.toml`
2. Entry in `CHANGELOG.md`

### Template Placeholders

- `$ARGUMENTS` - User input for Markdown-based agents
- `{{args}}` - User input for TOML-based agents (Gemini, Qwen)
- `{SCRIPT}` - Replaced with script path during generation
- `__AGENT__` - Replaced with agent name

### Agent Directory Patterns

- CLI agents: `.<agent-name>/commands/`
- IDE agents follow IDE-specific patterns (`.github/agents/`, `.windsurf/workflows/`, etc.)
