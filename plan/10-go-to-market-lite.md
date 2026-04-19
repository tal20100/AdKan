# Plan 10 — Go-to-Market Lite

MVP-scope only. Heavy marketing is out-of-scope for Build; this file captures what ships inside the app + the pre-launch Hebrew one-pager landing page as a founder-action.

---

## The core viral loop (lifted from `/prd/0002`)

1. User opens AdKan in the morning.
2. Sees their rank on the 3-friend leaderboard.
3. Rank change → APNs push → lures return to app.
4. Friday 18:00 IL → weekly recap screen → IG-Story share card tempts tap.
5. Empty leaderboard prompts "Invite a friend" CTA.
6. Friend invites → deep-link → onboarding → new row → viral growth.

---

## Invite copy per group template

The user picked one of 4 templates in onboarding Q4. Invite copy mirrors that template, in both HE and EN. `localization-lead` has final say; founder drafts below.

### Template `friends` — default, close social circle
- **HE:** `היי, הורדתי אפליקציה שעוזרת להפחית זמן מסך עם חברים - מצטרף/ת? זה עד כאן: <link>`
- **EN:** `Hey — downloaded this app for cutting screen time with friends. Join me? It's AdKan: <link>`

### Template `roommates` — shared living
- **HE:** `אולי נעשה פחות סקרולינג בערבים? אפליקציה של לוח דירוג בין חברים לדירה: <link>`
- **EN:** `Less doomscrolling at night? Roommate leaderboard app: <link>`

### Template `partner` — couple
- **HE:** `נסיון לצאת פחות מהמסך יחד, בא לך? <link>`
- **EN:** `Trying less screens together — wanna? <link>`

### Template `coworkers` — office
- **HE:** `מישהו/י רוצה תחרות ידידותית על זמן מסך במשרד? <link>`
- **EN:** `Anyone up for a friendly office screen-time competition? <link>`

All invite links go to `https://adkan.link/i/<code>` — a Supabase Edge Function that deep-links back to the App Store (if app not installed) or into the app's onboarding (if installed, via Universal Links). Founder-action to register the `adkan.link` domain or substitute with a subdomain of a domain the founder already owns. If no domain available: fall back to `https://<supabase-project>.supabase.co/i/<code>` — uglier but works.

---

## Friday recap + IG-Story share

### Recap copy

**HE:**
> השבוע שלך:
> ‎**{total_hours}** שעות על המסך (יום הכי גרוע: {worst_day_name}).
> דירוג בין חברים: {rank} מתוך {total}.
> שינוי מהשבוע שעבר: {delta_sign}{delta_hours}ש.
> המשך/י גם בשבוע הבא.

**EN:**
> Your week:
> **{total_hours}** hours on screen (worst day: {worst_day_name}).
> Rank: {rank} of {total}.
> Change vs last week: {delta_sign}{delta_hours}h.
> Keep it up.

### IG-Story share card

Square 1080×1920 PNG (Instagram Story aspect) generated on-device using `SwiftUI.ImageRenderer`. Layout:
- Top: AdKan logo + `עד כאן` wordmark.
- Middle: large digit "{total_hours}h" + "השבוע הזה" / "this week".
- Lower: mini 7-dot bar chart, one dot per day, colored by fixture state.
- Bottom: `@adkan.app` + `adkan.link` + invite_code personal to user.

No user PII on the card. No friend names. No per-app breakdown. Just the user's own aggregate.

Share uses `UIActivityViewController` with `source_app` metadata set to Instagram Stories if available (iOS 14+ API for pre-filling `com.instagram.sharedSticker.stickerImage` pasteboard). Fallback: generic share sheet.

---

## Viral unlock (3 friends → +7-day trial)

From `/prd/0002 §viral-unlock`:

When the user's invite_codes.redeemed_by count ≥ 3:
1. `viral-unlock-check` Edge Function grants an `entitlements` row with `kind = 'trial'`, `expires_at = now + 7 days`, `original_txn_id = 'viral-<user_id>-<timestamp>'`.
2. Client receives push: **HE** `הכנסת 3 חברים - 7 ימים של עד כאן Premium במתנה.` **EN** `You invited 3 friends — 7 days of AdKan Premium on the house.`
3. Deep-link to paywall screen showing "Trial active, 7 days remaining" state, with upsell to keep Premium after.

After 7 days, trial entitlement expires; user falls back to free tier. No exit discount (per `/prd/0003`).

---

## Pre-launch Hebrew one-pager (founder-action)

**Out of scope for Build** — founder creates separately. Recommended structure:

**Header:** AdKan / עד כאן. "הרשת החברתית להורדת זמן מסך."
**Above the fold:** single CTA "הצטרפו לרשימת הממתינים" / "Join waitlist" — email capture via Formspree/Fillout/similar (no backend needed). Or wait for TestFlight.
**Screenshot carousel:** 3–4 shots from Xcode Cloud's TestFlight build.
**Testimonials:** none at launch. Don't fabricate.
**Pricing teaser:** "חודשי / שנתי / Lifetime - ₪12.90 / ₪69 / ₪99."
**Privacy statement:** "הנתונים שלך נשארים בטלפון. רק מספר אחד יומי נשלח." (from `/adr/0004`).
**Footer:** bundle ID, founder name (individual account), IL tax info minimum required by law.

Hosting options (pick one):
- **Vercel** — free, deploy a single Next.js page or even plain HTML.
- **Netlify** — free, drag-and-drop zip.
- **GitHub Pages** — free, uses repo subfolder `/landing-page/`.
- **Cloudflare Pages** — free, unlimited bandwidth.

Recommendation: Cloudflare Pages for the bandwidth cap; register domain via Cloudflare for clean DNS + SSL.

---

## Launch channels (MVP = TestFlight)

For TestFlight-only MVP, founder's launch is:
1. **Direct messages** to 3–5 Israeli friends (the testers). No Twitter. No Product Hunt yet.
2. **One short update** in any Israeli software/founders group the founder is already in (Facebook / Slack / Discord). Hebrew text, casual tone, NOT promotional blast.

App Store public launch is **not** part of this plan — it's a separate post-MVP milestone with its own launch-marketing plan.

---

## Growth metrics to track from Day 1

PostHog funnel events (locked names in `App/Analytics/EventCatalog.swift`):

| Event | Triggered when |
|---|---|
| `install_first_launch` | App first launch after install |
| `onboarding_q1_answered` | Q1 survey complete |
| `onboarding_q2_answered` | Q2 survey complete |
| `onboarding_q3_answered` | Q3 survey complete |
| `onboarding_q4_answered` | Q4 survey complete |
| `onboarding_q5_answered` | Q5 survey complete |
| `permission_prompt_shown` | Pre-prompt sheet displayed |
| `permission_granted` | System dialog approved |
| `permission_skipped` | User chose manual-entry |
| `signin_apple_success` | Apple Sign-In returned valid token |
| `first_leaderboard_view` | Leaderboard first rendered with self |
| `invite_sent` | Invite link copied/shared |
| `invite_redeemed_received` | User received a friend-accept |
| `paywall_shown` | Paywall presented (reason: 4th_friend \| settings \| push_cta) |
| `subscription_started` | StoreKit 2 purchase success (sandbox or prod) |
| `subscription_cancelled` | Refund / expire / grace-end |
| `rank_change_push_received` | UNUserNotificationCenter delivered push |
| `rank_change_push_opened` | User tapped push |
| `friday_recap_viewed` | Recap screen shown |
| `friday_recap_shared` | Share sheet completed |
| `viral_unlock_triggered` | 3rd friend redeemed invite |

Payload constraint (from `privacy-engineer`): event names only. Optional low-cardinality properties: `locale`, `app_version`, `os_version`, `entitlement_kind`. **Never:** Hebrew text, friend names, per-app usage, raw minute counts, Apple ID, IDFA/IDFV, IP (PostHog auto-strips).

---

## Iteration plan (post-MVP)

Not in Build scope — captured here so founder sees the roadmap:

**v1.1 (2-3 weeks post-MVP):** Friday-recap email, DeviceActivityReport extension, multi-group UI, manual-entry mode polish.

**v1.2 (4-6 weeks):** Streaks, challenges (Premium), app-blocking via `ShieldConfiguration` (Premium).

**v1.3 (+2 months):** App Store public submission after TestFlight beta data validates the retention hypothesis. Marketing site beyond the waitlist one-pager.

**v2.0 (+4 months):** Android (maybe). Revisit per actual signal.
