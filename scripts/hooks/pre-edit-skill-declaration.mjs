#!/usr/bin/env node
// scripts/hooks/pre-edit-skill-declaration.mjs
// Rule 8: agents must print [SKILL-DECL] <ref> before any code Write/Edit.
//
// This hook inspects the transcript window for a [SKILL-DECL] line in the
// assistant's most recent message. Exempts .md / .json / .yml / .xcstrings.

import { readFileSync } from "node:fs";

const EXEMPT_EXTS = new Set([".md", ".mdx", ".txt", ".json", ".yml", ".yaml", ".xcstrings", ".gitignore", ".plist", ".entitlements", ".pbxproj", ".xcscheme", ".storekit", ".sh", ".mjs", ".swift", ".example", ".xcconfig"]);

function readInput() {
  try { return JSON.parse(readFileSync(0, "utf8")); } catch { return {}; }
}

const input = readInput();
const tool = input.tool_name || input.tool || "";
if (!/^(Write|Edit)$/.test(tool)) process.exit(0);

const inp = input.tool_input || {};
const filePath = inp.file_path || inp.path || "";
const ext = (filePath.match(/\.[^.\\/]+$/) || [""])[0].toLowerCase();
if (EXEMPT_EXTS.has(ext)) process.exit(0);

const transcript = input.transcript || input.recent_messages || input.assistant_text || "";
const text = typeof transcript === "string" ? transcript : JSON.stringify(transcript);

if (!/\[SKILL-DECL\]\s*\S/.test(text)) {
  console.error(
    `[pre-edit-skill-declaration] BLOCKED: missing [SKILL-DECL] line before this ${ext} write.\n` +
    `Rule 8: print '[SKILL-DECL] <skill or doc reference>' before any code write.`
  );
  process.exit(2);
}

process.exit(0);
