#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const home = homedir();

// Remove source line from shell rc files
const shellRcs = [".zshrc", ".bashrc"].map((f) => join(home, f));

for (const rc of shellRcs) {
  if (!existsSync(rc)) continue;
  const content = readFileSync(rc, "utf-8");
  if (!content.includes(".claude-versions/cvm.sh")) continue;

  const cleaned = content
    .replace(/\n# CVM - Claude Version Manager\n\[\[ -s .*cvm\.sh.*\]\] && source .*cvm\.sh.*\n/g, "\n")
    .replace(/\nsource .*cvm\.sh.*\n/g, "\n");

  writeFileSync(rc, cleaned);
  console.log(`\x1b[32m✓\x1b[0m 已从 ${rc} 移除 cvm source`);
}

console.log(`\x1b[2m注: ~/.claude-versions/ 目录已保留（含已安装的版本），如需清理请手动删除\x1b[0m`);
