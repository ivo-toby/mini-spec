# MiniSpec Skills Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace flat slash-command files with agentskills.io SKILL.md skills for claude/cursor-agent/copilot/codex/qoder, add the pi agent, align remaining layouts with upstream spec-kit, migrate existing projects on `minispec upgrade`, and rename all invocations `/minispec.X` → `/minispec-X`.

**Architecture:** Skills are generated at zip build time by new `generate_skills` functions in the release scripts (bash + powershell), sharing one body-processing helper with the existing `generate_commands`. The CLI (`src/minispec_cli/__init__.py`) restructures `AGENT_COMMAND_CONFIG`, adds pi, and gains a post-apply migration sweep that deletes legacy dot-named command files when their same-stem replacement was just applied. Zip download/install flow is unchanged.

**Tech Stack:** Python 3.12/Typer/Rich (CLI), pytest, bash + PowerShell release scripts (`shutil.which`-style zip assembly), GitHub Releases asset pipeline.

**Spec:** `docs/superpowers/specs/2026-10-05-skills-modernization-design.md`

## Global Constraints

- Skills frontmatter = `name: minispec-<stem>`, `description:` from template, `compatibility: Requires MiniSpec project structure with .minispec/ directory`, `metadata: author: ivo-toby/minispec` / `source: templates/commands/<file>.md` (verbatim from spec).
- Skill body processing is identical to today's `generate_commands`: `{SCRIPT}` → script command, `{AGENT_SCRIPT}` → agent script command, `{ARGS}` → `$ARGUMENTS` for skills, `__AGENT__` → agent key, `rewrite_paths`, and `scripts:`/`agent_scripts:` frontmatter sections stripped.
- Generated filenames: `minispec-<stem>.md` / `minispec-<stem>.toml` (dots in filenames removed everywhere).
- Template files in `templates/commands/*.md` keep plain stems and are NOT renamed.
- Only invocations change: `/minispec-design`, `/minispec-next`, `/minispec-tasks`, `/minispec-constitution`, `/minispec-walkthrough`, `/minispec-analyze`, `/minispec-status`, `/minispec-checklist`, `/minispec-validate-docs`, `/minispec-registry`, `/minispec-import`. Hook IDs (`minispec.protect-main` etc.) and the internal legacy matcher's dot handling are identifiers — never renamed.
- Zip names stay `minispec-template-<agent>-<script>(-VERSION)?.zip`; GitHub Releases download flow unchanged.
- Project rule: touching `src/minispec_cli/__init__.py` requires a `pyproject.toml` version rev + `CHANGELOG.md` entry (done once in Task 7).
- Git: commit per task, `type(scope): description`, never push.
- `AGENT_CONFIG["folder"]` is informational; update `codex` → `.agents/`, `kilocode` → `.kilo/` for accuracy. `check()` and the readchar picker consume `AGENT_CONFIG` generically — pi needs no extra code there.
- `agent_templates/gemini/GEMINI.md` / `agent_templates/qwen/QWEN.md` conditional copies are no-ops today (dir absent) — leave untouched.

## Review Focus

1. **Legacy dirs holding non-MiniSpec files** (e.g. user's own `.claude/commands/notes.md`): migration must stay silent on them and remove a directory only when MiniSpec files were all migrated out of it. Pinned in Task 5.
2. **Legacy file with no same-stem replacement** (command deleted upstream, or user-added `minispec.foo.md`): expected — file stays, reported as "kept (no replacement)". Pinned in Task 5.
3. **Re-running migration on an already-migrated project** (second `upgrade`): expected — no legacy files found, summary has no migration rows, exit clean. Pinned in Task 5.
4. **qwen mixed dir** (`.qwen/commands` holds both old `minispec.*.toml` and new `minispec-*` after partial state): classification must treat only hyphen-named files as current (prompt tier); TOML dot files route to migration; detection on dir presence only. Pinned in Tasks 4–5.
5. **Skill name validity** — future template stem with an invalid char (a dot, e.g. future `validate.docs.md`): build must sanitize stem → `minispec-validate-docs` name/folder and fail the build if result doesn't match `^minispec-[a-z0-9-]+$`. Pinned in Task 2.

---

### Task 1: Release scripts — hyphenate generated filenames, add pi agent (bash)

**Files:**

- Modify: `.github/workflows/scripts/create-release-packages.sh` (`generate_commands` output names; `ALL_AGENTS` array; `build_variant` case statement)
- Modify: `.github/workflows/scripts/create-github-release.sh` (asset list)

**Interfaces:**

- Produces: generated files named `minispec-$name.$ext` → `minispec-$name` prefix change lands here; Tasks 2/3 build on this function. Zip asset `minispec-template-pi-{sh,ps}.zip`.

- [ ] **Step 1: Change the generated filename prefix in `generate_commands` in `create-release-packages.sh`**

The function constructs output names as `minispec.$name.$ext` (both md and toml branches). Change both to `minispec-$name.$ext`. The `"$ARGUMENTS"`-placeholder and TOML escaping logic are untouched; the `agent.md` branch is left as-is (copilot's case stops using it in Task 2).

- [ ] **Step 2: Add `pi` to `ALL_AGENTS` and a `pi` case in `build_variant`**

Array becomes: `ALL_AGENTS=(copilot claude gemini cursor-agent qwen opencode codex windsurf kilocode auggie roo codebuddy qoder q amp shai bob pi)`. Case block mirrors any markdown agent (e.g. `shai`):

```bash
pi)
  mkdir -p "$base_dir/.pi/prompts"
  generate_commands pi md "\$ARGUMENTS" "$base_dir/.pi/prompts" "$script" ;;
```

- [ ] **Step 3: Add the two pi assets to `create-github-release.sh`'s `gh release create` list**

```bash
  .genreleases/minispec-template-pi-sh.zip \
  .genreleases/minispec-template-pi-ps.zip \
```

- [ ] **Step 4: Verify hyphenated filenames and pi zip**

Run: `cd /tmp && MINISPEC_VERSION=test0 bash /home/ivo/workspace/mini-spec/.github/workflows/scripts/create-release-packages.sh sh pi claude` (build to a scratch dir; script takes agent names as args), then `unzip -l` the pi and claude zips.
Expected: `.pi/prompts/minispec-design.md` and `.claude/commands/minispec-design.md` entries; no dot-named `minispec.` files anywhere in the zips.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/scripts/create-release-packages.sh .github/workflows/scripts/create-github-release.sh
git commit -m "chore(release): hyphenate generated command files, add pi agent"
```

### Task 2: Release scripts — skills generation + layout realignment (bash)

**Files:**

- Modify: `.github/workflows/scripts/create-release-packages.sh`

**Interfaces:**

- Consumes: `generate_commands`' file-naming convention from Task 1.
- Produces: `render_command_body <file> <script> <agent_script> <args_placeholder> <agent>` (bash helper, emits processed body to stdout — the shared pipeline extracted from `generate_commands`; `generate_commands` refactored to call it), `generate_skills <agent> <output_dir> <script>` writing `<output_dir>/minispec-<stem>/SKILL.md`.

- [ ] **Step 1: Factor the body-processing pipeline out of `generate_commands` into `render_command_body`**

`generate_commands` currently: extracts frontmatter description, strips `scripts:`/`agent_scripts:` frontmatter sections, applies `{SCRIPT}`, `{AGENT_SCRIPT}`, `{ARGS}`, `__AGENT__`, `rewrite_paths`, TOML-escapes backslashes. Keep behavior identical: `render_command_body` does everything up to (not including) the TOML escaping and file write; `generate_commands` keeps writing `minispec-$name.$ext` files on top of it. TOML escaping stays in `generate_commands` (skills never emit TOML).

- [ ] **Step 2: Add `generate_skills <agent> <output_dir> <script>` using `render_command_body`**

For each `templates/commands/*.md`: `stem=$(basename file .md)`; sanitize with `tr '.' '-'`; validity guard (fails the build) if `minispec-$stem` doesn't match `^minispec-[a-z0-9-]+$`; emit:

```markdown
---
name: minispec-$stem
description: $description
compatibility: Requires MiniSpec project structure with .minispec/ directory
metadata:
  author: ivo-toby/minispec
  source: templates/commands/$(basename file)
---

<render_command_body output with args_placeholder="$ARGUMENTS">
```

Frontmatter `description` value is quoted exactly as `generate_commands` quotes descriptions for md today.

- [ ] **Step 3: Rewrite the five skills-agent cases in `build_variant`; convert qwen + kilocode to markdown; drop copilot prompt companions**

- `claude` → `mkdir -p "$base_dir/.claude/skills"; generate_skills claude "$base_dir/.claude/skills" "$script"`; keep the `hooks/adapters/claude-code.json` → `.claude/settings.json` copy.
- `cursor-agent` → `.cursor/skills`; `codex` → `.agents/skills`; `qoder` → `.qoder/skills`; same `generate_skills` call shape.
- `copilot` → `.github/skills` only; delete the `generate_copilot_prompts` function, its invocation, and the `.vscode/settings.json` copy stays if it exists today (keep, it is IDE settings, unrelated to prompts).
- `qwen` → `.qwen/commands`, `generate_commands qwen md "\$ARGUMENTS"` + keep the QWEN.md conditional copy.
- `kilocode` → `.kilo/commands`, `generate_commands kilocode md "\$ARGUMENTS"`.

- [ ] **Step 4: Add zip content assertions to the script**

After each `build_variant`, for skills agents assert zip contains `minispec-design/SKILL.md` and no `commands/` dir; for all agents assert the zip contains no path matching `minispec.*.*` (dot syntax). Print `PASS`/fail the script otherwise.

- [ ] **Step 5: Build and inspect zip contents**

Run: build claude, codex, copilot, qoder, qwen, kilocode zips to a scratch dir for `sh` and list them with `unzip -l`.
Expected: `.claude/skills/minispec-design/SKILL.md`, `.agents/skills/minispec-next/SKILL.md`, `.qwen/commands/minispec-registry.md`, `.kilo/commands/minispec-tasks.md`; no `.github/prompts/` entries; dot-named files only under `.minispec/` (none expected in zips).

- [ ] **Step 6: Spot-check SKILL.md content**

Run: extract one claude zip; `cat .claude/skills/minispec-design/SKILL.md | head -20`.
Expected: frontmatter with `name: minispec-design`, description line, `compatibility:` line, `metadata:` block with `author: ivo-toby/minispec`; body contains `$ARGUMENTS` and no `scripts:` section; `minispec.` dot references gone.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/scripts/create-release-packages.sh
git commit -m "feat(release): generate agentskills for 5 agents, align layouts"
```

### Task 3: PowerShell release script mirror of Tasks 1–2

**Files:**

- Modify: `.github/workflows/scripts/create-release-packages.ps1`

**Interfaces:**

- Consumes: the bash design from Tasks 1–2 as the behavioral spec; mirrors its own existing function names (`Generate-Commands` style — match the actual names in the file).
- Produces: function `Generate-Skills` equivalent; same output layouts as Task 2 Step 3.

- [ ] **Step 1: Apply the same four changes to the .ps1 pipeline**

Equivalent of Task 1 Steps 1–2 (hyphenated filenames, pi in `ALL_AGENTS` + case) and Task 2 Steps 2–4 (shared body processor, `Generate-Skills`, five skills cases, qwen/kilocode conversion, copilot-prompts removal, zip assertions). Match the file's existing function naming and parameter style.

- [ ] **Step 2: Diff-review against the bash script**

Run the two scripts' case blocks via `grep -A5` side by side and verify every agent dir/ext/placeholder matches the bash version.

- [ ] **Step 3: Commit**

Note in the commit body: pwsh is not installed locally, so the .ps1 build is exercised by CI (see Task 7 Step 6).

```bash
git add .github/workflows/scripts/create-release-packages.ps1
git commit -m "feat(release): mirror skills generation in PowerShell build"
```

### Task 4: CLI — config restructure, pi, hyphenated output, classification

**Files:**

- Modify: `src/minispec_cli/__init__.py` (`AGENT_CONFIG` ~line 127, `AGENT_COMMAND_CONFIG` ~line 254, `init` help/docstring ~line 1163, panels lines 1437–1452, `_read_registry_skill` ~line 2124, registry messages ~2162/2280/2348, `_classify_upgrade_file` ~line 309)
- Modify: `tests/test_upgrade.py`, `tests/test_init_registry.py` (fixtures/dirs pointing at old layouts)

**Interfaces:**

- Consumes: nothing new.
- Produces: `AGENT_COMMAND_CONFIG` entries with new per-agent layout and a new `"kind"` field per entry: `"skill"` (claude, cursor-agent, copilot, codex, qoder) or `"command"` (the rest); `"path"` pointing at the leaf dir (e.g. claude → `".claude/skills"`, codex → `".agents/skills"`, kilocode → `".kilo/commands"`, qwen → `".qwen/commands"` with `ext: "md"`, copilot → `".github/skills"`); `AgentCommandConfig` consumers unchanged otherwise. `_classify_upgrade_file(rel_path) -> str` — same signature; new hyphen-named files under a config dir classify `"prompt"`.

- [ ] **Step 1: Update the config invariants/detection/classification tests (write failing tests first)**

In `tests/test_upgrade.py`:

```python
def test_config_paths_unique():
    paths = [c["path"] for c in AGENT_COMMAND_CONFIG.values()]
    assert len(paths) == len(set(paths))

def test_skills_agents_config():
    assert AGENT_COMMAND_CONFIG["claude"]["kind"] == "skill"
    assert AGENT_COMMAND_CONFIG["claude"]["path"] == ".claude/skills"
    assert AGENT_COMMAND_CONFIG["codex"]["path"] == ".agents/skills"
    assert AGENT_COMMAND_CONFIG["qoder"]["path"] == ".qoder/skills"
    assert AGENT_COMMAND_CONFIG["cursor-agent"]["path"] == ".cursor/skills"
    assert AGENT_COMMAND_CONFIG["copilot"]["path"] == ".github/skills"

def test_qwen_is_markdown():
    assert AGENT_COMMAND_CONFIG["qwen"]["ext"] == "md"

def test_kilocode_new_dir():
    assert AGENT_COMMAND_CONFIG["kilocode"]["path"] == ".kilo/commands"

def test_detects_claude_skills_layout(tmp_path):
    (tmp_path / ".claude" / "skills").mkdir(parents=True)
    (tmp_path / ".claude" / "skills" / "minispec-design").mkdir()
    (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
    (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
    agent, script = _detect_project_config(tmp_path)
    assert agent == "claude" and script == "sh"

def test_classify_new_hyphen_command_is_prompt():
    assert _classify_upgrade_file(".roo/commands/minispec-next.md") == "prompt"

def test_classify_skill_md_is_prompt():
    assert _classify_upgrade_file(".claude/skills/minispec-design/SKILL.md") == "prompt"

def test_classify_legacy_dot_toml_not_prompt():
    assert _classify_upgrade_file(".qwen/commands/minispec.design.toml") != "prompt"
```

Also update every existing test fixture that writes old-layout files (`minispec.design.md`, `.github/agents/`, `.codex/prompts/`, `.kilocode/workflows/`) to the new layout — grep `minispec.design` in `tests/` and convert.

- [ ] **Step 2: Run new tests to verify failure**

Run: `pytest tests/test_upgrade.py -x -q`
Expected: FAIL on `test_detects_claude_skills_layout` / `test_skills_agents_config` (current config has old paths).

- [ ] **Step 3: Implement config changes in `AGENT_CONFIG` + `AGENT_COMMAND_CONFIG`**

Add `pi` to `AGENT_CONFIG` (`name: "Pi"`, `folder: ".pi/"`, `install_url: "https://pi.dev"`, `requires_cli: True`) and `AGENT_COMMAND_CONFIG` (`path: ".pi/prompts"`, `ext: "md"`, `fmt: "md"`, `kind: "command"`). Apply the new paths/kinds per the Interfaces block. Keep dict ordering stable otherwise.

- [ ] **Step 4: Implement `_classify_upgrade_file` hyphen-handling**

Current command-file branch matches `"minispec." in rel_path`. Change the positive test to: rel_path is under a config dir AND basename starts `minispec-` (new layout). Dot-named `minispec.*` files under config dirs stop classifying as `prompt` (migration owns them — spec §Migration). User-content tiers unchanged.

- [ ] **Step 5: Update user-facing strings**

`init` `--ai` help text: `... claude, gemini, copilot, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, amp, shai, q, bob, qoder, or pi`. Docstring agent examples: switch the `codex` example line's agent and keep others. Panels at lines 1437–1452: `/minispec.constitution` → `/minispec-constitution`, etc. `_read_registry_skill` filename → `f"minispec-registry.{config['ext']}"`. Messages at 2162/2280/2348 use `/minispec-registry`. `grep -n "claude, gemini, copilot"` to catch every help listing; make the lists identical everywhere.

- [ ] **Step 6: Run tests to verify pass**

Run: `pytest tests/ -q`
Expected: PASS (all modules).

- [ ] **Step 7: Commit**

```bash
git add src/minispec_cli/__init__.py tests/
git commit -m "feat(cli): skills-aware config, pi agent, hyphenated commands"
```

### Task 5: CLI — legacy migration sweep in upgrade

**Files:**

- Modify: `src/minispec_cli/__init__.py` (new `AGENT_LEGACY_COMMAND_DIRS` near `AGENT_COMMAND_CONFIG`; new `_migrate_legacy_commands()`; wiring at `upgrade` command after `_apply_upgrade` call at line 1539; detection error hint in `_detect_project_config` ~line 288)
- Modify: `tests/test_upgrade.py` (new `TestLegacyMigration` class)

**Interfaces:**

- Consumes: `_apply_upgrade(project_path, template_path, force=False) -> list[tuple[str, str]]` — existing; results' rel_paths are the applied zip paths.
- Produces: `AGENT_LEGACY_COMMAND_DIRS: dict[str, tuple[str, ...]]` — per agent, ordered old dirs, e.g. claude → `(".claude/commands",)`, copilot → `(".github/agents", ".github/prompts")`, codex → `(".codex/prompts",)`, qoder → `(".qoder/commands",)`, kilocode → `(".kilocode/workflows",)`, qwen → `(".qwen/commands",)`; command-file agents whose dir persists (gemini, opencode, windsurf, auggie, roo, codebuddy, amp, shai, q, bob, pi) map to their current dir (only dot-named files there are candidates). `_migrate_legacy_commands(project_path: Path, agent: str, applied_rel_paths: set[str]) -> list[tuple[str, str]]` — returns `(path, action)` rows: `"migrated"` (deleted, replacement existed), `"kept (no replacement)"`, `"kept (not MiniSpec)"`; removes a directory when it becomes empty after its MiniSpec files are migrated; prints nothing (the upgrade command renders the table).

- [ ] **Step 1: Write failing migration tests**

```python
class TestLegacyMigration:
    def _apply_claude_zip(self, template_dir):
        skill = template_dir / ".claude" / "skills" / "minispec-design"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")

    def test_deletes_legacy_file_with_replacement(self, tmp_path):
        self._apply_claude_zip(tmp_path)
        legacy = tmp_path / ".claude" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "minispec.design.md").write_text("old")
        _migrate_legacy_commands(tmp_path, "claude", set())
        assert not (legacy / "minispec.design.md").exists()

    def test_keeps_legacy_file_without_replacement(self, tmp_path):
        legacy = tmp_path / ".claude" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "minispec.obsolete.md").write_text("old")
        rows = _migrate_legacy_commands(tmp_path, "claude", {f".claude/skills/minispec-{stem}/SKILL.md" for stem in ["design"]})
        assert rows == [(".claude/commands/minispec.obsolete.md", "kept (no replacement)")]
        assert (legacy / "minispec.obsolete.md").exists()

    def test_replacement_detected_from_applied_paths(self, tmp_path):
        # replacement exists in applied zip paths, not yet on disk
        legacy = tmp_path / ".claude" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "minispec.design.md").write_text("old")
        rows = _migrate_legacy_commands(tmp_path, "claude", {".claude/skills/minispec-design/SKILL.md"})
        assert rows[0][1] == "migrated"

    def test_keeps_non_minispec_files_and_dir(self, tmp_path):
        legacy = tmp_path / ".claude" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "notes.md").write_text("user file")
        _migrate_legacy_commands(tmp_path, "claude", set())
        assert (legacy / "notes.md").exists()

    def test_removes_empty_legacy_dir(self, tmp_path):
        legacy = tmp_path / ".github" / "prompts"
        legacy.mkdir(parents=True)
        (legacy / "minispec.design.prompt.md").write_text("old")
        _migrate_legacy_commands(tmp_path, "copilot", {".github/skills/minispec-design/SKILL.md"})
        assert not legacy.exists()

    def test_renames_in_place_for_command_agents(self, tmp_path):
        legacy = tmp_path / ".roo" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "minispec.design.md").write_text("old")
        new = legacy / "minispec-design.md"
        new.write_text("new")
        rows = _migrate_legacy_commands(tmp_path, "roo", {".roo/commands/minispec-design.md"})
        assert not (legacy / "minispec.design.md").exists()
        assert rows[0][1] == "migrated"

    def test_idempotent_rerun(self, tmp_path):
        _migrate_legacy_commands(tmp_path, "claude", set())
        # no legacy layout at all: no rows, no exception
```

Stem-matching rule the tests pin: legacy basename `minispec.<stem>.<ext>` (also `minispec.<stem>.prompt.md`, `minispec.<stem>.agent.md`) is migrated iff any applied path (or on-disk file under a config path) contains the component `minispec-<stem>` — skill dir `minispec-<stem>/SKILL.md` qualifies.

- [ ] **Step 2: Run tests to verify failure**

Run: `pytest tests/test_upgrade.py::TestLegacyMigration -q`
Expected: FAIL with `ImportError: cannot import name '_migrate_legacy_commands'`.

- [ ] **Step 3: Implement `AGENT_LEGACY_COMMAND_DIRS` + `_migrate_legacy_commands`**

Pure-filesystem sweep per the Interfaces block; no printing, no Exit raises. Wire into `upgrade()` right after `results = _apply_upgrade(...)` (line 1539): `results += _migrate_legacy_commands(project_path, selected_ai, {rel for rel, _ in results if not rel.startswith("skipped")})` — build the applied set from `_apply_upgrade`'s returned rel_paths plus the template-extracted dirs passed in (zip extraction happens into `template_root`; pass set of applied rel_paths from results only, and let replacement detection ALSO check on-disk existence via `AGENT_COMMAND_CONFIG` dirs, which the `test_deletes_legacy_file_with_replacement` and `test_renames_in_place_for_command_agents` cases exercise).

- [ ] **Step 4: Add the migration summary + detection hint**

In `upgrade()`, render migration rows in the existing results table style. In `_detect_project_config`'s "Could not detect" exit, extend the message: list legacy layout dirs (`.claude/commands/`, `.codex/prompts/`, …) and say `minispec upgrade --ai <agent> --script <sh|ps>` migrates them.

- [ ] **Step 5: Run tests to verify pass**

Run: `pytest tests/ -q`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/minispec_cli/__init__.py tests/test_upgrade.py
git commit -m "feat(cli): migrate legacy command files to skills on upgrade"
```

### Task 6: Content sweep — templates, scripts, docs invocations

**Files:**

- Modify: `templates/commands/*.md` (cross-references, incl. `registry.md`'s `minispec.my-command` example)
- Modify: `scripts/bash/check-prerequisites.sh`, `scripts/powershell/check-prerequisites.ps1` (the three "Run /minispec.design first…" messages and their `/minispec.tasks` sibling)
- Modify: `hooks/scripts/claude-doc-update-prompt.sh` (message `/minispec.validate-docs` → `/minispec-validate-docs`; hook IDs in `hooks/hooks.yaml` untouched)
- Modify: `README.md`, `MINISPEC.md`, `WHY-MINI-SPEC.md` (every `/minispec.X`, `minispec.X.md`, and `minispec.X.toml` reference; README agent table gains pi row)

**Interfaces:** none consumed/produced.

- [ ] **Step 1: Apply the mechanical rename**

`grep -rl 'minispec\.' templates/ scripts/ hooks/ README.md MINISPEC.md WHY-MINI-SPEC.md | xargs sed -i 's|/minispec\.\([a-z-]*\)|/minispec-\1|g; s|minispec\.\([a-z-]*\)\.\(md\|toml\)|minispec-\1.\2|g; s|minispec\.my-command|minispec-my-command|g'` — then hand-review the diff: hook IDs (`minispec.protect-main`, `minispec.block-force`, `minispec.secrets-scan`, `minispec.doc-update-prompt`) and any `.minispec/` paths must be unchanged; revert any false hit.

- [ ] **Step 2: Verify zero remaining dot invocations**

Run: `grep -rn 'minispec\.[a-z]' templates/ scripts/ hooks/ README.md MINISPEC.md WHY-MINI-SPEC.md | grep -vE 'minispec\.(protect-main|block-force|secrets-scan|doc-update-prompt)|\.minispec[^-]'`
Expected: no output.

- [ ] **Step 3: README pi row + supported-agents table**

Add pi to the README agent table (CLI tool `pi`, Full support, `.pi/prompts/`), matching existing row style.

- [ ] **Step 4: Commit**

```bash
git add templates/ scripts/ hooks/ README.md MINISPEC.md WHY-MINI-SPEC.md
git commit -m "docs: rename command invocations to hyphenated form"
```

### Task 7: Version, changelog, agent guide, dogfood refresh, full verification

**Files:**

- Modify: `pyproject.toml` (version → 0.6.0)
- Modify: `CHANGELOG.md` (0.6.0 entry)
- Modify: `AGENTS.md` (Adding-New-Agent guide: skills note, pi row in the table, `AGENT_CONFIG`/`AGENT_COMMAND_CONFIG` field docs)
- Create: `.claude/skills/minispec-*/SKILL.md` (regenerated dogfood)
- Modify: `.minispec/scripts/{bash,powershell}/` (refreshed copies)

**Interfaces:** consumes release build from Task 2 for the dogfood extraction.

- [ ] **Step 1: Version + changelog**

`pyproject.toml`: `version = "0.6.0"`. `CHANGELOG.md` new `## [0.6.0]` section: **Breaking** — command invocations renamed `/minispec.X` → `/minispec-X`; command files replaced by skills for claude/cursor-agent/copilot/codex/qoder (run `minispec upgrade` to migrate); codex layout → `.agents/skills/`, kilocode → `.kilo/commands/`, qwen → markdown; copilot `.github/prompts/` companions removed. **Added** — pi agent. **Changed** — build-time skill generation.

- [ ] **Step 2: Update AGENTS.md guide**

Agent table: add pi row; update codex (`.agents/skills/`), kilocode (`.kilo/commands/`), qwen (markdown), copilot (`.github/skills/`) rows; skills agents get a "skills" note. Section "Add to AGENT_CONFIG" gains the `AGENT_COMMAND_CONFIG` second-dict step with the `kind` field and the no-dots rule.

- [ ] **Step 3: Build + extract claude zip into this repo (dogfood)**

Run: build `minispec.sh` claude zip per Task 2 Step 5; `unzip` it into the repo root; then `git rm .claude/commands/minispec.*.md` (skills layout replaces it); copy `scripts/bash/*.sh` → `.minispec/scripts/bash/` and `scripts/powershell/*.ps1` → `.minispec/scripts/powershell/`.
Expected: `.claude/skills/minispec-design/SKILL.md` present; `.claude/settings.json` hooks entry unchanged.

- [ ] **Step 4: Full verification**

Run: `pytest tests/ -q` (expect PASS); `git status` (only intended files).
Expected: everything green; old `.claude/commands/` empty or gone.

- [ ] **Step 5: Commit**

```bash
git add pyproject.toml CHANGELOG.md AGENTS.md .claude .minispec
git commit -m "chore: version 0.6.0, dogfood skills layout"
```

- [ ] **Step 6: Report unverified items**

State in the completion report: PowerShell build and end-to-end `init`/`upgrade` against a published release are CI/next-release-verified (`pip install minispec-cli==0.6.0` after tagging); everything else verified locally.
