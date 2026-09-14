#!/usr/bin/env bash
# Install the Claude Code status line into ~/.claude/hud and wire up settings.json.
# Idempotent: safe to re-run to update.
set -euo pipefail

REPO="Domizze/claude-code-hud"
DEST="$HOME/.claude/hud"

command -v node >/dev/null || { echo "install.sh: node not found on PATH" >&2; exit 1; }
command -v gh   >/dev/null || { echo "install.sh: gh not found on PATH (brew/winget install gh, then gh auth login)" >&2; exit 1; }

mkdir -p "$DEST"
for f in metricc-cc-statusbar.mjs config.jsonc merge-settings.mjs; do
  echo "fetching $f"
  gh api "repos/$REPO/contents/$f" -H "Accept: application/vnd.github.raw" > "$DEST/$f.tmp"
  mv "$DEST/$f.tmp" "$DEST/$f"
done
rm -f "$DEST/.usage-cache.json" "$DEST/.version-cache.json"

node "$DEST/merge-settings.mjs"

# Smoke test: a real render against a fixture, so a broken install fails here
# instead of silently showing nothing in the UI.
FIXTURE=$(mktemp)
CWD=$(node -p 'process.cwd().split(require("path").sep).join("/")')
cat > "$FIXTURE" <<JSON
{"workspace":{"current_dir":"$CWD"},"model":{"display_name":"Opus 5"},"version":"2.0.0","context_window":{"used_percentage":42}}
JSON
OUT=$(node "$DEST/metricc-cc-statusbar.mjs" < "$FIXTURE" || true)
rm -f "$FIXTURE"
case "$OUT" in
  ""|*"waiting for data"*)
    echo "install.sh: smoke test failed, the status line produced no output" >&2
    exit 1
    ;;
esac

echo "$OUT"
echo "installed. restart Claude Code to see it."
