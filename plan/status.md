# AdKan — Live Status

**Updated:** 2026-05-10 (Social competition system — Phase 1 implementation complete).

---

## Current phase

**Build — active development. Social competition Phase 1 landed on `feature/leaderboard-redesign`.**

Phase 1 social competition system implemented: profile system, leaderboard redesign with podium, league badges, streak sync, group owner management, weekly leaderboard RPC, localization fixes. Ready for Supabase migration and TestFlight validation.

---

## Social Competition — Phase 1 Implementation Status

### Completed (this branch)
- [x] Schema migration (`supabase/migration_002_social.sql`) — profile, streak, league badge columns + RPCs
- [x] Profile system (`ProfileSetupView.swift`) — name + curated emoji avatar, onboarding + settings integration
- [x] Leaderboard redesign (`LeaderboardView.swift` + `PodiumView.swift`) — podium top-3, daily/weekly toggle, current-user highlight
- [x] League badges (`LeagueBadge.swift`) — 🥉→🥈→🥇→💎→👑 based on weekly performance
- [x] Weekly leaderboard RPC — replaces 7-parallel-call pattern with single `weekly_leaderboard_for`
- [x] Group owner management — leave group, ownership transfer, leave confirmation
- [x] Streak + badge fields added to `GroupMember`, `LeaderboardEntry`, service layer
- [x] Home screen leaderboard preview card (replaces `FavoriteGroupCard`)
- [x] Localization — 18 new HE+EN keys for profile, leaderboard, groups
- [x] Deleted replaced files: `FavoriteGroupCard.swift`, `WeeklyLeaderboardCard.swift`

### Phase 2 (next branch)
- [ ] Rank-change push notifications (APNs + Edge Function)
- [ ] Friday recap view + IG Story share
- [ ] Morning nudge local notifications
- [ ] Rivalry indicators (⚡ between close competitors)
- [ ] Viral unlock backend (invite 3 friends = trial)

---

## Next action

1. Run Supabase migration (`migration_002_social.sql`) against EU Frankfurt project
2. Build + verify on simulator (stubs cover all new service methods)
3. TestFlight build once Developer Program approval completes

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

- 2026-04-25T14:07:11.371Z orchestrator — (no subject) — ? files — ok
- 2026-04-25T07:05:11.965Z orchestrator — (no subject) — ? files — ok
- 2026-04-25T06:54:41.691Z orchestrator — (no subject) — ? files — ok
- 2026-04-25T06:39:40.500Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T21:58:23.662Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T21:51:53.085Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T21:43:58.700Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T21:34:09.233Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T21:27:08.394Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T17:14:34.561Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T17:09:59.805Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T08:51:54.148Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T08:45:05.683Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T08:13:25.661Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T08:03:51.709Z orchestrator — (no subject) — ? files — ok
- 2026-04-24T07:59:35.266Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T19:02:27.241Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T18:55:02.277Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T18:07:36.007Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T18:02:17.574Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T18:01:36.926Z orchestrator — (no subject) — ? files — ok
- 2026-04-22T18:00:30.988Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T13:29:38.033Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T13:24:29.317Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T13:24:24.312Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T13:22:33.227Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T11:02:50.606Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T10:35:24.106Z orchestrator — (no subject) — ? files — ok
- 2026-04-21T09:00:23.625Z orchestrator — (no subject) — ? files — ok
- 2026-04-20T20:30:06.686Z orchestrator — (no subject) — ? files — ok
- 2026-04-20T20:01:15.094Z orchestrator — (no subject) — ? files — ok
- 2026-04-20T19:23:11.342Z orchestrator — (no subject) — ? files — ok
- 2026-04-20T14:32:21.800Z orchestrator — (no subject) — ? files — ok
- 2026-04-19T08:23:46.521Z orchestrator — (no subject) — ? files — ok
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

- 2026-05-04T09:08:36.939Z orchestrator — (no subject) — ? files — ok
- 2026-05-04T08:57:06.069Z orchestrator — (no subject) — ? files — ok
- 2026-05-04T08:42:08.787Z orchestrator — (no subject) — ? files — ok
- 2026-05-04T08:23:11.002Z orchestrator — (no subject) — ? files — ok
- 2026-05-04T08:11:25.186Z orchestrator — (no subject) — ? files — ok
- 2026-05-03T14:53:33.471Z orchestrator — (no subject) — ? files — ok
- 2026-05-03T09:40:52.025Z orchestrator — (no subject) — ? files — ok
- 2026-05-03T07:11:17.276Z orchestrator — (no subject) — ? files — ok
- 2026-05-03T06:46:05.578Z orchestrator — (no subject) — ? files — ok
- 2026-05-03T06:42:40.743Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T19:56:53.470Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T19:15:37.008Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T18:56:55.713Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T18:56:11.223Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T18:49:42.261Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T18:33:24.554Z orchestrator — (no subject) — ? files — ok
- 2026-05-02T13:49:10.018Z orchestrator — (no subject) — ? files — ok
- 2026-05-01T15:34:13.191Z orchestrator — (no subject) — ? files — ok
- 2026-05-01T15:32:28.388Z orchestrator — (no subject) — ? files — ok
- 2026-05-01T15:32:26.019Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:25:41.299Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:19:50.623Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:19:44.155Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:18:56.832Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:06:28.507Z orchestrator — (no subject) — ? files — ok
- 2026-04-29T18:02:01.226Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T20:30:42.833Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T20:26:51.563Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T20:24:27.488Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T19:33:51.471Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T19:30:00.739Z orchestrator — (no subject) — ? files — ok
- 2026-04-26T14:22:47.231Z orchestrator — (no subject) — ? files — ok

- 2026-05-06T12:31:13.336Z orchestrator — (no subject) — ? files — ok
- 2026-05-06T09:02:19.531Z orchestrator — (no subject) — ? files — ok
- 2026-05-06T08:51:01.357Z orchestrator — (no subject) — ? files — ok
- 2026-05-06T07:35:10.504Z orchestrator — (no subject) — ? files — ok
- 2026-05-05T20:51:41.795Z orchestrator — (no subject) — ? files — ok
- 2026-05-05T20:36:53.403Z orchestrator — (no subject) — ? files — ok
- 2026-05-05T20:33:45.280Z orchestrator — (no subject) — ? files — ok
- 2026-05-05T20:23:04.655Z orchestrator — (no subject) — ? files — ok
- 2026-05-05T20:20:22.489Z orchestrator — (no subject) — ? files — ok

- 2026-05-10T08:04:51.957Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:54:23.195Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:29:22.786Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:24:44.834Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:20:27.115Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:20:23.189Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T07:07:29.584Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:48:58.135Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:45:54.995Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:32:55.446Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:27:34.736Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:19:10.193Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:15:32.334Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:14:07.262Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:07:21.954Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T20:01:30.818Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:55:51.928Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:47:01.715Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:31:27.947Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:29:36.306Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:28:44.654Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:23:11.192Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:19:17.073Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:18:11.582Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:17:52.990Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:10:22.259Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:07:20.855Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T19:06:00.706Z orchestrator — (no subject) — ? files — ok
- 2026-05-09T18:58:32.339Z orchestrator — (no subject) — ? files — ok

- 2026-05-10T13:02:20.969Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T12:34:22.841Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T12:33:52.220Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T12:07:18.784Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T09:24:58.660Z orchestrator — (no subject) — ? files — ok

- 2026-05-14T18:54:06.514Z orchestrator — (no subject) — ? files — ok
- 2026-05-14T18:29:12.760Z orchestrator — (no subject) — ? files — ok
- 2026-05-14T17:54:20.737Z orchestrator — (no subject) — ? files — ok
- 2026-05-14T17:48:41.038Z orchestrator — (no subject) — ? files — ok
- 2026-05-14T17:48:01.824Z orchestrator — (no subject) — ? files — ok
- 2026-05-14T17:46:53.600Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T12:23:58.918Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T12:19:12.873Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T12:18:25.406Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T12:17:51.314Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T12:17:44.177Z orchestrator — (no subject) — ? files — ok
- 2026-05-11T11:28:21.141Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:26:01.823Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:24:25.792Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:18:53.458Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:15:52.969Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:09:04.588Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:06:04.558Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:04:41.346Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:01:39.540Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T19:00:35.375Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:58:40.355Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:58:34.539Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:57:21.079Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:54:36.795Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:48:49.724Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:40:34.939Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:21:27.528Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:17:56.912Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:15:42.024Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T18:03:03.095Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T17:49:27.246Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T17:37:32.482Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T14:50:53.393Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T14:46:07.838Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T14:45:40.946Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T14:44:41.605Z orchestrator — (no subject) — ? files — ok
- 2026-05-10T14:44:38.049Z orchestrator — (no subject) — ? files — ok
