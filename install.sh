#!/usr/bin/env bash
# Install the Claude Code status line into ~/.claude/hud and wire up settings.json.
#
#   git clone https://github.com/Domizze/claude-code-hud.git
#   cd claude-code-hud && ./install.sh
#
# Also works piped, with no clone:
#   curl -fsSL https://raw.githubusercontent.com/Domizze/claude-code-hud/main/install.sh | bash
#
# Idempotent: safe to re-run to update.
set -euo pipefail

REPO="Domizze/claude-code-hud"
BRANCH="main"
DEST="$HOME/.claude/hud"
FILES="metricc-cc-statusbar.mjs config.jsonc merge-settings.mjs"

command -v node >/dev/null || { echo "install.sh: node not found on PATH" >&2; exit 1; }

# Running from a clone? Then the files sit next to this script and there is
# nothing to download. Piped through bash, BASH_SOURCE points at nothing useful.
SRC=""
self="${BASH_SOURCE[0]:-}"
if [ -n "$self" ] && [ -f "$(dirname "$self")/metricc-cc-statusbar.mjs" ]; then
  SRC="$(cd "$(dirname "$self")" && pwd)"
fi

# Fetch one file to stdout. curl works on a public repo with no auth; gh covers
# the private case. Whichever is available wins, so flipping the repo's
# visibility never needs an edit here.
fetch() {
  if command -v curl >/dev/null && curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/$1"; then
    return 0
  fi
  command -v gh >/dev/null || {
    echo "install.sh: cannot download $1 - need curl on a public repo, or gh (gh auth login) on a private one" >&2
    return 1
  }
  gh api "repos/$REPO/contents/$1" -H "Accept: application/vnd.github.raw"
}

mkdir -p "$DEST"
for f in $FILES; do
  if [ -n "$SRC" ]; then
    echo "copying $f"
    cp "$SRC/$f" "$DEST/$f.tmp"
  else
    echo "fetching $f"
    fetch "$f" > "$DEST/$f.tmp"
  fi
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
