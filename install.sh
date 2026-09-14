#!/usr/bin/env bash
# Install the Claude Code status line into ~/.claude/hud and wire up settings.json.
# Idempotent: safe to re-run to update.
set -euo pipefail

REPO="Domizze/claude-code-hud"
DEST="$HOME/.claude/hud"

command -v node >/dev/null || { echo "install.sh: node not found on PATH" >&2; exit 1; }
command -v gh   >/dev/null || { echo "install.sh: gh not found on PATH (brew/winget install gh, then gh auth login)" >&2; exit 1; }

mkdir -p "$DEST"
for f in metricc-cc-statusbar.mjs config.jsonc; do
  echo "fetching $f"
  gh api "repos/$REPO/contents/$f" -H "Accept: application/vnd.github.raw" > "$DEST/$f.tmp"
  mv "$DEST/$f.tmp" "$DEST/$f"
done
rm -f "$DEST/.usage-cache.json" "$DEST/.version-cache.json"

# Merge the statusLine key into settings.json without clobbering anything else.
node -e '
const fs = require("fs"), path = require("path"), os = require("os");
const p = path.join(os.homedir(), ".claude", "settings.json");
const cmd = "node " + path.join(os.homedir(), ".claude", "hud", "metricc-cc-statusbar.mjs").replace(/\/g, "/");
let cfg = {};
if (fs.existsSync(p)) {
  const raw = fs.readFileSync(p, "utf-8").trim();
  if (raw) cfg = JSON.parse(raw);
  fs.copyFileSync(p, p + ".bak");
}
cfg.statusLine = { type: "command", command: cmd, padding: 0 };
fs.mkdirSync(path.dirname(p), { recursive: true });
fs.writeFileSync(p, JSON.stringify(cfg, null, 2) + "\n");
console.log("settings.json updated" + (fs.existsSync(p + ".bak") ? " (previous saved as settings.json.bak)" : ""));
'

# Smoke test: a real render against a fixture, so a broken install fails here and not silently in the UI.
FIXTURE=$(mktemp)
REPO_DIR=$(node -e 'process.stdout.write(process.cwd().replace(/\/g,"/"))')
cat > "$FIXTURE" <<JSON
{"workspace":{"current_dir":"$REPO_DIR"},"model":{"display_name":"Opus 5"},"version":"2.0.0","context_window":{"used_percentage":42}}
JSON
OUT=$(node "$DEST/metricc-cc-statusbar.mjs" < "$FIXTURE" || true)
rm -f "$FIXTURE"
case "$OUT" in
  ""|*"waiting for data"*) echo "install.sh: smoke test failed, status line produced no output" >&2; exit 1 ;;
esac
echo "$OUT"
echo
echo "installed. restart Claude Code to see it."
