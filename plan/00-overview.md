# Plan 00 — Overview

This file is the in-repo entry point for the 7-day Build phase. It restates the spine decisions for any agent arriving fresh and maps the rest of `/plan/`.

**Source of truth for founder decisions:** `CLAUDE.md`.
**Source of truth for master plan:** `C:/Users/Tal/.claude/plans/you-are-the-founding-iterative-peach.md`.

---

## The 9 rules (recap)

1. **Plan-mode gating** — governance files (`/plan`, `/specs`, `/prd`, `/adr`, `/research`) only during plan mode. Other writes require an approved plan.
2. **Secrets are radioactive** — never read/write/echo/commit `.env*` (except `.env.example`), `*.p8`, `*.p12`, `*.pem`, `AuthKey_*`, SSH private keys, `SUPABASE_SERVICE_ROLE_KEY`, `sk-*`, `pk-*`, long `eyJ*`.
3. **Deny-listed paths** — never touch: `.env.local`, `~/.ssh/`, `~/Keys/` (and Windows equivalents), `.git/` (except reading `HEAD`), `node_modules/`, `Pods/`, `DerivedData/`.
4. **Template `${APP_NAME}` / `${APP_NAME_HE}`** — source of truth is `config/app-identity.json`.
5. **TDD** — `qa-engineer` writes the failing test first, then implementation.
6. **Hebrew + English parity** — no machine translation, `localization-lead` vetoes copy PRs.
7. **Escalation over invention** — ambiguous → ask the founder.
8. **`[SKILL-DECL]` before any code Write/Edit** — every agent declares which skill/doc it consulted.
9. **SSH is privileged** — only `ios-engineer`, `qa-engineer`, `release-engineer` may SSH. Config in `config/mac-bridge.json`.

---

## Locked decisions (re-read from `CLAUDE.md`)

- **App name:** AdKan / עד כאן
- **Bundle ID:** `com.taltalhayun.adkan`
- **Deployment target:** iOS 16.0+
- **Auth:** Apple Sign-In only
- **Dev account:** Individual (tal20100)
- **No physical iPhone** — validation via TestFlight external testers
- **Mac deferred** — Xcode Cloud is primary CI
- **MVP = TestFlight-quality** — App Store submission is a later milestone
- **Privacy boundary:** only `dailyTotalMinutes: Int` crosses network (see `adr/0004`)
- **Pricing:** ₪12.90/mo (3-day trial), ₪69/yr (3-day trial), ₪99 lifetime hero (no trial). No weekly, ever.

---

## The 15-agent team (recap)

| Agent | Role |
|---|---|
| product-strategist | PRDs, feature scope, positioning |
| ux-designer | SwiftUI layouts, Hebrew-first + RTL |
| architecture-auditor | module boundaries, SPM graph, drift detection |
| ios-engineer | Swift, SwiftUI, FamilyControls (SSH-allowed) |
| backend-engineer | Supabase schema, Edge Functions |
| payments-engineer | StoreKit 2, paywall, receipts |
| social-graph-engineer | friends, groups, leaderboard, realtime |
| qa-engineer | TDD, XCTest + XCUITest (SSH-allowed) |
| security-reviewer | VETO — secret scans, threat model, OWASP |
| privacy-engineer | VETO — data-leaves-device policy, permissions UX |
| app-store-reviewer | Guideline compliance, rejection-risk scan |
| growth-analytics-engineer | PostHog funnels, event taxonomy |
| social-virality-designer | viral unlock UX, IG-Story recap, invite copy |
| release-engineer | Xcode Cloud, TestFlight, signing (SSH-allowed) |
| localization-lead | VETO — HE+EN parity, RTL correctness |

Full definitions in `.claude/agents/*.md` (written by Batch 10).

---

## The 32-file map

### Root (1)
- `/CLAUDE.md` — session context (written Batch 1)

### `/research/` (3)
- `brainrot-unrot-learnings.md`, `competitors-landscape.md`, `windows-mac-workflow-verified.md` (Batch 2)

### `/prd/` (4)
- `0001-onboarding-survey.md`, `0002-leaderboard-core.md`, `0003-monetization-and-paywall.md`, `0004-privacy-and-permissions.md` (Batch 3)

### `/specs/` (4)
- `0001-onboarding-survey.md`, `0002-leaderboard-core.md`, `0003-monetization-and-paywall.md`, `0004-privacy-and-permissions.md` (Batch 4)

### `/adr/` (7)
- `0001-state-management.md`, `0002-local-storage.md`, `0003-push-notifications.md`, `0004-data-leaves-device-policy.md` (Batch 5)
- `0005-screentime-provider-abstraction.md`, `0006-distribution-and-account.md`, `0007-windows-to-mac-workflow.md` (Batch 6)

### `/plan/` (13)
- `00-overview.md` (this file), `01-agent-definitions.md`, `02-infrastructure-setup.md`, `03-skills-installation.md` (Batch 7)
- `04-hooks-and-automation.md`, `05-ios-architecture.md`, `06-backend-architecture.md`, `07-localization-strategy.md` (Batch 8)
- `08-testing-strategy.md`, `09-seven-day-execution.md`, `10-go-to-market-lite.md`, `11-governance-and-hooks.md`, `status.md` (Batch 9)

Plus `scripts/hello-mac.mjs` (Batch 6), `.claude/agents/*.md` (Batch 10), `.claude/settings.json` (Batch 11).

---

## Daily cadence

**Morning:** orchestrator re-reads `plan/status.md` → plans the day's first-5 files → posts a status summary → awaits founder `continue`.
**Mid-day:** write 4–5 files, run hook checks, then pause for another status summary + `continue`.
**Afternoon:** same cadence — 4–5 files, pause, summary.
**End of day:** demo artifact (screenshot, test output, or TestFlight link), update `status.md`, commit + push.

The pause-every-4-5-files rule is absolute. Any agent that writes 6+ files without pausing is violating governance.

---

## Escalation policy

- **Technical ambiguity** (which library, which pattern) → resolve internally, document in ADR if non-obvious.
- **Product ambiguity** (feature scope, pricing, copy) → `AskUserQuestion` to founder.
- **Security ambiguity** (secret handling, data exposure) → `security-reviewer` decides; may veto.
- **Privacy ambiguity** (what crosses network) → `privacy-engineer` decides; may veto.
- **Copy ambiguity** (Hebrew phrasing, RTL correctness) → `localization-lead` decides; may veto.
- **Schedule ambiguity** (what gets cut for v1) → `AskUserQuestion` to founder.

VETO means a single agent can block a merge unilaterally. VETO reason is logged in `plan/status.md`.

---

## Kill-gates (recap)

1. **No physical iPhone** → ScreenTimeProvider stub + TestFlight external testers.
2. **FamilyControls entitlement delay** → build against stubs; flip when approval arrives.
3. **Mac offline** → Xcode Cloud covers shipping path.

Full analysis in master plan §5 and `adr/0007`.

---

## First-hour orientation for any incoming agent

1. Read `CLAUDE.md`.
2. Read this file.
3. Read the specific PRD / spec / ADR your task references.
4. If implementing a feature: read `research/brainrot-unrot-learnings.md` + `research/competitors-landscape.md` first.
5. Before any Write/Edit: print `[SKILL-DECL] <skill or doc reference>`.
6. Unclear? `AskUserQuestion` or comment in `plan/status.md` as `[FOUNDER-ACTION]`.
