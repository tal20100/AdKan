#!/usr/bin/env node
// scripts/hooks/post-edit-template-check.mjs
// Rule 4: warn (not block) if hard-coded 'AdKan' or 'עד כאן' appears in Swift/TS source
// outside the allowed paths.

import { readFileSync, existsSync } from "node:fs";

const CHECK_EXTS = /\.(swift|ts|tsx|sql|mjs|js)$/;
const ALLOW_PATHS = [
  /^CLAUDE\.md$/,
  /(^|[\\/])plan[\\/]/,
  /(^|[\\/])research[\\/]/,
  /(^|[\\/])prd[\\/]/,
  /(^|[\\/])specs[\\/]/,
  /(^|[\\/])adr[\\/]/,
  /(^|[\\/])README\.md$/,
  /(^|[\\/])config[\\/]app-identity\.json$/,
  /(^|[\\/])Localization[\\/].+\.xcstrings$/,
  /\.env\.(example|template)$/,
  /Package\.swift$/,
  /package\.json$/,
];

function readInput() {
  try { return JSON.parse(readFileSync(0, "utf8")); } catch { return {}; }
}

const input = readInput();
const tool = input.tool_name || input.tool || "";
if (!/^(Write|Edit)$/.test(tool)) process.exit(0);

const inp = input.tool_input || {};
const filePath = inp.file_path || inp.path || "";
if (!CHECK_EXTS.test(filePath)) process.exit(0);
if (ALLOW_PATHS.some((re) => re.test(filePath))) process.exit(0);

let content = inp.content || inp.new_string || "";
if (!content && existsSync(filePath)) {
  try { content = readFileSync(filePath, "utf8"); } catch {}
}

const hits = [];
if (/\bAdKan\b/.test(content)) hits.push("'AdKan'");
if (/עד כאן/.test(content)) hits.push("'עד כאן'");

if (hits.length > 0) {
  console.warn(`[post-edit-template-check] warning: ${filePath} contains hard-coded ${hits.join(" + ")}. Consider templating from config/app-identity.json (\${APP_NAME} / \${APP_NAME_HE}).`);
}

process.exit(0);  // warn-only, never block
