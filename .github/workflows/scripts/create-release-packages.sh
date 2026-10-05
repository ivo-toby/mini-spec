#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.sh (workflow-local)
# Build MiniSpec template release archives for each supported AI assistant and script type.
# Usage: .github/workflows/scripts/create-release-packages.sh <version>
#   Version argument should include leading 'v'.
#   Optionally set AGENTS and/or SCRIPTS env vars to limit what gets built.
#     AGENTS  : space or comma separated subset of: claude gemini copilot cursor-agent qwen opencode windsurf codex amp shai bob (default: all)
#     SCRIPTS : space or comma separated subset of: sh ps (default: both)
#   Examples:
#     AGENTS=claude SCRIPTS=sh $0 v0.2.0
#     AGENTS="copilot,gemini" $0 v0.2.0
#     SCRIPTS=ps $0 v0.2.0

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi
NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building release packages for $NEW_VERSION"

# Create and use .genreleases directory for all build artifacts
GENRELEASES_DIR=".genreleases"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

rewrite_paths() {
  sed -E \
    -e 's@(/?)memory/@.minispec/memory/@g' \
    -e 's@(/?)scripts/@.minispec/scripts/@g' \
    -e 's@(/?)templates/@.minispec/templates/@g'
}

template_description() {
  # Echo the description: value from a template's YAML frontmatter.
  local template=$1
  tr -d '\r' < "$template" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}'
}

render_command_body() {
  # $1=template file, $2=script_variant (sh|ps), $3=agent, $4=arg_format.
  # Emits the processed body to stdout. Description extraction lives in
  # template_description: callers read body via command substitution, which is
  # a bash subshell, so function-set "globals" cannot flow back.
  local template=$1 script_variant=$2 agent=$3 arg_format=$4
  local script_command agent_script_command body file_content
    
    # Normalize line endings
    file_content=$(tr -d '\r' < "$template")
    
    # Extract script command from YAML frontmatter
    script_command=$(printf '%s\n' "$file_content" | awk -v sv="$script_variant" '/^[[:space:]]*'"$script_variant"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, ""); print; exit}')
    
    if [[ -z $script_command ]]; then
      echo "Warning: no script command found for $script_variant in $template" >&2
      script_command="(Missing script command for $script_variant)"
    fi
    
    # Extract agent_script command from YAML frontmatter if present
    agent_script_command=$(printf '%s\n' "$file_content" | awk '
      /^agent_scripts:$/ { in_agent_scripts=1; next }
      in_agent_scripts && /^[[:space:]]*'"$script_variant"':[[:space:]]*/ {
        sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, "")
        print
        exit
      }
      in_agent_scripts && /^[a-zA-Z]/ { in_agent_scripts=0 }
    ')
    
    # Replace {SCRIPT} placeholder with the script command
    body=$(printf '%s\n' "$file_content" | sed "s|{SCRIPT}|${script_command}|g")
    
    # Replace {AGENT_SCRIPT} placeholder with the agent script command if found
    if [[ -n $agent_script_command ]]; then
      body=$(printf '%s\n' "$body" | sed "s|{AGENT_SCRIPT}|${agent_script_command}|g")
    fi
    
    # Remove the scripts: and agent_scripts: sections from frontmatter while preserving YAML structure
    body=$(printf '%s\n' "$body" | awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^agent_scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ')
    
    # Apply other substitutions
    body=$(printf '%s\n' "$body" | sed "s/{ARGS}/$arg_format/g" | sed "s/__AGENT__/$agent/g" | rewrite_paths)

  printf '%s\n' "$body"
}

generate_commands() {
  local agent=$1 ext=$2 arg_format=$3 output_dir=$4 script_variant=$5
  mkdir -p "$output_dir"
  for template in templates/commands/*.md; do
    [[ -f "$template" ]] || continue
    local name description body
    name=$(basename "$template" .md)
    body=$(render_command_body "$template" "$script_variant" "$agent" "$arg_format")
    description=$(template_description "$template")
    
    case $ext in
      toml)
        body=$(printf '%s\n' "$body" | sed 's/\\/\\\\/g')
        { echo "description = \"$description\""; echo; echo "prompt = \"\"\""; echo "$body"; echo "\"\"\""; } > "$output_dir/minispec-$name.$ext" ;;
      md)
        echo "$body" > "$output_dir/minispec-$name.$ext" ;;
      agent.md)
        echo "$body" > "$output_dir/minispec-$name.$ext" ;;
    esac
  done
}

generate_skills() {
  # Agentskills.io SKILL.md layout: <output_dir>/minispec-<stem>/SKILL.md.
  # Same body pipeline as generate_commands; the SKILL.md frontmatter replaces
  # the template's own description/scripts frontmatter.
  local agent=$1 output_dir=$2 script_variant=$3
  mkdir -p "$output_dir"
  for template in templates/commands/*.md; do
    [[ -f "$template" ]] || continue
    local name stem description body skill_dir
    name=$(basename "$template" .md)
    stem=${name//./-}
    if [[ ! "minispec-$stem" =~ ^minispec-[a-z0-9-]+$ ]]; then
      echo "Error: invalid skill name 'minispec-$stem' from $template (must match ^minispec-[a-z0-9-]+\$)" >&2
      exit 1
    fi
    body=$(render_command_body "$template" "$script_variant" "$agent" "\$ARGUMENTS")
    description=$(template_description "$template")
    body=$(printf '%s\n' "$body" | awk '
      NR==1 && $0=="---" { in_frontmatter=1; next }
      in_frontmatter && $0=="---" { in_frontmatter=0; next }
      in_frontmatter { next }
      { print }
    ')
    skill_dir="$output_dir/minispec-$stem"
    mkdir -p "$skill_dir"
    cat > "$skill_dir/SKILL.md" <<EOF
---
name: minispec-$stem
description: $description
compatibility: Requires MiniSpec project structure with .minispec/ directory
metadata:
  author: ivo-toby/minispec
  source: templates/commands/$(basename "$template")
---

$body
EOF
  done
}
build_variant() {
  local agent=$1 script=$2
  local base_dir="$GENRELEASES_DIR/minispec-${agent}-package-${script}"
  echo "Building $agent ($script) package..."
  mkdir -p "$base_dir"

  # Copy base structure but filter scripts by variant
  SPEC_DIR="$base_dir/.minispec"
  mkdir -p "$SPEC_DIR"

  [[ -d memory ]] && { cp -r memory "$SPEC_DIR/"; echo "Copied memory -> .minispec"; }

  # Only copy the relevant script variant directory
  if [[ -d scripts ]]; then
    mkdir -p "$SPEC_DIR/scripts"
    case $script in
      sh)
        [[ -d scripts/bash ]] && { cp -r scripts/bash "$SPEC_DIR/scripts/"; echo "Copied scripts/bash -> .minispec/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
      ps)
        [[ -d scripts/powershell ]] && { cp -r scripts/powershell "$SPEC_DIR/scripts/"; echo "Copied scripts/powershell -> .minispec/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
    esac
  fi

  [[ -d templates ]] && { mkdir -p "$SPEC_DIR/templates"; find templates -type f -not -path "templates/commands/*" -not -name "vscode-settings.json" -exec cp --parents {} "$SPEC_DIR"/ \; ; echo "Copied templates -> .minispec/templates"; }

  [[ -d hooks ]] && { cp -r hooks "$SPEC_DIR/"; echo "Copied hooks -> .minispec/hooks"; }

  # NOTE: We substitute {ARGS} internally. Outward tokens differ intentionally:
  #   * Markdown command-file agents + skill bodies: $ARGUMENTS
  #   * TOML (gemini): {{args}}
  # This keeps formats readable without extra abstraction.

  case $agent in
    claude)
      generate_skills claude "$base_dir/.claude/skills" "$script"
      [[ -f hooks/adapters/claude-code.json ]] && cp hooks/adapters/claude-code.json "$base_dir/.claude/settings.json" ;;
    gemini)
      mkdir -p "$base_dir/.gemini/commands"
      generate_commands gemini toml "{{args}}" "$base_dir/.gemini/commands" "$script"
      [[ -f agent_templates/gemini/GEMINI.md ]] && cp agent_templates/gemini/GEMINI.md "$base_dir/GEMINI.md" ;;
    copilot)
      generate_skills copilot "$base_dir/.github/skills" "$script"
      # Create VS Code workspace settings
      mkdir -p "$base_dir/.vscode"
      [[ -f templates/vscode-settings.json ]] && cp templates/vscode-settings.json "$base_dir/.vscode/settings.json"
      ;;
    cursor-agent)
      generate_skills cursor-agent "$base_dir/.cursor/skills" "$script" ;;
    qwen)
      mkdir -p "$base_dir/.qwen/commands"
      generate_commands qwen md "\$ARGUMENTS" "$base_dir/.qwen/commands" "$script"
      [[ -f agent_templates/qwen/QWEN.md ]] && cp agent_templates/qwen/QWEN.md "$base_dir/QWEN.md" ;;
    opencode)
      mkdir -p "$base_dir/.opencode/command"
      generate_commands opencode md "\$ARGUMENTS" "$base_dir/.opencode/command" "$script" ;;
    windsurf)
      mkdir -p "$base_dir/.windsurf/workflows"
      generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" ;;
    codex)
      generate_skills codex "$base_dir/.agents/skills" "$script" ;;
    kilocode)
      mkdir -p "$base_dir/.kilo/commands"
      generate_commands kilocode md "\$ARGUMENTS" "$base_dir/.kilo/commands" "$script" ;;
    auggie)
      mkdir -p "$base_dir/.augment/commands"
      generate_commands auggie md "\$ARGUMENTS" "$base_dir/.augment/commands" "$script" ;;
    roo)
      mkdir -p "$base_dir/.roo/commands"
      generate_commands roo md "\$ARGUMENTS" "$base_dir/.roo/commands" "$script" ;;
    codebuddy)
      mkdir -p "$base_dir/.codebuddy/commands"
      generate_commands codebuddy md "\$ARGUMENTS" "$base_dir/.codebuddy/commands" "$script" ;;
    qoder)
      generate_skills qoder "$base_dir/.qoder/skills" "$script" ;;
    amp)
      mkdir -p "$base_dir/.agents/commands"
      generate_commands amp md "\$ARGUMENTS" "$base_dir/.agents/commands" "$script" ;;
    shai)
      mkdir -p "$base_dir/.shai/commands"
      generate_commands shai md "\$ARGUMENTS" "$base_dir/.shai/commands" "$script" ;;
    pi)
      mkdir -p "$base_dir/.pi/prompts"
      generate_commands pi md "\$ARGUMENTS" "$base_dir/.pi/prompts" "$script" ;;
    q)
      mkdir -p "$base_dir/.amazonq/prompts"
      generate_commands q md "\$ARGUMENTS" "$base_dir/.amazonq/prompts" "$script" ;;
    bob)
      mkdir -p "$base_dir/.bob/commands"
      generate_commands bob md "\$ARGUMENTS" "$base_dir/.bob/commands" "$script" ;;
  esac
  ( cd "$base_dir" && zip -r "../minispec-template-${agent}-${script}.zip" . ) > /dev/null
  echo "Created $GENRELEASES_DIR/minispec-template-${agent}-${script}.zip"

  # Post-build assertions: skills agents get the skills layout, and no zip may
  # contain dot-named command files.
  local zipfile="$GENRELEASES_DIR/minispec-template-${agent}-${script}.zip"
  # grep -q would SIGPIPE unzip under pipefail, so capture the listing first.
  local zip_contents
  zip_contents=$(unzip -l "$zipfile")
  case $agent in
    claude|cursor-agent|copilot|codex|qoder)
      if ! grep -q "skills/minispec-design/SKILL.md" <<<"$zip_contents"; then
        echo "Assertion failed: $zipfile is missing skills/minispec-design/SKILL.md" >&2
        exit 1
      fi ;;
  esac
  if grep -qE 'minispec\.[a-z-]+\.(md|toml|agent\.md)' <<<"$zip_contents"; then
    echo "Assertion failed: $zipfile contains dot-named command files" >&2
    exit 1
  fi
}

# Determine agent list
ALL_AGENTS=(claude gemini copilot cursor-agent qwen opencode windsurf codex kilocode auggie roo codebuddy amp shai q bob qoder pi)
ALL_SCRIPTS=(sh ps)

norm_list() {
  # convert comma+space separated -> line separated unique while preserving order of first occurrence
  tr ',\n' '  ' | awk '{for(i=1;i<=NF;i++){if(!seen[$i]++){printf((out?"\n":"") $i);out=1}}}END{printf("\n")}'
}

validate_subset() {
  local type=$1; shift; local -n allowed=$1; shift; local items=("$@")
  local invalid=0
  for it in "${items[@]}"; do
    local found=0
    for a in "${allowed[@]}"; do [[ $it == "$a" ]] && { found=1; break; }; done
    if [[ $found -eq 0 ]]; then
      echo "Error: unknown $type '$it' (allowed: ${allowed[*]})" >&2
      invalid=1
    fi
  done
  return $invalid
}

if [[ -n ${AGENTS:-} ]]; then
  mapfile -t AGENT_LIST < <(printf '%s' "$AGENTS" | norm_list)
  validate_subset agent ALL_AGENTS "${AGENT_LIST[@]}" || exit 1
else
  AGENT_LIST=("${ALL_AGENTS[@]}")
fi

if [[ -n ${SCRIPTS:-} ]]; then
  mapfile -t SCRIPT_LIST < <(printf '%s' "$SCRIPTS" | norm_list)
  validate_subset script ALL_SCRIPTS "${SCRIPT_LIST[@]}" || exit 1
else
  SCRIPT_LIST=("${ALL_SCRIPTS[@]}")
fi

echo "Agents: ${AGENT_LIST[*]}"
echo "Scripts: ${SCRIPT_LIST[*]}"

for agent in "${AGENT_LIST[@]}"; do
  for script in "${SCRIPT_LIST[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo "Archives in $GENRELEASES_DIR:"
ls -1 "$GENRELEASES_DIR"/minispec-template-*.zip

