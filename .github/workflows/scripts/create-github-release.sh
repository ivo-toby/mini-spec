#!/usr/bin/env bash
set -euo pipefail

# create-github-release.sh
# Create a GitHub release with all template zip files
# Usage: create-github-release.sh <version>

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"

# Remove 'v' prefix from version for release title
VERSION_NO_V=${VERSION#v}

gh release create "$VERSION" \
  .genreleases/minispec-template-copilot-sh.zip \
  .genreleases/minispec-template-copilot-ps.zip \
  .genreleases/minispec-template-claude-sh.zip \
  .genreleases/minispec-template-claude-ps.zip \
  .genreleases/minispec-template-gemini-sh.zip \
  .genreleases/minispec-template-gemini-ps.zip \
  .genreleases/minispec-template-cursor-agent-sh.zip \
  .genreleases/minispec-template-cursor-agent-ps.zip \
  .genreleases/minispec-template-opencode-sh.zip \
  .genreleases/minispec-template-opencode-ps.zip \
  .genreleases/minispec-template-qwen-sh.zip \
  .genreleases/minispec-template-qwen-ps.zip \
  .genreleases/minispec-template-windsurf-sh.zip \
  .genreleases/minispec-template-windsurf-ps.zip \
  .genreleases/minispec-template-codex-sh.zip \
  .genreleases/minispec-template-codex-ps.zip \
  .genreleases/minispec-template-kilocode-sh.zip \
  .genreleases/minispec-template-kilocode-ps.zip \
  .genreleases/minispec-template-auggie-sh.zip \
  .genreleases/minispec-template-auggie-ps.zip \
  .genreleases/minispec-template-roo-sh.zip \
  .genreleases/minispec-template-roo-ps.zip \
  .genreleases/minispec-template-codebuddy-sh.zip \
  .genreleases/minispec-template-codebuddy-ps.zip \
  .genreleases/minispec-template-qoder-sh.zip \
  .genreleases/minispec-template-qoder-ps.zip \
  .genreleases/minispec-template-amp-sh.zip \
  .genreleases/minispec-template-amp-ps.zip \
  .genreleases/minispec-template-shai-sh.zip \
  .genreleases/minispec-template-shai-ps.zip \
  .genreleases/minispec-template-q-sh.zip \
  .genreleases/minispec-template-q-ps.zip \
  .genreleases/minispec-template-bob-sh.zip \
  .genreleases/minispec-template-bob-ps.zip \
  --title "MiniSpec Templates - $VERSION_NO_V" \
  --notes-file release_notes.md
