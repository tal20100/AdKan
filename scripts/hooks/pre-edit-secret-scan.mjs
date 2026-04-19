#!/usr/bin/env node
// scripts/hooks/pre-edit-secret-scan.mjs
// Rule 2: secrets are radioactive. Block any Write/Edit that tries to create or write
// a secret file, OR whose content contains a likely secret token.
//
// Reads Claude Code's PreToolUse JSON on stdin; exits 2 to block, 0 to allow.

import { readFileSync } from "node:fs";

const DENY_FILENAME_PATTERNS = [
  /(^|[\\/])\.env(\.|$)/i,        // .env, .env.local, .env.production — but allow .env.example below
  /\.p8$/i,
  /\.p12$/i,
  /\.pem$/i,
  /\.cer$/i,
  /\.mobileprovision$/i,
  /AuthKey_[A-Z0-9]+\.p8$/i,
  /(^|[\\/])id_rsa(\.|$)/,
  /(^|[\\/])id_ed25519(\.|$)/,
  /(^|[\\/])\.ssh[\\/]/,
  /(^|[\\/])Keys[\\/]/,
];

const ALLOW_FILENAME_EXCEPTIONS = [
  /\.env\.example$/,
  /\.env\.template$/,
];

// Content patterns — only applied when path is not a docs file.
const DOCS_EXTS = new Set([".md", ".mdx", ".txt"]);
const SECRET_CONTENT_PATTERNS = [
  { pattern: /\b(sk|pk_live)[-_][A-Za-z0-9]{20,}\b/, hint: "Stripe-style live key" },
  { pattern: /\beyJ[A-Za-z0-9_\-]{30,}\.[A-Za-z0-9_\-]{30,}\.[A-Za-z0-9_\-]{20,}\b/, hint: "JWT" },
  { pattern: /-----BEGIN (PRIVATE|RSA PRIVATE|EC PRIVATE|OPENSSH PRIVATE) KEY-----/, hint: "PEM private key" },
  { pattern: /\bSUPABASE_SERVICE_ROLE_KEY\s*=\s*['"]?eyJ/i, hint: "Supabase service-role key" },
];

// Generic high-entropy token — only flag outside docs and only if not tagged [FAKE].
const HIGH_ENTROPY = /[A-Za-z0-9+/=]{40,}/;

function readInput() {
  try {
    return JSON.parse(readFileSync(0, "utf8"));
  } catch {
    return {};
  }
}

function fail(reason) {
  console.error(`[pre-edit-secret-scan] BLOCKED: ${reason}`);
  process.exit(2);
}

const input = readInput();
const tool = input.tool_name || input.tool || "";
if (!/^(Write|Edit)$/.test(tool)) process.exit(0);

const inp = input.tool_input || {};
const filePath = inp.file_path || inp.path || "";
const content = inp.content || inp.new_string || "";

if (ALLOW_FILENAME_EXCEPTIONS.some((re) => re.test(filePath))) process.exit(0);

for (const re of DENY_FILENAME_PATTERNS) {
  if (re.test(filePath)) fail(`path '${filePath}' matches secret filename pattern ${re}`);
}

const ext = (filePath.match(/\.[^.\\/]+$/) || [""])[0].toLowerCase();
const isDocs = DOCS_EXTS.has(ext);

for (const { pattern, hint } of SECRET_CONTENT_PATTERNS) {
  if (pattern.test(content) && !content.includes("[FAKE]")) {
    fail(`content contains ${hint} pattern. Tag placeholder with [FAKE] if this is documentation.`);
  }
}

if (!isDocs) {
  const match = content.match(HIGH_ENTROPY);
  if (match && !content.includes("[FAKE]")) {
    const sample = match[0].slice(0, 12) + "...";
    fail(`content contains high-entropy token '${sample}' outside docs. Tag with [FAKE] if placeholder, else move to Supabase secrets / Xcode Cloud env vars.`);
  }
}

process.exit(0);
