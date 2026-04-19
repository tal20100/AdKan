# AdKan — Live Status

**Updated:** 2026-04-19 (end of Day 0 — Plan lock complete; Build phase scaffold authored).

---

## Current phase

**Day 0 complete. Day 1 pending founder `approved, begin execution`.**

Plan lock delivered: all 32 governance files authored in the repo (this file + the rest of `/plan`, plus `/CLAUDE.md`, `/research/*`, `/prd/*`, `/specs/*`, `/adr/*`, `/scripts/hello-mac.mjs`). Agent definitions + settings.json wiring remain as Batches 10 + 11, executed during Day 1.

---

## Last commit

**none yet** — initial commit happens at the start of Day 1 (Batch 11 finalization).

---

## Active blockers

None blocking Day 1 start. Two open items are *ambient* but do not block code Day 1:

- **Apple Developer Program enrollment** in flight (founder-action #1). Day 1 work is governance + scaffold, not device-dependent.
- **FamilyControls entitlement** to be submitted Day 1 morning (founder-action #3). 1–30 day wildcard; we build against stubs regardless per ADR 0005.

---

## Next action

1. Founder types `approved, begin execution`.
2. Orchestrator runs Day-1 first-three commands from master plan §7:
   - Plugin installs (frontend-design, owasp)
   - Commit the 32-file scaffold + verify hooks
   - `node scripts/hello-mac.mjs` smoke test → OFFLINE banner + exit 0.

---

## Founder actions outstanding

From `/plan/02-infrastructure-setup.md`:

- [ ] #1 Apple Developer Program enrollment
- [ ] #2 Register bundle ID `com.taltalhayun.adkan`
- [ ] #3 Submit FamilyControls entitlement
- [ ] #4 Supabase project (EU Frankfurt)
- [ ] #5 PostHog (EU)
- [ ] #6 Sentry (EU region)
- [ ] #7 Apple Sign-In service + `.p8`
- [ ] #8 APNs `.p8` AuthKey
- [ ] #9 Supabase secrets upload
- [ ] #10 App Store Connect app record
- [ ] #11 Recruit 3–5 IL TestFlight testers
- [ ] #12 Mac bridge (optional, anytime)

---

## Skills loaded

- [ ] `frontend-design@anthropics-claude-code` — needed Day 2
- [ ] `owasp@claude-code-owasp` — needed first security review

---

## Turn log (last 20)

_(auto-appended by `subagent-stop-status-update.mjs` once the hook is wired in Batch 11)_

- 2026-04-18 orchestrator — Batch 1 root scaffold — 4 files — ok
- 2026-04-18 orchestrator — Batch 2 research — 3 files — ok
- 2026-04-18 orchestrator — Batch 3 PRDs — 4 files — ok
- 2026-04-18 orchestrator — Batch 4 specs — 4 files — ok
- 2026-04-18 orchestrator — Batch 5 ADRs 0001-0004 — 4 files — ok
- 2026-04-19 orchestrator — Batch 6 ADRs 0005-0007 + hello-mac.mjs — 4 files — ok
- 2026-04-19 orchestrator — Batch 7 plan/00-03 — 4 files — ok
- 2026-04-19 orchestrator — Batch 8 plan/04-07 — 4 files — ok
- 2026-04-19 orchestrator — Batch 9 plan/08-11 + status.md — 5 files — ok

---

## Drift checks

- _(none yet — first drift check end-of-Day-3)_

---

## Vetoes this week

- _(none)_

---

## FOUNDER-ACTIONS surfaced since last review

- None new. See checklist above.

---

## Open questions (from master plan §10)

1. Bundle ID `com.taltalhayun.adkan` — OK to use, or do you own a domain you'd prefer?
2. App Store listing Hebrew description + keywords — `product-strategist` + `localization-lead` to draft; founder approves.
3. Pre-launch Hebrew landing page — out-of-scope for Build; confirm Day 7+ follow-up is fine.
4. 3–5 TestFlight testers — already lined up, or recruit during Day 5-6?
5. Brand visuals (avatar art, color palette, icon) — `ux-designer` drafts ASCII placeholders Day 2; real artwork is founder-action.
6. Master plan lists 32 files; founder v4 prompt said 29. Math discrepancy noted; 32 is the actual count. OK to keep, or prefer to merge any?
