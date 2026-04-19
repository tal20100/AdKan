# ADR 0007 — Windows-to-Mac Workflow

**Status:** Accepted. **Mac bridge: CURRENTLY OFFLINE (founder-deferred).**
**Date:** 2026-04-18.
**Deciders:** release-engineer, ios-engineer, founder.

## Context

The founder develops on a Windows 11 machine. iOS builds fundamentally require macOS + Xcode for code signing, device deployment, and App Store Connect uploads. Three workflow options:

1. **Dedicated Mac + SSH bridge** — keep a Mac powered on on the local network, SSH from Windows to trigger builds, use `fastlane` over SSH for signing + upload.
2. **Cloud CI only** — Xcode Cloud (Apple) builds from pushed git commits. No local Mac required.
3. **Hybrid** — Cloud CI for shipping builds; Mac for interactive debugging when available.

At the time of this ADR, the founder has a Mac but it is not currently connected/configured. A local Mac is valuable for interactive Xcode debugging but is not on the critical path for shipping a TestFlight build.

## Decision

Hybrid, with Cloud CI as the primary path.

- **Primary: Xcode Cloud** — 25 free compute hrs/mo bundled with the Apple Developer Program. Weekly TestFlight builds fit comfortably. dSYMs + symbolication handled by Apple. Triggered by git push to `main`.
- **Secondary: Mac bridge (deferred)** — when the Mac comes online, SSH from Windows with fastlane for local debug builds + faster iteration. Every SSH-dependent script has a deferred-stub behavior: prints `Mac bridge: OFFLINE (expected)` and exits 0 so CI stays green.
- **Config:** `config/mac-bridge.json` (gitignored; see `.env.example` for shape). When populated with `host`, `user`, `remoteRepoPath`, and the founder's SSH public key is added to `~/.ssh/authorized_keys` on the Mac, the scripts flip from stub → live with no code change.

Only three agents are authorized to SSH: `ios-engineer`, `qa-engineer`, `release-engineer`. Every SSH command is logged by the pre-SSH hook and scanned for secret-looking tokens.

## Alternatives considered

### Self-hosted GitHub Actions runner on the Mac
- **Pros:** push-triggered cloud-style CI without Xcode Cloud limits.
- **Cons:** requires the Mac to be online 24/7, consumes electricity, needs firewall exposure or GitHub's self-hosted runner auth rotation, duplicates what Xcode Cloud already provides inside the Developer Program fee.

Rejected for v1. Revisit if Xcode Cloud hour quota becomes a bottleneck.

### MacStadium / MacinCloud rental
- **Pros:** no physical Mac needed; access from anywhere.
- **Cons:** $30–80/mo added opex; violates the "minimum-cost MVP" rule; no offline work.

Rejected.

### Pure Xcode Cloud, no Mac bridge ever
- **Pros:** simplest mental model.
- **Cons:** interactive Xcode debugging (breakpoints, Instruments, live preview, device console) is impossible without a Mac. Some bug classes are effectively undetectable.

Rejected as the only path — hybrid beats pure cloud once the Mac is online.

### WSL2 + `xcode-select` tricks / GitHub Codespaces
- Xcode does not run on Linux. Not a viable path for iOS builds.

Rejected categorically.

## Implementation

### Xcode Cloud setup (primary)
1. Founder opens App Store Connect → Xcode Cloud → connect the GitHub repo `tal20100/adkan` (or equivalent).
2. Workflow: `Build + Test + TestFlight` — triggered on push to `main`.
3. Secrets: Supabase anon key, PostHog project key, Sentry DSN — added via Xcode Cloud Environment Variables (not in repo).
4. dSYM upload to Sentry via post-build script (secrets sourced from environment).
5. Signed builds auto-distributed to the "Internal" TestFlight group; external distribution gated on founder manual approval in App Store Connect.

### Mac bridge (deferred, ready)
Config file (gitignored) `config/mac-bridge.json`:
```json
{
  "host": "mac.local",
  "user": "tal",
  "sshKeyPath": "C:/Users/Tal/.ssh/adkan_mac_ed25519",
  "remoteRepoPath": "/Users/tal/dev/adkan",
  "xcodeVersion": "15.4",
  "keychainName": "adkan-ci.keychain-db"
}
```

Smoke-test script `scripts/hello-mac.mjs`:
- If `config/mac-bridge.json` is absent → prints `Mac bridge: OFFLINE (expected — founder deferred)` + exits 0.
- If present → runs `ssh -o BatchMode=yes <user>@<host> "xcodebuild -version"`, exits non-zero on failure.

Fastlane keychain-unlock pattern (ready for when bridge activates):
```ruby
# fastlane/Fastfile (deferred — written only after Mac comes online)
lane :beta do
  setup_ci
  unlock_keychain(
    path: ENV["MATCH_KEYCHAIN_NAME"],
    password: ENV["MATCH_KEYCHAIN_PASSWORD"]
  )
  match(type: "appstore", readonly: true)
  build_app(scheme: "AdKan", export_method: "app-store")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

### Pre-SSH hook
All SSH-using scripts route through `scripts/pre-ssh-check.mjs`, which:
1. Verifies the caller identity (agent name from arg).
2. Verifies caller is in the whitelist (`ios-engineer`, `qa-engineer`, `release-engineer`).
3. Greps the proposed command for `[A-Za-z0-9+/=]{40,}` → blocks if matched.
4. Appends a log line to `logs/ssh-audit.log` (gitignored).

## Consequences

**Positive:**
- Zero day-1 blocker from Mac availability — Xcode Cloud ships the app.
- When the Mac comes online, the bridge is pre-wired: config file + SSH key setup + scripts are already in place.
- Pre-SSH hook centralizes audit and secret-prevention across all SSH usage.
- Build reproducibility: Xcode Cloud is Apple's own builder, highest fidelity vs. what App Review sees.

**Negative:**
- Interactive Xcode debugging unavailable until the Mac bridge is up.
- 25 hrs/mo Xcode Cloud quota is comfortable but not unlimited — we will revisit if TestFlight cadence exceeds weekly.
- Two paths (cloud + local) create small duplication in build config documentation.

## Current state (as of ADR date)

- Xcode Cloud: **not yet configured** (blocked on founder-action #1: Apple Developer Program enrollment + App Store Connect app record).
- Mac bridge: **OFFLINE** (`config/mac-bridge.json` absent). `scripts/hello-mac.mjs` prints the deferred stub. Not a blocker.
