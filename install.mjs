#!/usr/bin/env node
import { existsSync, mkdirSync, copyFileSync, readFileSync, appendFileSync } from "fs";
import { join } from "path";
import { homedir } from "os";

// Use stderr — npm silences stdout from postinstall scripts
const log = (msg) => process.stderr.write(msg + "\n");

const home = homedir();
const cvmDir = join(home, ".claude-versions");
const cvmSh = join(cvmDir, "cvm.sh");
const sourceLine = `\n# CVM - Claude Version Manager\n[[ -s "$HOME/.claude-versions/cvm.sh" ]] && source "$HOME/.claude-versions/cvm.sh"\n`;

// 1. Copy cvm.sh
mkdirSync(cvmDir, { recursive: true });
const src = join(new URL(".", import.meta.url).pathname, "cvm.sh");
copyFileSync(src, cvmSh);
log(`\x1b[32m✓\x1b[0m cvm.sh → ${cvmSh}`);

// 2. Inject source line into shell rc
const shellRcs = [".zshrc", ".bashrc"].map((f) => join(home, f));
let injected = false;

for (const rc of shellRcs) {
  if (!existsSync(rc)) continue;
  const content = readFileSync(rc, "utf-8");
  if (content.includes(".claude-versions/cvm.sh")) {
    log(`\x1b[32m✓\x1b[0m ${rc} already configured, skipped`);
    injected = true;
    continue;
  }
  appendFileSync(rc, sourceLine);
  log(`\x1b[32m✓\x1b[0m Added source line to ${rc}`);
  injected = true;
}

if (!injected) {
  log(
    `\x1b[33m⚠\x1b[0m No .zshrc or .bashrc found. Add manually:\n  source ~/.claude-versions/cvm.sh`
  );
}

// 3. Done
log(`
\x1b[38;5;209m✦\x1b[0m \x1b[1mCVM installed!\x1b[0m

  \x1b[1mRestart your terminal\x1b[0m, then run:  cvm help
`);
