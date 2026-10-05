"""Tests for minispec upgrade command."""

import json
from pathlib import Path

import pytest
from click.exceptions import Exit

from minispec_cli import (
    _apply_upgrade,
    _classify_upgrade_file,
    _detect_project_config,
    _diff_files,
    _migrate_legacy_commands,
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
        with pytest.raises(Exit):
            _detect_project_config(tmp_path)

    def test_no_script_found(self, tmp_path):
        (tmp_path / ".claude" / "skills" / "minispec-design").mkdir(parents=True)
        (tmp_path / ".claude" / "skills" / "minispec-design" / "SKILL.md").write_text("---\nname: minispec-design\n---\nbody")
        (tmp_path / ".minispec").mkdir(parents=True)
        with pytest.raises(Exit):
            _detect_project_config(tmp_path)

    def test_no_minispec_dir(self, tmp_path):
        with pytest.raises(Exit):
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
