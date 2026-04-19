#!/usr/bin/env node
// scripts/hooks/pre-edit-deny-path.mjs
// Rule 3: deny-listed paths can never be written.

import { readFileSync } from "node:fs";

const GLOBAL_DENY = [
  /(^|[\\/])\.env\.local$/,
  /(^|[\\/])node_modules([\\/]|$)/,
  /(^|[\\/])Pods([\\/]|$)/,
  /(^|[\\/])DerivedData([\\/]|$)/,
  /(^|[\\/])\.git[\\/](objects|refs|hooks)[\\/]/,
  /(^|[\\/])\.ssh([\\/]|$)/,
  /(^|[\\/])Keys([\\/]|$)/,
  /(^|[\\/])logs[\\/]ssh-audit\.log$/,
];

function readInput() {
  try { return JSON.parse(readFileSync(0, "utf8")); } catch { return {}; }
}

const input = readInput();
const tool = input.tool_name || input.tool || "";
if (!/^(Write|Edit)$/.test(tool)) process.exit(0);

const inp = input.tool_input || {};
const filePath = inp.file_path || inp.path || "";

for (const re of GLOBAL_DENY) {
  if (re.test(filePath)) {
    console.error(`[pre-edit-deny-path] BLOCKED: '${filePath}' is on the global deny-list (pattern ${re}).`);
    process.exit(2);
  }
}

process.exit(0);
