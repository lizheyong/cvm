#!/usr/bin/env node
import { existsSync, mkdirSync, copyFileSync, readFileSync, appendFileSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const home = homedir();
const cvmDir = join(home, ".claude-versions");
const cvmSh = join(cvmDir, "cvm.sh");
const sourceLine = `\n# CVM - Claude Version Manager\n[[ -s "$HOME/.claude-versions/cvm.sh" ]] && source "$HOME/.claude-versions/cvm.sh"\n`;

// 1. Copy cvm.sh
mkdirSync(cvmDir, { recursive: true });
const src = join(new URL(".", import.meta.url).pathname, "cvm.sh");
copyFileSync(src, cvmSh);
console.log(`\x1b[32m✓\x1b[0m cvm.sh → ${cvmSh}`);

// 2. Inject source line into shell rc
const shellRcs = [".zshrc", ".bashrc"].map((f) => join(home, f));
let injected = false;

for (const rc of shellRcs) {
  if (!existsSync(rc)) continue;
  const content = readFileSync(rc, "utf-8");
  if (content.includes(".claude-versions/cvm.sh")) {
    console.log(`\x1b[32m✓\x1b[0m ${rc} 已包含 cvm source，跳过`);
    injected = true;
    continue;
  }
  appendFileSync(rc, sourceLine);
  console.log(`\x1b[32m✓\x1b[0m 已添加 source 到 ${rc}`);
  injected = true;
}

if (!injected) {
  console.log(
    `\x1b[33m⚠\x1b[0m 未找到 .zshrc 或 .bashrc，请手动添加:\n  source ~/.claude-versions/cvm.sh`
  );
}

// 3. Done
console.log(`
\x1b[38;5;209m✦\x1b[0m \x1b[1mCVM 安装完成\x1b[0m

  重启终端或运行:  source ~/.claude-versions/cvm.sh
  然后:            cvm help
`);
