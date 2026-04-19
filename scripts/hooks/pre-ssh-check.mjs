#!/usr/bin/env node
// scripts/hooks/pre-ssh-check.mjs
// Rule 9: SSH is privileged. Only ios-engineer, qa-engineer, release-engineer may SSH.
// Blocks SSH commands from other agents, or any SSH command that contains a
// secret-looking token inline.

import { readFileSync, mkdirSync, appendFileSync } from "node:fs";
import { dirname } from "node:path";

const WHITELIST = new Set(["ios-engineer", "qa-engineer", "release-engineer"]);
const SECRET_LIKE = /[A-Za-z0-9+/=]{40,}/;
const P8_INLINE = /-----BEGIN (PRIVATE|RSA PRIVATE|EC PRIVATE|OPENSSH PRIVATE) KEY-----/;

function readInput() {
  try { return JSON.parse(readFileSync(0, "utf8")); } catch { return {}; }
}

const input = readInput();
const tool = input.tool_name || input.tool || "";
if (tool !== "Bash") process.exit(0);

const cmd = (input.tool_input && input.tool_input.command) || "";
if (!/^\s*(ssh|scp)\s/.test(cmd)) process.exit(0);

const agent = input.agent_name || input.subagent_name || "orchestrator";

if (!WHITELIST.has(agent)) {
  console.error(`[pre-ssh-check] BLOCKED: agent '${agent}' is not in SSH whitelist {ios-engineer, qa-engineer, release-engineer}.`);
  process.exit(2);
}

if (SECRET_LIKE.test(cmd) || P8_INLINE.test(cmd)) {
  console.error(`[pre-ssh-check] BLOCKED: SSH command contains a secret-looking token inline. Use env vars on the Mac side, not command substitution.`);
  process.exit(2);
}

try {
  const logPath = "logs/ssh-audit.log";
  mkdirSync(dirname(logPath), { recursive: true });
  appendFileSync(logPath, `${new Date().toISOString()} ${agent} ${cmd.slice(0, 200)}\n`);
} catch {}

process.exit(0);
