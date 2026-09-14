// Merge the statusLine key into ~/.claude/settings.json, leaving everything else alone.
// Run by install.sh; safe to run directly.
import { existsSync, readFileSync, writeFileSync, copyFileSync, mkdirSync } from "node:fs";
import { join, dirname, sep } from "node:path";
import { homedir } from "node:os";

const settingsPath = join(homedir(), ".claude", "settings.json");
const script = join(homedir(), ".claude", "hud", "metricc-cc-statusbar.mjs").split(sep).join("/");

let cfg = {};
let backedUp = false;
if (existsSync(settingsPath)) {
  const raw = readFileSync(settingsPath, "utf-8").trim();
  if (raw) {
    try {
      cfg = JSON.parse(raw);
    } catch (err) {
      console.error(`merge-settings: ${settingsPath} is not valid JSON, refusing to overwrite it`);
      console.error(`  ${err.message}`);
      process.exit(1);
    }
  }
  copyFileSync(settingsPath, settingsPath + ".bak");
  backedUp = true;
}

cfg.statusLine = { type: "command", command: `node ${script}`, padding: 0 };

mkdirSync(dirname(settingsPath), { recursive: true });
writeFileSync(settingsPath, JSON.stringify(cfg, null, 2) + "\n");
console.log(`settings.json updated${backedUp ? " (previous saved as settings.json.bak)" : ""}`);
