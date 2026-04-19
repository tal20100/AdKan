# Windows → Mac SSH iOS build workflow

Status as of Build Day 1: **the Mac is not connected.** Every SSH step below is marked `[UNTESTED]`. When the founder brings the Mac online, `release-engineer` runs through this file top-to-bottom, updates statuses, and reports results into `/plan/status.md`.

---

## 1. Architecture summary

```
Windows 11 (primary dev)                Mac (build server, OFFLINE)
├── Claude Code orchestrator            ├── Xcode + iOS Simulator
├── VS Code file edits                  ├── xcodebuild / swift test
├── Git, Supabase CLI, Deno             ├── fastlane (optional)
├── Backend dev + tests                 ├── Code signing keychain
│                                       │
└── ssh mac "..." ───────────────→      └── Receives build commands
                                            (when online)
```

Sync model: Windows pushes to GitHub, Mac pulls before each build. **No SMB / SSHFS filesystem share** — too fragile across OS, too slow over Wi-Fi, lock contention with concurrent Xcode.

**Critical insight** from Phase 1 research: Xcode Cloud (25 free hrs/mo with the $99/yr Dev Program) makes the Mac optional for MVP shipping. The Mac is only needed for fast local debug builds. All TestFlight distribution can go through Xcode Cloud while the Mac is offline.

---

## 2. SSH key setup — Windows to macOS `[UNTESTED]`

### On Windows (PowerShell or Git Bash)
```
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_adkan_ed25519" -C "adkan-windows-to-mac"
```
No passphrase if the Mac is a trusted home device on the same LAN. Passphrase + `ssh-agent` if the Mac is shared.

### On macOS (founder types these on the Mac)
```
System Settings → General → Sharing → Remote Login: ON
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# paste the contents of Windows id_adkan_ed25519.pub into:
vi ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Smoke test from Windows
```
ssh -i ~/.ssh/id_adkan_ed25519 tal@mac "sw_vers && xcodebuild -version"
```
Expected: macOS version + Xcode version. Failure path: check `/var/log/system.log` on Mac for `sshd` rejection reason.

---

## 3. xcodebuild over SSH `[UNTESTED]`

```
ssh tal@mac "cd ~/adkan && git pull && xcodebuild \
  -scheme AdKan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test"
```

Known issues (Phase 1 research, documented gotchas):
- Use `-T` (no TTY allocation) for non-interactive builds; otherwise xcodebuild output buffering is weird.
- Set `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8` on Mac side for fastlane UTF-8 compliance.
- Redirect large output via `tee` for durable logs.

## 4. Code signing over SSH `[UNTESTED, high-risk]`

Code signing requires keychain access. SSH sessions do NOT auto-unlock the login keychain.

### Solution A (recommended, non-interactive)
```
ssh tal@mac "security unlock-keychain -p \$KEYCHAIN_PASSWORD ~/Library/Keychains/login.keychain-db"
```
`KEYCHAIN_PASSWORD` is an env var injected via Supabase secrets or a local `.env.local` on the Mac — **never passed inline on the command** (would be logged by the `pre-ssh-command` hook's secret scan).

### Solution B (fastlane)
```
ssh tal@mac "cd ~/adkan && fastlane setup_ci && fastlane unlock_keychain && fastlane beta"
```
Fastlane's `setup_ci` action removes the ACL prompts that normally block non-GUI signing.

## 5. Fastlane over SSH `[UNTESTED]`

Gotchas:
- 2FA: use `FASTLANE_USER`, `FASTLANE_PASSWORD`, `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` env vars. 2FA prompt over SSH = hang.
- `match` certificate repo: store repo in a private GitHub repo; key stored as `MATCH_PASSWORD` in Mac `.env.local`.
- Expect periodic Apple-session expiry prompts — fastlane will hang on SSH. Solution: re-auth manually once, then the session cookie persists for ~30 days.

## 6. Alternative: GitHub Actions self-hosted runner

If SSH pain accumulates, the Mac can become a self-hosted GitHub Actions runner:
- Runner agent is configured once via SSH, then GitHub orchestrates all future builds.
- Logs land in GitHub UI — easier to share.
- No per-build SSH round-trips.
- Downside: runner agent must stay running; tie to launchd.

Decision: **start with raw SSH**. Migrate to self-hosted runner if build frequency exceeds ~5/day and the SSH overhead becomes noticeable.

## 7. Device-less path for today

The `scripts/hello-mac.mjs` smoke test is the Day-1 equivalent of "is the Mac alive?" It attempts an SSH handshake using `config/mac-bridge.json` (gitignored). If the file is absent or the SSH fails:

```
[hello-mac] Mac bridge: OFFLINE (expected — founder deferred)
[hello-mac] When ready, see /plan/02-infrastructure-setup.md §mac-bridge
[hello-mac] Xcode Cloud remains the primary CI path — no action required to proceed
[hello-mac] exit 0 ✓
```

Exit 0 because the deferred state is expected, not an error.

## 8. Sources

- Microsoft: Pair to Mac for iOS — https://learn.microsoft.com/en-us/dotnet/maui/ios/pair-to-mac
- AWS CodeBuild: Fastlane code signing — https://docs.aws.amazon.com/codebuild/latest/userguide/sample-fastlane.html
- Fastlane sync_code_signing (match) — https://docs.fastlane.tools/actions/sync_code_signing/
- GitHub: self-hosted vs hosted runners — https://github.blog/enterprise-software/ci-cd/when-to-choose-github-hosted-runners-or-self-hosted-runners-with-github-actions/
- Apple devforum (keychain unlock over SSH) — https://developer.apple.com/forums/
