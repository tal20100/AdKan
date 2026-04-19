# PRD 0002 — Leaderboard Core

**Owner:** product-strategist + social-graph-engineer. **Reviewers:** ux-designer, privacy-engineer, growth-analytics-engineer.

## Problem

The leaderboard is the product. Brainrot, Unrot, Opal, ScreenZen, Clearspace all make self-tracking primary and social secondary (or absent). AdKan inverts that: when you open the app, the first thing you see is your rank among friends. Every retention mechanic flows from that.

## Core loop (locked)

```
Open app
   ↓
See rank among friends (realtime)
   ↓
Get push on rank change (gained a spot / lost a spot)
   ↓
Open Friday recap
   ↓
Share recap as IG Story (optional)
   ↓
Invite 3rd friend → unlocks trial Premium
```

Every surface binds to this loop. Anything that doesn't — cut it.

## Home screen layout

```
┌─────────────────────────────────────┐
│  [Top Enemy card — from Q3]         │
│  "TikTok stole 1h 23m today"        │
├─────────────────────────────────────┤
│  [Avatar — from Q1]                 │
│  [Today: 2h 41m / goal 3h]          │
│  [Progress bar]                     │
├─────────────────────────────────────┤
│  👑  Tal      1h 02m    ↑1          │
│  2   Rona     1h 47m    —           │
│  3   Itay     2h 19m    ↓1          │
│  4   You      2h 41m    —           │
├─────────────────────────────────────┤
│  [Invite friend] [Recap] [Settings] │
└─────────────────────────────────────┘
```

Only 3 primary tabs — Home, Recap, Settings. No clutter. Home is the leaderboard.

## Avatar state machine

Avatar reflects how the user's current week is going relative to their Q5 goal.
- `streak_winning` — daily total below goal for 3+ consecutive days.
- `on_track` — daily total below goal today.
- `neutral` — daily total equals goal ± 15 min.
- `slipping` — daily total above goal today.
- `spiraling` — daily total above goal for 3+ consecutive days.

State transitions are animated. `streak_winning → spiraling` in one day should feel dramatic (visual jolt, haptic).

## Push on rank change

Trigger: any rank change in a group containing the user, calculated by Supabase Edge Function `calculate-rank-changes` running every 15 minutes.

Push copy (locked):
- Gained a spot:
  - HE: `עלית למקום {rank}. {friend} בפסיכוזה.`
  - EN: `You moved to #{rank}. {friend} is losing it.`
- Lost a spot:
  - HE: `{friend} עקף אותך. חרפה.`
  - EN: `{friend} passed you. Rough.`
- #1 reached:
  - HE: `אתה #1 היום. 👑`
  - EN: `You're #1 today. 👑`

Israeli humor. Never condescending. Never guilt-driven. Brainrot and Unrot both lean on shame — we don't.

Frequency cap: maximum 3 push notifications per user per day. Anti-spam.

## Friday recap

Delivered at 18:00 Israel time on Friday (matches IL pre-Shabbat wind-down — social-virality-designer to confirm in `/plan/10-go-to-market-lite.md`).

Content:
- Weekly total vs. Q5 goal.
- Rank movement across the week.
- "Won back" framing — minutes reclaimed vs. last week.
- Avatar montage — Monday state → Friday state.
- One-tap IG Story share with pre-rendered image (1080×1920, HE-first with EN fallback).

Premium recap adds: per-day breakdown, vs-each-friend head-to-head, streak count, and a weekly challenge outcome summary.

## Free tier

- Track daily screen time (via FamilyControls / `ScreenTimeProvider`).
- Leaderboard with **≤3 friends** in one group.
- Basic Friday recap (weekly total + rank + one avatar).
- Avatar state machine.
- 3-push/day limit.

## Premium tier

Unlocked by any of the three products in `/prd/0003-monetization-and-paywall.md`. Adds:
- **Up to 15 friends** in a group.
- Multiple groups (friends, roommates, partner, coworkers — one per Q4 template).
- Weekly challenges (shared-enemy theme from Q3 overlaps).
- App-blocking via ManagedSettings (requires FamilyControls entitlement).
- Streaks with visual progression.
- Enhanced recap (per-day breakdown, head-to-heads).

## Paywall trigger (reminder)

Per PRD 0003 — the single non-pricing paywall trigger is adding a 4th friend to a group. Copy:
- HE: `הקבוצה שלך מלאה. שדרג כדי להזמין עד 15 חברים.`
- EN: `Your group is full. Upgrade to invite up to 15 friends.`

No pre-feature paywalls. No forced-video-demo paywalls. No exit-discount tactics.

## Viral unlock

When a user invites 3 friends who actually install AdKan (measured by the install-attribution event from Supabase), the user unlocks a **7-day Premium trial** with a group size bumped to 10.

Copy (trial screen):
- HE: `3 חברים הצטרפו. זכית ב-7 ימי פרימיום וקבוצה של 10.`
- EN: `3 friends joined. You've unlocked 7 days of Premium and a group of 10.`

Countdown visible in the home screen top bar during the trial. On Day 6, a soft paywall appears explaining continued value at ₪12.90/mo / ₪69/yr / ₪99 lifetime.

## Data that crosses the network (privacy boundary reminder)

Per `/adr/0004-data-leaves-device-policy.md`:
- `userId: UUID` (Supabase anonymous)
- `date: ISO8601`
- `dailyTotalMinutes: Int`

Nothing else. Ever. The leaderboard query returns these fields for the user and the user's confirmed friends, nothing more.

## Analytics events (PostHog)

- `home_opened`, `home_rank_changed`, `invite_sent`, `invite_accepted`
- `viral_unlock_achieved` (3-friend trial triggered)
- `recap_viewed`, `recap_shared_ig`
- `paywall_shown_reason` (value: `fourth_friend` | `settings_upgrade` | `trial_expired`)

No PII. No per-friend identifiers in events — only anonymous counts.

## Out of scope for v1

- In-app chat between friends.
- Video reactions to rank changes.
- Spectator mode (watching someone else's rank without reciprocity).
- Global leaderboard.
- Group-vs-group tournaments.
