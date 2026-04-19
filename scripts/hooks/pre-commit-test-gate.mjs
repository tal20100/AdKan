#!/usr/bin/env node
// scripts/hooks/pre-commit-test-gate.mjs
// Rule 5: TDD. Every non-exempt source file under App/Features/** or App/Core/**
// must have at least one corresponding *Tests.swift file tracked in git.

import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";

function staged() {
  try {
    const out = execSync("git diff --cached --name-only --diff-filter=ACM", { encoding: "utf8" });
    return out.split(/\r?\n/).filter(Boolean);
  } catch { return []; }
}

function tracked() {
  try {
    const out = execSync("git ls-files", { encoding: "utf8" });
    return new Set(out.split(/\r?\n/).filter(Boolean));
  } catch { return new Set(); }
}

const EXEMPT = [
  /\.xcstrings$/,
  /View\.swift$/,                // snapshot tests cover views
  /[\\/]Fixtures[\\/]/,
  /[\\/]DesignSystem[\\/]/,
  /[\\/]Localization[\\/]/,
  /[\\/]AppRoot[\\/]/,
  /[\\/]Views[\\/]/,             // covered by snapshot tests
];

const stagedFiles = staged().filter((f) => /^App[\\/].+\.swift$/.test(f) && !f.endsWith("Tests.swift"));
if (stagedFiles.length === 0) process.exit(0);

const all = tracked();
let failed = 0;

for (const src of stagedFiles) {
  if (EXEMPT.some((re) => re.test(src))) continue;
  const base = path.basename(src, ".swift");
  const hasTests = [...all].some((t) => t.endsWith(`${base}Tests.swift`));
  if (!hasTests) {
    console.error(`[pre-commit-test-gate] ${src}: no ${base}Tests.swift tracked in git. TDD: write a failing test first (Rule 5).`);
    failed++;
  }
}

if (failed > 0) {
  console.error(`[pre-commit-test-gate] ${failed} file(s) missing tests. Commit blocked.`);
  process.exit(1);
}

process.exit(0);
