# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to the MiniSpec CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-10-05

### Breaking

- **Command invocations renamed** — all `/minispec.X` slash commands are now `/minispec-X` (e.g. `/minispec.design` → `/minispec-design`). Update muscle memory and any docs referencing the commands.
- **Command files replaced by skills** — Claude Code, Cursor, GitHub Copilot, Codex, and Qoder now install `SKILL.md` skills (e.g. `.claude/skills/minispec-design/SKILL.md`) instead of flat command files. Run `minispec upgrade` to migrate an existing project; legacy dot-named files are removed when their replacement exists.
- Codex layout moved to `.agents/skills/` (was `.codex/prompts/`), Kilo Code to `.kilo/commands/` (was `.kilocode/workflows/`), Qwen Code installs markdown (was TOML)
- GitHub Copilot no longer ships `.github/prompts/` companions alongside `.github/skills/`

### Added

- **Pi Coding Agent** support (`.pi/prompts/`)

### Changed

- Release builds generate agent skills with `name`/`description`/`compatibility`/`metadata` frontmatter for capable agents; other agents keep markdown/TOML command files with hyphenated names (e.g. `minispec-design.md`, `minispec-design.toml`)
- `minispec upgrade` migrates legacy dot-named command files to the new layouts and removes empty legacy dirs

## [0.5.0] - 2026-03-23

### Changed

- **BREAKING: Specs directory moved** - Feature specs now live at top-level `specs/` instead of `.minispec/specs/`
- Updated all command templates, scripts (bash + powershell), and CLI to use new path
- OS-agnostic path matching in upgrade file classifier (Windows compatibility)

### Fixed

- Fixed `.minispec.minispec/` typos in `.claude/commands/` files (pre-existing)
- Enforce tasks file creation in `/minispec.tasks` command

## [0.1.0] - 2025-02-01

### Added

- **MiniSpec workflow** - Pair programming approach to AI-assisted development
- **New commands**: `/minispec.design`, `/minispec.tasks`, `/minispec.next`, `/minispec.walkthrough`, `/minispec.analyze`, `/minispec.status`, `/minispec.checklist`, `/minispec.validate-docs`
- **Interactive design conversations** - AI asks questions, presents trade-offs, engineer decides
- **Configurable chunk sizes** - Small (20-40), Medium (40-80), Large (80-150) lines
- **Living documentation** - Knowledge base with decisions, patterns, and modules
- **CLI rebranded** - `minispec` command with new banner and identity

### Changed

- **Directory structure** - `.specify/` → `.minispec/`
- **Spec files** - `spec.md` → `design.md`, `plan.md` → `tasks.md`
- **Command prefix** - `/speckit.*` → `/minispec.*`
- **Environment variable** - `SPECIFY_FEATURE` → `MINISPEC_FEATURE`

### Removed

- Old SpecKit commands: `/speckit.specify`, `/speckit.plan`, `/speckit.implement`, `/speckit.clarify`

---

## Pre-Fork History (SpecKit)

MiniSpec is forked from [SpecKit](https://github.com/github/spec-kit). For the complete SpecKit changelog, see the [original repository](https://github.com/github/spec-kit/blob/main/CHANGELOG.md).
