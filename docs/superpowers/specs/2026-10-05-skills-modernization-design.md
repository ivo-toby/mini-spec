# MiniSpec Skills Modernization — Design

- **Date:** 2026-10-05
- **Status:** Approved design (option A: skills + migration; zip install retained)
- **Upstream reference:** [github/spec-kit](https://github.com/github/spec-kit/tree/main) v1.1.0
  (skills-first integrations, `SkillsIntegration` base, agentskills.io SKILL.md layout)
- **Target version:** 0.6.0 (breaking)

## Goal

Move MiniSpec from flat slash-command files (`minispec.*.md`, TOML, workflows) to
agentskills.io-style skills for the agents that natively support them, align per-agent
layouts with upstream spec-kit's current state, and migrate existing projects on
`minispec upgrade`. Installation mechanics (per-agent release zips on GitHub Releases)
stay as they are.

## Agreed scope (from discussion)

- Skills conversion for skills-capable agents; plain command files for the rest.
- Add the **pi** agent integration; align existing agents' layouts with upstream's
  current state (codex → `.agents/skills/`, kilocode → `.kilo/commands/`,
  qwen → markdown files, copilot → skills).
- Keep zip-download distribution; do not adopt upstream's bundled-wheel,
  extensions, presets, workflows, or bundles systems.

## Non-goals

- Upstream's extensions / presets / workflows / bundles platform.
- Bundling templates into the pip wheel (upstream `core_pack`).
- Python script variant (upstream sh/ps/py; MiniSpec stays sh/ps).
- Hook subsystem (`.minispec/hooks/` + `.claude/settings.json` adapter is
  layout-independent and stays unchanged).
- Registry packages (`registry.py`): targets come from each package's
  `package.yaml` `files:` mapping, so skill packages already work. No change.
- Historical docs under `docs/plans/`.

## Current state (baseline)

- `AGENT_CONFIG` + `AGENT_COMMAND_CONFIG` in `src/minispec_cli/__init__.py`
  (single 2363-line file, version 0.5.1). 17 agents, all flat command files:
  `.claude/commands/minispec.*.md`, `.gemini/commands/*.toml` (TOML prompt),
  `.github/agents/*.agent.md` + generated `.github/prompts/*.prompt.md`,
  `.cursor/commands/*.md`, `.qwen/commands/*.toml`, `.opencode/command/*.md`,
  `.windsurf/workflows/*.md`, `.codex/prompts/*.md`,
  `.kilocode/workflows/*.md`, `.augment/commands/*.md`, `.roo/commands/*.md`,
  `.codebuddy/commands/*.md`, `.qoder/commands/*.md`, `.agents/commands/*.md` (amp),
  `.shai/commands/*.md`, `.amazonq/prompts/*.md`, `.bob/commands/*.md`.
- Commands are invoked as dot-paths: `/minispec.design`, `/minispec.next`,
  `/minispec.tasks`, … (11 templates in `templates/commands/*.md`).
- Release zips: `.github/workflows/scripts/create-release-packages.sh` (and `.ps1`)
  builds `minispec-template-<agent>-<script>.zip` via `generate_commands`
  (frontmatter extraction, `{SCRIPT}`/`{AGENT_SCRIPT}`/`{ARGS}` substitution,
  scripts/agent_scripts frontmatter stripping, `rewrite_paths`).
- `minispec init` / `minispec upgrade` download the latest matching zip from
  GitHub Releases and extract. `upgrade` classifies files via
  `_classify_upgrade_file` → skip / merge / prompt / overwrite; agent command
  files currently classify as `prompt` (diff shown).

## Target state per agent

| Agent | Today | Target | Layout |
| --- | --- | --- | --- |
| claude | `.claude/commands/minispec.*.md` | `.claude/skills/minispec-<stem>/SKILL.md` | skills |
| cursor-agent | `.cursor/commands/*.md` | `.cursor/skills/minispec-<stem>/SKILL.md` | skills |
| copilot | `.github/agents/*.agent.md` + `.github/prompts/*.prompt.md` | `.github/skills/minispec-<stem>/SKILL.md` | skills |
| codex | `.codex/prompts/*.md` | `.agents/skills/minispec-<stem>/SKILL.md` | skills |
| qoder | `.qoder/commands/*.md` | `.qoder/skills/minispec-<stem>/SKILL.md` | skills |
| pi (new) | — | `.pi/prompts/minispec-<stem>.md` | commands |
| gemini | `.gemini/commands/minispec.*.toml` | same, hyphenated filenames | commands (TOML) |
| qwen | `.qwen/commands/minispec.*.toml` | `.qwen/commands/minispec-<stem>.md` | commands (markdown) |
| opencode | `.opencode/command/minispec.*.md` | same, hyphenated filenames | commands |
| windsurf | `.windsurf/workflows/minispec.*.md` | same, hyphenated filenames | commands |
| kilocode | `.kilocode/workflows/*.md` | `.kilo/commands/minispec-<stem>.md` | commands |
| auggie | `.augment/commands/minispec.*.md` | same, hyphenated filenames | commands |
| roo | `.roo/commands/minispec.*.md` | same, hyphenated filenames | commands |
| codebuddy | `.codebuddy/commands/*.md` | same, hyphenated filenames | commands |
| amp | `.agents/commands/*.md` | same, hyphenated filenames | commands |
| shai | `.shai/commands/*.md` | same, hyphenated filenames | commands |
| q | `.amazonq/prompts/*.md` | same, hyphenated filenames | commands |
| bob | `.bob/commands/*.md` | same, hyphenated filenames | commands |

Skill-file agents mirror upstream's skills-native classes (`SkillsIntegration`):
claude, cursor-agent, copilot, codex, qodercli. Amp stays markdown upstream, so
MiniSpec keeps amp on `.agents/commands/` (no collision with codex's
`.agents/skills/`) — same convention as upstream.

## Skill file format

Mirrors upstream `SkillsIntegration.setup()` (agentskills.io spec):

```markdown
---
name: minispec-design
description: Interactively establish design through guided conversation.
compatibility: Requires MiniSpec project structure with .minispec/ directory
metadata:
  author: ivo-toby/minispec
  source: templates/commands/design.md
---

<processed body — identical pipeline to generate_commands>
```

- `name` = `minispec-<stem>` (`stem` = template filename without `.md`, e.g. `design`).
- `description` comes from the template's frontmatter (same source generate_commands uses).
- Body: same processing as today — `{SCRIPT}` → script command for the variant,
  `{AGENT_SCRIPT}` → agent script command, `{ARGS}` → `$ARGUMENTS`,
  `__AGENT__` → agent key, `rewrite_paths` path substitutions, and stripping of the
  `scripts:` / `agent_scripts:` frontmatter sections.
- `$ARGUMENTS` remains in the body (agents still substitute it for skill invocations).

## Invoke rename: dots → hyphens

Skill directory names cannot contain dots and command-file agents should use the same
naming for consistency (upstream does exactly this — `/speckit-plan`).

- All invocations become `/minispec-<stem>`: `/minispec-design`, `/minispec-next`,
  `/minispec-tasks`, `/minispec-constitution`, `/minispec-walkthrough`,
  `/minispec-analyze`, `/minispec-status`, `/minispec-checklist`,
  `/minispec-validate-docs`, `/minispec-registry`, `/minispec-import`.
- Generated file names become `minispec-<stem>.md` / `.toml`
  (previously `minispec.<stem>.md` / `.toml`).
- Template files in `templates/commands/*.md` keep plain stems (`design.md`); only
  generated output and cross-references change.
- Sweep: ~100 references across `templates/commands/*.md`, CLI user-facing panels
  (init/upgrade next-steps), README.md, MINISPEC.md, WHY-MINI-SPEC.md, and any
  docs that instruct users to invoke commands. Internal hook IDs
  (`minispec.protect-main` etc.) are identifiers, not invocations — unchanged.

## Release scripts (sh + ps1)

- New `generate_skills <agent> <output_dir> <script_variant>` function in
  `create-release-packages.sh`, mirroring `generate_commands` but writing
  `minispec-<stem>/SKILL.md` files with the skills frontmatter above.
  Same template pipeline shared: factor the body-processing into one helper used by
  both generators so the two paths cannot drift.
- `generate_copilot_prompts` and the `.github/prompts` generation are dropped
  (copilot becomes skills).
- Per-agent cases: skills agents call `generate_skills` into
  `<folder>/skills`; markdown agents keep `generate_commands` with renamed
  output files (`minispec-<stem>.md` — the generator owns the prefix, so this is a
  one-line change from `minispec.$name` to `minispec-$name`); gemini keeps TOML
  (hyphenated filenames, `{{args}}`); qwen switches its case block to
  `generate_commands qwen md "\$ARGUMENTS"`.
- `pi` added to `ALL_AGENTS` in `ALL_AGENTS` arrays and case statements (both
  scripts); `.github/workflows/scripts/create-github-release.sh` lists the two
  new pi zips.
- Powershell script (`create-release-packages.ps1`) receives the same changes.

## CLI changes (`src/minispec_cli/__init__.py`)

1. **Config restructure.** `AGENT_COMMAND_CONFIG` entries gain the new paths
   per the table above (skills agents point at their `skills` subdir). Codex's
   `folder` (`.codex/` → `.agents/`) and kilocode's (`.kilocode/` → `.kilo/`)
   change in `AGENT_CONFIG`; qwen/amp/copilot tool-check metadata unchanged.
   Add `pi` to both. Help text, docstrings, and error messages updated.
2. **Detection.** `_detect_project_config` keeps working on directory presence.
   Projects on the old layout (`.codex/prompts`, `.kilocode/`, `.github/agents`)
   are no longer detected (new config points elsewhere); explicit
   `--ai <agent>` upgrade works as today and drives the migration. The
   "Could not detect AI agent" error gains a hint about old layouts and
   `--ai` usage.
3. **Migration in upgrade.** New post-apply step in `_apply_upgrade` (or right
   after it in the `upgrade` command): legacy-layout replacement.
   - Legacy paths per agent are an explicit `AGENT_LEGACY_COMMAND_DIRS` table:
     for the five skills agents, the old command dirs (`.claude/commands/`,
     `.cursor/commands/`, `.github/agents/`, `.github/prompts/`,
     `.codex/prompts/`, `.kilocode/workflows/`, `.qoder/commands/`); for qwen,
     `.qwen/commands/` (`.toml` only). Files inside an agent's *current* command
     dir that still carry dot naming (`minispec.*.md`) are also legacy
     (covers command-file agents that only renamed files).
   - Delete a legacy file only when its same-stem replacement exists after the
     upgrade was applied (stem match: `minispec.design.md` →
     `minispec-design/SKILL.md` or `minispec-design.md`/`.toml`). Report each as
     `replaced by skills layout` / `migrated` in the upgrade summary table.
   - Old dirs are removed when empty after deletion (`.github/prompts/`,
     `.codex/`, `.kilocode/`, `.github/agents/`, `.claude/commands/`, …). Dirs
     still containing non-MiniSpec files stay.
4. **User-facing text.** Init/upgrade panels and docstrings switch to hyphen
   invocations.
5. **No change** to zip download/unzip/init flow, `check` (tool checks),
   hooks merging (`merge_json_files` for `.claude/settings.json` still applies),
   or `registry.py`.

## Templates and content

- `templates/commands/*.md`: cross-references `/minispec.X` → `/minispec-X`.
  No other body changes; workflow content stays MiniSpec-specific
  (design conversation, next, walkthrough…).
- `AGENTS.md` (repo doc): "Adding New Agent Support" guide updated —
  `AGENT_CONFIG` + `AGENT_COMMAND_CONFIG` become the two tables to edit, skills
  note (SKILL.md generation, no dots in names), pi entry, updated agent table.

## Dogfood (this repository)

This repo runs its own `.claude/commands/minispec.*.md` and `.minispec/scripts/*`
copies. After the change:
- Generate the new claude skills locally (run the release build, extract the
  claude zip into the repo root), delete `.claude/commands/minispec.*.md`.
- Refresh `.minispec/scripts/{bash,powershell}` copies from `scripts/{bash,powershell}`.
- Regenerate `.claude/settings.json` hooks entry only if adapter changed (not expected).

## Versioning & release

- `pyproject.toml` → **0.6.0**.
- `CHANGELOG.md` 0.6.0 entry: BREAKING (invocation rename, command files moved to
  skills for five agents — run `minispec upgrade` to migrate), Added (pi agent),
  Changed (codex/kilocode/qwen/copilot layout alignment).
- One release cut after the change; first `minispec upgrade` against it performs
  the migration for every existing project.

## Testing

- **pytest**
  - Update `tests/test_upgrade.py` classification cases: skill files under
    new skill dirs classify as (`prompt`, same tier as command files today —
    first migration only ever sees "created (new)", later upgrades diff-prompt);
    legacy dot-named files classified as migrated-delete.
  - New tests: `_apply_upgrade` migration (legacy file deleted iff replacement
    applied; old dirs removed when empty; summary actions), agent detection on
    new layouts, config-table invariants (no two agents sharing a commands path;
    skills agents' `SKILL.md` layout; no dots in generated names).
- **Release build**
  - Run `create-release-packages.sh` locally for sample agents (claude, gemini,
    pi, codex, qwen) × sh; assert zip contents: skill dirs + SKILL.md frontmatter,
    hyphenated names, no `scripts:` frontmatter leakage, `$ARGUMENTS` preserved.
  - Same spot-check for `create-release-packages.ps1`. pwsh is not installed
    here, so CI verifies it; noted in "Not verifiable here".
- **Dogfood smoke**: extract claude zip into this repo, confirm
  `.claude/skills/minispec-design/SKILL.md` exists and old commands are gone.
- **Not verifiable here** (needs the published release, or pwsh not installed):
  end-to-end `minispec init` + `minispec upgrade` against GitHub Releases and the
  PowerShell release build. Covered after the 0.6.0 release by running the
  migration once against a scratch project; .ps1 covered by CI.

## Risks

- **Invocation breakage:** `/minispec.design` stops resolving after upgrade until
  users type `/minispec-design`. Mitigated by upgrade summary + changelog BREAKING
  note; no silent breakage possible (old files are deleted by the migration, not
  left half-installed).
- **Copilot prompts removal:** `.github/prompts/*.prompt.md` companions for older
  VS Code copilot modes are deleted on migration; users on very old copilot
  versions lose the prompts. Accepted, tracked in changelog.
- **Build-time generation in bash/ps** has no pytest coverage (same as today's
  `generate_commands`); covered by build-time assertions in the release script
  (zip content check) and CI.

## Verification evidence

- `tests/`: `pytest` green locally (existing 3 modules + new migration tests).
- Release zips built locally and inspected (file list + SKILL.md head).
- Dogfood layout in this repo switched over in the same change.