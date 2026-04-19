#!/usr/bin/env node
// scripts/hello-mac.mjs
//
// Day-1 smoke test for the Mac bridge (ADR 0007).
//
// Behavior:
//   - If config/mac-bridge.json is absent OR missing required fields,
//     prints an OFFLINE banner and exits 0 (expected / non-blocking).
//   - If config is present + populated, attempts a minimal SSH round-trip
//     (`xcodebuild -version`) and exits non-zero on failure.
//
// This keeps CI green during the Mac-deferred phase while giving a one-command
// check that flips real the moment the founder configures the bridge.

import { readFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");
const CONFIG_PATH = path.join(REPO_ROOT, "config", "mac-bridge.json");

function banner(line) {
  console.log(`[hello-mac] ${line}`);
}

async function loadConfig() {
  try {
    const raw = await readFile(CONFIG_PATH, "utf8");
    return JSON.parse(raw);
  } catch (err) {
    if (err.code === "ENOENT") return null;
    throw err;
  }
}

function isConfigComplete(cfg) {
  if (!cfg) return false;
  const required = ["host", "user", "sshKeyPath", "remoteRepoPath"];
  return required.every((k) => typeof cfg[k] === "string" && cfg[k].length > 0);
}

function runSsh(cfg) {
  return new Promise((resolve) => {
    const args = [
      "-o", "BatchMode=yes",
      "-o", "StrictHostKeyChecking=accept-new",
      "-o", "ConnectTimeout=10",
      "-i", cfg.sshKeyPath,
      `${cfg.user}@${cfg.host}`,
      "xcodebuild -version",
    ];
    const child = spawn("ssh", args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (c) => (stdout += c.toString()));
    child.stderr.on("data", (c) => (stderr += c.toString()));
    child.on("close", (code) => resolve({ code, stdout, stderr }));
    child.on("error", (err) => resolve({ code: 127, stdout: "", stderr: err.message }));
  });
}

async function main() {
  const cfg = await loadConfig();

  if (!isConfigComplete(cfg)) {
    banner("Mac bridge: OFFLINE (expected — founder deferred)");
    banner("When ready, see /plan/02-infrastructure-setup.md §mac-bridge");
    banner("Xcode Cloud remains the primary CI path — no action required to proceed");
    banner("exit 0 \u2713");
    process.exit(0);
  }

  banner(`Mac bridge: ONLINE target ${cfg.user}@${cfg.host}`);
  banner("Running: xcodebuild -version over SSH...");
  const { code, stdout, stderr } = await runSsh(cfg);

  if (code === 0) {
    banner("SSH round-trip OK. xcodebuild reports:");
    for (const line of stdout.trim().split(/\r?\n/)) banner(`  ${line}`);
    banner("exit 0 \u2713");
    process.exit(0);
  }

  banner(`SSH round-trip FAILED (exit ${code})`);
  if (stderr.trim()) {
    for (const line of stderr.trim().split(/\r?\n/)) banner(`  stderr: ${line}`);
  }
  banner("Fix: verify host reachable, sshKeyPath exists, authorized_keys on Mac, Xcode installed");
  process.exit(code || 1);
}

main().catch((err) => {
  banner(`FATAL: ${err.message}`);
  process.exit(1);
});
