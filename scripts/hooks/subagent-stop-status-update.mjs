#!/usr/bin/env node
// scripts/hooks/subagent-stop-status-update.mjs
// Appends a one-line turn log entry to plan/status.md each time a subagent stops.

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

function readInput() {
  try { return JSON.parse(readFileSync(0, "utf8")); } catch { return {}; }
}

const input = readInput();
const agent = input.subagent_name || input.agent_name || "orchestrator";
const subject = (input.subject || input.last_user_message || "").toString().slice(0, 80).replace(/\s+/g, " ").trim() || "(no subject)";
const filesTouched = (input.files_touched || input.tool_uses || []).length || "?";
const status = input.exit_status || input.status || "ok";
const ts = new Date().toISOString();

const statusPath = "plan/status.md";
const line = `- ${ts} ${agent} — ${subject} — ${filesTouched} files — ${status}\n`;

try {
  let content = existsSync(statusPath) ? readFileSync(statusPath, "utf8") : "";
  const marker = "## Turn log (last 20)";
  const markerIdx = content.indexOf(marker);
  if (markerIdx === -1) {
    // append a new section
    content += `\n\n${marker}\n\n${line}`;
  } else {
    // insert just after the marker's blank line
    const insertAt = content.indexOf("\n\n", markerIdx);
    if (insertAt === -1) {
      content += `\n${line}`;
    } else {
      content = content.slice(0, insertAt + 2) + line + content.slice(insertAt + 2);
    }
  }
  mkdirSync(dirname(statusPath), { recursive: true });
  writeFileSync(statusPath, content);
} catch (err) {
  console.error(`[subagent-stop-status-update] non-fatal: ${err.message}`);
}

process.exit(0);
