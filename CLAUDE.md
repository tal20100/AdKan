# AdKan — Claude Code session context

**Project:** AdKan / עד כאן (Hebrew: "enough, stop right there").
Hebrew+English iOS app, Israeli market, social screen-time competition.
Solo founder (tal20100). Claude Code orchestrates 15 specialist agents.

This file is auto-loaded at the start of every Claude Code session. It stays short on purpose. Detail lives in `/plan/`, `/prd/`, `/specs/`, `/adr/`, `/research/`.

---

## The 9 absolute rules

1. **Plan-mode gating** — governance files (`/plan`, `/specs`, `/prd`, `/adr`, `/research`) only during plan mode. Other writes require an approved plan.
2. **Secrets are radioactive** — never read/write/echo/commit `.env*` (except `.env.example`), `*.p8`, `*.p12`, `*.pem`, `AuthKey_*`, SSH private keys, `SUPABASE_SERVICE_ROLE_KEY`, `sk-*`, `pk-*`, long `eyJ*`. Pre-edit hook greps `[A-Za-z0-9+/=]{40,}` on every file write.
3. **Deny-listed paths** — never touch: `.env.local`, `~/.ssh/`, `~/Keys/` (and Windows equivalents), `.git/` (except reading `HEAD`), `node_modules/`, `Pods/`, `DerivedData/`.
4. **Template `${APP_NAME}` / `${APP_NAME_HE}`** — source of truth is `config/app-identity.json`. Never hard-code `AdKan` or `עד כאן` in Swift or TS source; always template.
5. **TDD** — `qa-engineer` writes the failing test first, then implementation. Pre-commit hook enforces.
6. **Hebrew + English parity** — both languages first-class, never machine-translated. `localization-lead` has veto on UI copy PRs. Pre-commit hook blocks any `.xcstrings` key missing either `he` or `en`.
7. **Escalation over invention** — ambiguous → ask the founder. Never fabricate pricing, statistics, copy, or Hebrew strings.
8. **`[SKILL-DECL]` before any code Write/Edit** — every implementation agent declares which skill/doc/reference it consulted. Pre-edit hook blocks otherwise. "I recall" is never acceptable.
9. **SSH is privileged** — only `ios-engineer`, `qa-engineer`, `release-engineer` may SSH. Mac config in `config/mac-bridge.json` (gitignored). **Current state: Mac bridge OFFLINE (deferred by founder).**

---

## Founder-confirmed decisions (locked)

- App name: **AdKan** / **עד כאן**
- Bundle ID: `com.taltalhayun.adkan`
- Deployment target: **iOS 16.0+**, iPhone only in v1
- Auth: **Apple Sign-In only** (no phone OTP, no email+password)
- Dev account: **Individual** (personal name on App Store listing; VAT collected by Apple)
- **No physical iPhone** — validation via TestFlight external testers + Sentry/PostHog as remote eyes
- **Mac deferred** — Xcode Cloud (25 free hrs/mo with Developer Program) is the primary CI path
- MVP = **TestFlight-quality, not App Store submitted**. Submission is a later milestone.

---

## The privacy boundary (binding)

The ONLY field that may cross the network per user per day is `dailyTotalMinutes: Int`.

Never syncs: per-app usage, per-category usage, per-hour buckets, device identifiers beyond the anonymous Supabase UUID, ScreenTime tokens, user location, contact list.

`security-reviewer` + `privacy-engineer` have veto on any PR that adds a field to the sync payload. See `adr/0004-data-leaves-device-policy.md` once written.

---

## The 15 agents

Full definitions in `.claude/agents/*.md`. Each file carries explicit `tools`, `deny_paths`, `model`, and `required_skills`.

- **product-strategist** — PRDs, feature scope, positioning
- **ux-designer** — SwiftUI layouts, Hebrew-first + RTL, interaction patterns
- **architecture-auditor** — module boundaries, SPM graph, drift detection
- **ios-engineer** — Swift, SwiftUI, FamilyControls. SSH-allowed.
- **backend-engineer** — Supabase schema, Edge Functions, Deno. Windows-only, never SSHs.
- **payments-engineer** — StoreKit 2, paywall, receipt validation
- **social-graph-engineer** — friends, groups, leaderboard, realtime
- **qa-engineer** — TDD, XCTest + XCUITest + snapshot tests. SSH-allowed.
- **security-reviewer** — VETO power; secret scans, threat model, OWASP
- **privacy-engineer** — VETO power; data-leaves-device policy, permissions UX
- **app-store-reviewer** — Guideline compliance, rejection-risk scan
- **growth-analytics-engineer** — PostHog funnels, event taxonomy, no PII
- **social-virality-designer** — viral unlock UX, IG-Story recap, invite copy
- **release-engineer** — Xcode Cloud, TestFlight, code signing. SSH-allowed.
- **localization-lead** — VETO power on UI copy; HE+EN parity, RTL correctness

Plus **orchestrator** (the main Claude Code session you're reading now).

---

## Operational defaults

- **Pause every 4–5 files** during Build phase. Orchestrator posts a status summary, awaits founder `continue` before the next batch.
- **Plan is the spine.** `/plan/00-overview.md` through `/plan/11-governance-and-hooks.md` define process. `/plan/status.md` is live state, updated by the `subagent-stop` hook.
- **Pre-commit hooks**: secret scan (gitleaks), test gate, localization parity.
- **Pre-edit hooks**: secret regex scan, deny-path check, `[SKILL-DECL]` presence.
- **Pre-SSH hook**: logs every SSH command, blocks any command containing a secret-looking token.

---

## First-hour orientation for any agent

1. Read this file.
2. Read `/plan/00-overview.md`.
3. Read the PRD, spec, or ADR your task names.
4. If writing code: read `/research/brainrot-unrot-learnings.md` + `/research/competitors-landscape.md` BEFORE designing features.
5. Before any code Write or Edit: print `[SKILL-DECL] <skill or doc reference>`.
6. Unclear? Escalate via `AskUserQuestion`. Never invent.

---

## Current phase

**Build — Day 1.** See `/plan/status.md` for live state, last commit, open blockers, and next action.
