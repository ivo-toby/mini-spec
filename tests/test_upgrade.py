"""Tests for minispec upgrade command."""

import json
from pathlib import Path

import pytest
import typer
from typer.testing import CliRunner

from minispec_cli import (
    _apply_upgrade,
    _classify_upgrade_file,
    _detect_project_agent,
    _detect_project_config,
    _detect_project_script,
    _diff_files,
    _migrate_legacy_commands,
    app,
)


class TestDetectProjectConfig:
    def test_detects_claude_sh(self, tmp_path):
        (tmp_path / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        agent, script = _detect_project_config(tmp_path)
        assert agent == "claude"
        assert script == "sh"

    def test_detects_copilot_ps(self, tmp_path):
        (tmp_path / ".github" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".github" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        (tmp_path / ".minispec" / "scripts" / "powershell").mkdir(parents=True)
        agent, script = _detect_project_config(tmp_path)
        assert agent == "copilot"
        assert script == "ps"

    def test_detects_cursor(self, tmp_path):
        (tmp_path / ".cursor" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".cursor" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        agent, script = _detect_project_config(tmp_path)
        assert agent == "cursor-agent"
        assert script == "sh"

    def test_no_agent_found(self, tmp_path):
        (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        with pytest.raises(typer.Exit):
            _detect_project_config(tmp_path)

    def test_no_script_found(self, tmp_path):
        (tmp_path / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        (tmp_path / ".minispec").mkdir(parents=True)
        with pytest.raises(typer.Exit):
            _detect_project_config(tmp_path)

    def test_no_minispec_dir(self, tmp_path):
        with pytest.raises(typer.Exit):
            _detect_project_config(tmp_path)


class TestClassifyUpgradeFile:
    def test_scripts_are_overwrite(self):
        assert _classify_upgrade_file(".minispec/scripts/bash/common.sh") == "overwrite"
        assert _classify_upgrade_file(".minispec/scripts/powershell/setup-plan.ps1") == "overwrite"

    def test_templates_are_prompt(self):
        # Templates may be customised by users, so they get interactive review
        assert _classify_upgrade_file(".minispec/templates/design-template.md") == "prompt"
        assert _classify_upgrade_file(".minispec/templates/knowledge/module-template.md") == "prompt"

    def test_hooks_are_overwrite(self):
        assert _classify_upgrade_file(".minispec/hooks/scripts/claude-protect-main.sh") == "overwrite"
        assert _classify_upgrade_file(".minispec/hooks/hooks.yaml") == "overwrite"
        assert _classify_upgrade_file(".minispec/hooks/adapters/claude-code.json") == "overwrite"

    def test_settings_json_are_merge(self):
        assert _classify_upgrade_file(".claude/settings.json") == "merge"
        assert _classify_upgrade_file(".vscode/settings.json") == "merge"

    def test_agent_commands_are_prompt(self):
        assert _classify_upgrade_file(".qwen/commands/minispec-next.md") == "prompt"
        assert _classify_upgrade_file(".claude/skills/minispec-design/SKILL.md") == "prompt"

    def test_legacy_dot_named_commands_not_prompt(self):
        # Old layout commands are migration-owned, not user prompts
        assert _classify_upgrade_file(".qwen/commands/minispec.design.toml") != "prompt"
        assert _classify_upgrade_file(".codex/prompts/minispec-import.md") != "prompt"

    def test_constitution_is_skip(self):
        assert _classify_upgrade_file(".minispec/memory/constitution.md") == "skip"

    def test_unknown_files_are_overwrite(self):
        assert _classify_upgrade_file("GEMINI.md") == "overwrite"


class TestAgentCommandConfig:
    def test_config_paths_unique(self):
        from minispec_cli import AGENT_COMMAND_CONFIG
        paths = [c["path"] for c in AGENT_COMMAND_CONFIG.values()]
        assert len(paths) == len(set(paths))

    def test_skills_agents_config(self):
        from minispec_cli import AGENT_COMMAND_CONFIG
        assert AGENT_COMMAND_CONFIG["claude"]["kind"] == "skill"
        assert AGENT_COMMAND_CONFIG["claude"]["path"] == ".claude/skills"
        assert AGENT_COMMAND_CONFIG["codex"]["path"] == ".agents/skills"
        assert AGENT_COMMAND_CONFIG["qoder"]["path"] == ".qoder/skills"
        assert AGENT_COMMAND_CONFIG["cursor-agent"]["path"] == ".cursor/skills"
        assert AGENT_COMMAND_CONFIG["copilot"]["path"] == ".github/skills"

    def test_qwen_is_markdown(self):
        from minispec_cli import AGENT_COMMAND_CONFIG
        assert AGENT_COMMAND_CONFIG["qwen"]["ext"] == "md"

    def test_kilocode_new_dir(self):
        from minispec_cli import AGENT_COMMAND_CONFIG
        assert AGENT_COMMAND_CONFIG["kilocode"]["path"] == ".kilo/commands"

    def test_pi_agent_config(self):
        from minispec_cli import AGENT_COMMAND_CONFIG, AGENT_CONFIG
        assert AGENT_COMMAND_CONFIG["pi"]["path"] == ".pi/prompts"
        assert AGENT_COMMAND_CONFIG["pi"]["kind"] == "command"
        assert AGENT_CONFIG["pi"]["folder"] == ".pi/"


class TestDiffFiles:
    def test_identical_files_returns_none(self, tmp_path):
        a = tmp_path / "a.md"
        b = tmp_path / "b.md"
        a.write_text("hello\nworld\n")
        b.write_text("hello\nworld\n")
        assert _diff_files(a, b) is None

    def test_different_files_returns_diff(self, tmp_path):
        a = tmp_path / "a.md"
        b = tmp_path / "b.md"
        a.write_text("line1\nline2\n")
        b.write_text("line1\nchanged\n")
        result = _diff_files(a, b)
        assert result is not None
        assert "-line2" in result
        assert "+changed" in result

    def test_new_file_returns_diff(self, tmp_path):
        a = tmp_path / "a.md"  # doesn't exist
        b = tmp_path / "b.md"
        b.write_text("new content\n")
        result = _diff_files(a, b)
        assert result is not None
        assert "+new content" in result


class TestApplyUpgrade:
    def _setup_project(self, tmp_path):
        """Create a minimal existing MiniSpec project."""
        project = tmp_path / "project"
        project.mkdir()
        (project / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        (project / ".minispec" / "templates").mkdir(parents=True)
        (project / ".minispec" / "memory").mkdir(parents=True)
        (project / ".minispec" / "memory" / "constitution.md").write_text("my principles")
        (project / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (project / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("old design prompt")
        (project / ".claude" / "settings.json").write_text(json.dumps({"user_key": True}))
        return project

    def _setup_template(self, tmp_path):
        """Create a minimal extracted template."""
        template = tmp_path / "template"
        template.mkdir()
        (template / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        (template / ".minispec" / "scripts" / "bash" / "common.sh").write_text("#!/bin/bash\n# new")
        (template / ".minispec" / "templates").mkdir(parents=True)
        (template / ".minispec" / "templates" / "design-template.md").write_text("# new template")
        (template / ".minispec" / "memory").mkdir(parents=True)
        (template / ".minispec" / "memory" / "constitution.md").write_text("new constitution")
        (template / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (template / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("new design prompt")
        (template / ".claude" / "settings.json").write_text(json.dumps({"hooks": {"new": True}}))
        return template

    def test_overwrites_scripts(self, tmp_path):
        project = self._setup_project(tmp_path)
        template = self._setup_template(tmp_path)
        results = _apply_upgrade(project, template, force=True)
        assert (project / ".minispec" / "scripts" / "bash" / "common.sh").read_text() == "#!/bin/bash\n# new"
        assert any(r[1] == "created" for r in results if "common.sh" in r[0])

    def test_preserves_constitution(self, tmp_path):
        project = self._setup_project(tmp_path)
        template = self._setup_template(tmp_path)
        _apply_upgrade(project, template, force=True)
        assert (project / ".minispec" / "memory" / "constitution.md").read_text() == "my principles"

    def test_merges_settings_json(self, tmp_path):
        project = self._setup_project(tmp_path)
        template = self._setup_template(tmp_path)
        _apply_upgrade(project, template, force=True)
        with open(project / ".claude" / "settings.json") as f:
            data = json.load(f)
        assert data["user_key"] is True
        assert data["hooks"]["new"] is True

    def test_force_overwrites_commands(self, tmp_path):
        project = self._setup_project(tmp_path)
        template = self._setup_template(tmp_path)
        results = _apply_upgrade(project, template, force=True)
        assert (project / ".claude" / "skills" / "minispec-design" / "SKILL.md").read_text() == "new design prompt"
        assert any(r[1] == "overwritten (auto)" for r in results if "minispec-design" in r[0])


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
        assert [r for r in rows if r[1] == "migrated"] == [(".roo/commands/minispec.design.md", "migrated")]

    def test_idempotent_rerun(self, tmp_path):
        _migrate_legacy_commands(tmp_path, "claude", set())
        # no legacy layout at all: no rows, no exception

    def test_no_rows_for_non_minispec_files(self, tmp_path):
        legacy = tmp_path / ".claude" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "notes.md").write_text("user file")
        rows = _migrate_legacy_commands(tmp_path, "claude", set())
        assert rows == []
        assert (legacy / "notes.md").exists()

    def test_new_layout_files_in_persisting_dir_gain_no_rows(self, tmp_path):
        # gemini keeps .gemini/commands: new-layout files must not be reported
        legacy = tmp_path / ".gemini" / "commands"
        legacy.mkdir(parents=True)
        (legacy / "minispec-design.toml").write_text("new file")
        (legacy / "minispec.design.toml").write_text("old file")
        rows = _migrate_legacy_commands(tmp_path, "gemini", {".gemini/commands/minispec-design.toml"})
        assert rows == [(".gemini/commands/minispec.design.toml", "migrated")]

    def test_removes_stale_agent_root(self, tmp_path):
        # codex: legacy .codex/prompts emptied -> .codex removed even though
        # the new install lands in .agents/skills
        (tmp_path / ".codex" / "prompts").mkdir(parents=True)
        (tmp_path / ".codex" / "prompts" / "minispec.design.md").write_text("old")
        rows = _migrate_legacy_commands(tmp_path, "codex", {".agents/skills/minispec-design/SKILL.md"})
        assert rows == [(".codex/prompts/minispec.design.md", "migrated")]
        assert not (tmp_path / ".codex").exists()

    def test_removes_stale_agent_root_kilocode(self, tmp_path):
        (tmp_path / ".kilocode" / "workflows").mkdir(parents=True)
        (tmp_path / ".kilocode" / "workflows" / "minispec.design.md").write_text("old")
        kilo = tmp_path / ".kilo" / "commands"
        kilo.mkdir(parents=True)
        (kilo / "minispec-design.md").write_text("new (installed this run)")
        _migrate_legacy_commands(tmp_path, "kilocode", {".kilo/commands/minispec-design.md"})
        assert not (tmp_path / ".kilocode").exists()
        assert (kilo / "minispec-design.md").exists()

    def test_keeps_nonempty_dot_parent(self, tmp_path):
        # copilot: .github survives while other content lives in it
        (tmp_path / ".github" / "prompts").mkdir(parents=True)
        (tmp_path / ".github" / "prompts" / "minispec.design.prompt.md").write_text("old")
        (tmp_path / ".github" / "workflows").mkdir(parents=True)
        (tmp_path / ".github" / "workflows" / "ci.yml").write_text("jobs: []")
        _migrate_legacy_commands(tmp_path, "copilot", {".github/skills/minispec-design/SKILL.md"})
        assert not (tmp_path / ".github" / "prompts").exists()
        assert (tmp_path / ".github" / "workflows" / "ci.yml").exists()

    def test_removes_empty_dot_parent(self, tmp_path):
        # .github becomes fully empty -> removed too
        (tmp_path / ".github" / "prompts").mkdir(parents=True)
        (tmp_path / ".github" / "prompts" / "minispec.design.prompt.md").write_text("old")
        _migrate_legacy_commands(tmp_path, "copilot", {".github/skills/minispec-design/SKILL.md"})
        assert not (tmp_path / ".github").exists()


class TestDetectHelpers:
    def test_agent_from_new_layout(self, tmp_path):
        (tmp_path / ".minispec").mkdir()
        (tmp_path / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        assert _detect_project_agent(tmp_path) == "claude"

    def test_agent_old_layout_hint_exits(self, tmp_path):
        (tmp_path / ".minispec").mkdir()
        (tmp_path / ".claude" / "commands").mkdir(parents=True)
        (tmp_path / ".claude" / "commands" / "minispec.design.md").write_text("old")
        with pytest.raises(typer.Exit):
            _detect_project_agent(tmp_path)

    def test_script_from_bash_dir(self, tmp_path):
        (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        assert _detect_project_script(tmp_path) == "sh"

    def test_script_missing_exits(self, tmp_path):
        (tmp_path / ".minispec").mkdir()
        with pytest.raises(typer.Exit):
            _detect_project_script(tmp_path)


class TestUpgradeCommandExplicitAgent:
    # upgrade --ai/--script must drive the run on old-layout projects
    # without hitting the could-not-detect exit (spec: explicit flags win).

    def _make_template_zip(self, tmp_path):
        import zipfile
        root = tmp_path / "tplroot"
        root.mkdir()
        skill = root / ".claude" / "skills" / "minispec-design"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("---\nname: minispec-design\ndescription: d\n---\nnew body")
        bash = root / ".minispec" / "scripts" / "bash"
        bash.mkdir(parents=True)
        (bash / "common.sh").write_text("#!/usr/bin/env bash\n")
        zip_path = tmp_path / "release.zip"
        with zipfile.ZipFile(zip_path, "w") as zf:
            for f in root.rglob("*"):
                if f.is_file():
                    zf.write(f, f.relative_to(root))
        return zip_path

    def _fake_download(self, monkeypatch, zip_path):
        monkeypatch.setattr(
            "minispec_cli.download_template_from_github",
            lambda *a, **k: (zip_path, {"release": "v0.0.0-test"}),
        )

    def test_old_layout_project_upgrades_with_explicit_flags(self, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        (tmp_path / ".claude" / "commands").mkdir(parents=True)
        (tmp_path / ".claude" / "commands" / "minispec.design.md").write_text("old")
        (tmp_path / ".minispec" / "memory").mkdir(parents=True)
        (tmp_path / ".minispec" / "memory" / "constitution.md").write_text("constitution")
        zip_path = self._make_template_zip(tmp_path)
        self._fake_download(monkeypatch, zip_path)
        runner = CliRunner()
        result = runner.invoke(app, ["upgrade", "--ai", "claude", "--script", "sh", "--force"])
        assert result.exit_code == 0, result.output
        assert (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").exists()
        assert not (tmp_path / ".claude" / "commands" / "minispec.design.md").exists()
        assert (tmp_path / ".minispec" / "memory" / "constitution.md").read_text() == "constitution"

    def test_explicit_ai_with_detected_script(self, tmp_path, monkeypatch):
        # --ai alone: script must be detected, agent detection skipped
        monkeypatch.chdir(tmp_path)
        (tmp_path / ".claude" / "commands").mkdir(parents=True)
        (tmp_path / ".claude" / "commands" / "minispec.design.md").write_text("old")
        (tmp_path / ".minispec" / "scripts" / "bash").mkdir(parents=True)
        zip_path = self._make_template_zip(tmp_path)
        self._fake_download(monkeypatch, zip_path)
        runner = CliRunner()
        result = runner.invoke(app, ["upgrade", "--ai", "claude", "--force"])
        assert result.exit_code == 0, result.output
        assert (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").exists()
