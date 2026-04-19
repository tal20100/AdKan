#!/usr/bin/env node
// scripts/hooks/pre-commit-localization-gate.mjs
// Rule 6: every .xcstrings key has both 'he' and 'en' entries with non-empty values.

import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";

function stagedFiles() {
  try {
    const out = execSync("git diff --cached --name-only --diff-filter=ACM", { encoding: "utf8" });
    return out.split(/\r?\n/).filter(Boolean);
  } catch {
    return [];
  }
}

const catalogs = stagedFiles().filter((f) => f.endsWith(".xcstrings"));
if (catalogs.length === 0) process.exit(0);

let failed = 0;

for (const file of catalogs) {
  if (!existsSync(file)) continue;
  let catalog;
  try {
    catalog = JSON.parse(readFileSync(file, "utf8"));
  } catch (err) {
    console.error(`[pre-commit-localization-gate] invalid JSON in ${file}: ${err.message}`);
    failed++;
    continue;
  }
  const strings = catalog.strings || {};
  for (const [key, entry] of Object.entries(strings)) {
    const locs = (entry && entry.localizations) || {};
    for (const lang of ["he", "en"]) {
      const val = locs[lang]?.stringUnit?.value;
      if (typeof val !== "string" || val.trim() === "") {
        console.error(`[pre-commit-localization-gate] ${file}: key '${key}' missing '${lang}' value`);
        failed++;
      }
    }
  }
}

if (failed > 0) {
  console.error(`[pre-commit-localization-gate] ${failed} parity issue(s). Commit blocked.`);
  process.exit(1);
}

process.exit(0);
