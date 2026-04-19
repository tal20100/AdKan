# Plan 02 — Infrastructure Setup (founder-action checklist)

All items in this file are **founder-actions** — things Claude cannot do on its own because they require typing passwords, clicking buttons in external web consoles, or physically touching a machine.

Each section has: **why**, **when**, **exact steps**, **what to paste back** (usually into `.env.local`).

`.env.local` is gitignored and never enters the repo. Treat it like a password file.

---

## §apple-developer-program — ENROLL FIRST

**Why:** without this, nothing ships. It gates the bundle ID, the entitlement, TestFlight, App Store Connect, Xcode Cloud.
**When:** Day 1 morning. Blocker on everything.
**Cost:** $99 USD/yr (~₪360).
**ETA:** hours to 2 business days (identity verification).

1. Go to https://developer.apple.com/programs/enroll/.
2. Sign in with your personal Apple ID (the one you use on your iPhone eventually).
3. Choose **Individual / Sole Proprietor**. NOT Organization. NOT Company.
4. Confirm name and address match government ID.
5. Pay $99 via Apple ID payment method.
6. Wait for the "Welcome to the Apple Developer Program" email. This may arrive in minutes or take up to 2 business days.
7. When it arrives, sign in to https://developer.apple.com/account/ and confirm access.
8. Note your **Team ID** (10-char alphanumeric, top-right of the membership page). Paste into `.env.local`:
   ```
   APNS_TEAM_ID=<YOUR_TEAM_ID>
   ```

---

## §bundle-id — register `com.taltalhayun.adkan`

**Why:** bundle ID must exist before entitlement request, before Xcode Cloud, before App Store Connect.
**When:** immediately after Apple Developer Program activates.
**ETA:** 2 minutes.

1. https://developer.apple.com/account/resources/identifiers/list → "+" → App IDs → App → Continue.
2. Description: `AdKan Production`.
3. Bundle ID: **Explicit** = `com.taltalhayun.adkan`.
4. Capabilities: tick these:
   - **Sign in with Apple**
   - **Push Notifications**
   - **App Groups** (click "Edit" → "+" → Identifier: `group.com.taltalhayun.adkan` → Description: `AdKan Shared Group`)
   - **Family Controls** (grayed out if entitlement not yet approved — tick is harmless; request in §family-controls below)
5. Continue → Register.

---

## §family-controls — the long-lead entitlement

**Why:** `FamilyControls` / `DeviceActivity` / `ManagedSettings` all require Apple approval beyond the base entitlement. 1–30+ day wildcard.
**When:** Day 1, immediately after §bundle-id. Start the clock ASAP.
**ETA:** 1–30 days. Plan accordingly. Code against `StubScreenTimeProvider` in the meantime.

1. https://developer.apple.com/contact/request/family-controls-distribution
2. Sign in with your Developer Program account.
3. Fill the form. Suggested wording (paste and adapt):

> **App name:** AdKan (עד כאן)
> **Bundle ID:** com.taltalhayun.adkan
> **Description:** AdKan helps users voluntarily reduce their phone screen time through a friendly social leaderboard with 3–10 invited friends. The FamilyControls / DeviceActivity / ManagedSettings frameworks are used to let users opt-in to accurate daily-total screen-time tracking, which feeds a simple `dailyTotalMinutes` count to the leaderboard (no per-app data leaves the device). The ManagedSettings shield capability is used only for the user's own opt-in app-blocking during self-declared focus sessions. No data is collected or transmitted beyond the single daily-total integer.
> **Territories:** Israel primary, worldwide distribution.
> **Users:** adults (17+) who self-enroll; no child accounts, no parental-control usage.

4. Submit. Note the ticket reference in `plan/status.md`.
5. Check email daily. If silence > 14 days, reply to the auto-acknowledgement asking for an ETA.

---

## §apns-p8 — APNs AuthKey

**Why:** direct APNs HTTP/2 (ADR 0003) requires a `.p8` key.
**When:** Day 4, before implementing push.
**ETA:** 5 minutes.

1. https://developer.apple.com/account/resources/authkeys/list → "+".
2. Key Name: `AdKan APNs Production`.
3. Tick **Apple Push Notifications service (APNs)**. Continue → Register.
4. Download the `.p8` file. **This is your only chance.** Apple does NOT let you re-download.
5. Save to `C:\Users\Tal\Keys\AuthKey_<KEYID>.p8`. DO NOT put this in the repo. DO NOT email it.
6. Note the **Key ID** (10-char alphanumeric, shown on the page after creation).
7. Paste into `.env.local` (server-side, never client) for reference ONLY — the real value goes to Supabase secrets in §supabase-secrets:
   ```
   # .env.local — reference only; real value in Supabase secrets
   APNS_KEY_ID=<KEY_ID>
   ```
8. Upload `.p8` contents to Supabase (see §supabase-secrets).

---

## §supabase — signup + project

**Why:** backend foundation. EU Frankfurt region for IL user data residency.
**When:** Day 2 morning.
**Cost:** free tier sufficient for MVP.
**ETA:** 15 minutes.

1. https://supabase.com → Sign up with GitHub.
2. New project:
   - Name: `adkan-production`
   - Database password: generate 32+ chars, save in password manager. DO NOT commit.
   - Region: **West Europe (Frankfurt, eu-central-1)**.
   - Plan: Free.
3. Wait for provision (~2 min).
4. Settings → API → copy:
   - **Project URL** → paste to `.env.local` as `SUPABASE_URL=https://<project-ref>.supabase.co`
   - **anon (public) key** → paste to `.env.local` as `SUPABASE_ANON_KEY=<eyJ...>`
   - **service_role (secret) key** — NEVER paste to `.env.local`. Used only in Edge Functions via secrets.
5. Authentication → Providers → enable **Apple**. Leave client details blank for now (filled in §apple-signin below).

---

## §supabase-secrets — server-side secret upload

**Why:** Edge Functions need APNs `.p8`, key ID, team ID, topic. These live in Supabase secrets, never in the repo.
**When:** Day 4, after §apns-p8.
**ETA:** 10 minutes.

1. In Supabase dashboard → Project Settings → Edge Functions → Secrets (or via `supabase secrets set` CLI).
2. Set:
   ```
   APNS_KEY_ID=<from §apns-p8>
   APNS_TEAM_ID=<from §apple-developer-program>
   APNS_TOPIC=com.taltalhayun.adkan
   APNS_ENVIRONMENT=sandbox     # switch to 'production' at App Store submit time
   APNS_AUTH_KEY_P8_CONTENTS=<paste full .p8 file contents, including BEGIN/END lines>
   APPLE_CLIENT_ID=com.taltalhayun.adkan
   APPLE_SHARED_SECRET=<from App Store Connect → Users and Access → Shared Secrets>   # for validate-receipt
   ```
3. Verify none of these appear in the repo: `git grep -n "APNS_\|APPLE_SHARED"` should return zero hits outside `.env.example` and docs.

---

## §posthog — EU analytics

**Why:** funnel + retention analytics. EU region for IL user data residency.
**When:** Day 2 afternoon.
**Cost:** free tier (1M events/month).
**ETA:** 10 minutes.

1. https://eu.posthog.com → Sign up.
2. Create project `adkan`.
3. Settings → Project → copy:
   - **Project API Key** (starts with `phc_`) → paste to `.env.local` as `POSTHOG_PROJECT_KEY=phc_...`
   - **Host** → `POSTHOG_HOST=https://eu.posthog.com`
4. No server-side secret key needed — all analytics are client-side with the public project key.

---

## §sentry — crash reporting

**Why:** remote eyes on crashes when we don't own a device.
**When:** Day 2 afternoon.
**Cost:** free tier (5k errors/month).
**ETA:** 10 minutes.

1. https://sentry.io → Sign up (choose EU data region at signup).
2. Create organization `adkan`.
3. Create project: platform **Apple** → **iOS**. Name `adkan-ios`.
4. Copy the DSN from the setup screen → paste to `.env.local`:
   ```
   SENTRY_DSN=https://<publicKey>@<subdomain>.ingest.sentry.io/<projectId>
   ```
5. Settings → Auth Tokens → create a token with `project:write` + `org:read` scopes for dSYM upload. Save as `SENTRY_AUTH_TOKEN` in Xcode Cloud environment (NOT in `.env.local`, NOT in repo).

---

## §app-store-connect — app record

**Why:** TestFlight distribution + App Store submission need the app record.
**When:** Day 5, before first TestFlight upload.
**ETA:** 20 minutes.

1. https://appstoreconnect.apple.com → My Apps → "+".
2. Platform: iOS. Name: `AdKan`. Primary language: Hebrew. Bundle ID: `com.taltalhayun.adkan`. SKU: `ADKAN001`.
3. Full access: Individual account = only you.
4. App Information → Primary category: **Health & Fitness**. Secondary: **Lifestyle**.
5. Pricing: set to free + in-app purchases for now; configure real IAPs per `/specs/0003-monetization-and-paywall.md` on Day 6.
6. App Privacy → start the privacy questionnaire. Expected answers driven by ADR 0004 (minimal data collection: anonymous user ID + daily total minutes + email for account recovery only). `privacy-engineer` reviews before submission.

---

## §apple-signin — Apple Sign-In for Supabase

**Why:** auth flow.
**When:** Day 3.
**ETA:** 15 minutes.

1. https://developer.apple.com/account/resources/identifiers/list → "+", choose **Services IDs**.
2. Identifier: `com.taltalhayun.adkan.auth`. Description: `AdKan Apple Sign-In service`. Continue → Register.
3. Open the Services ID you just created → tick **Sign in with Apple** → Configure.
4. Primary App ID: `com.taltalhayun.adkan`.
5. Domains: `<your-supabase-project-ref>.supabase.co`.
6. Return URLs: `https://<your-supabase-project-ref>.supabase.co/auth/v1/callback`.
7. Save.
8. Create a Sign-In Key: Keys → "+" → tick **Sign in with Apple** → Configure → primary App ID as above → Save → Register. Download the `.p8`. Save to `C:\Users\Tal\Keys\AuthKey_<SIGNIN_KEYID>.p8`.
9. In Supabase → Authentication → Providers → Apple → enable and fill:
   - **Client ID (Services ID):** `com.taltalhayun.adkan.auth`
   - **Secret Key (JWT):** generate from Supabase's helper using the `.p8` contents + Key ID + Team ID. (Supabase docs provide a script.)
10. Test the flow via Supabase Auth URL in a browser — should redirect through Apple → back to Supabase callback.

---

## §testflight-testers — recruit 3–5 Israeli testers

**Why:** Tier-2 device-less validation.
**When:** Day 6.
**ETA:** ongoing.

1. Message 3–5 friends/family in Israel who own iPhones.
2. Get their Apple ID email addresses (the one they use on App Store).
3. App Store Connect → TestFlight → External Testing → create group `Beta IL` → add testers by email → invite.
4. First external build requires a brief Apple Beta App Review (usually 1 day).

---

## §mac-bridge — OPTIONAL, deferred

**Why:** interactive Xcode debugging. Not critical for shipping.
**When:** whenever the founder chooses.
**ETA:** 30 minutes.

When ready:

1. On the Mac: System Settings → General → Sharing → enable **Remote Login**.
2. On Windows PowerShell: `ssh-keygen -t ed25519 -f C:\Users\Tal\.ssh\adkan_mac_ed25519 -N ""` (NO passphrase).
3. Copy the public key: `type C:\Users\Tal\.ssh\adkan_mac_ed25519.pub`.
4. On Mac: append that single line to `~/.ssh/authorized_keys`. (Create the file if it doesn't exist. `chmod 600` it.)
5. On Windows: test `ssh -i C:\Users\Tal\.ssh\adkan_mac_ed25519 tal@<mac-local-ip-or-hostname> "hostname"`. Should return the Mac hostname.
6. Create `config/mac-bridge.json` from the template in `adr/0007`. DO NOT commit — file is gitignored.
7. Run `node scripts/hello-mac.mjs`. Expected: prints "Mac bridge: ONLINE ..." and xcodebuild version.
8. Install `fastlane` on the Mac: `brew install fastlane` (or `sudo gem install fastlane` on older macOS without brew).
9. Founder-action: review the ADR 0007 fastlane snippet before enabling production signing automation.

---

## §env-local-template

After all sections complete, `.env.local` should look like this (values redacted here):

```
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_ANON_KEY=eyJ...
POSTHOG_PROJECT_KEY=phc_...
POSTHOG_HOST=https://eu.posthog.com
SENTRY_DSN=https://...@...ingest.sentry.io/...
APNS_KEY_ID=ABCDE12345
APNS_TEAM_ID=FGHIJ67890
# NOTE: .p8 contents + service_role key live in Supabase secrets, NOT here.
ADKAN_USE_STUB_SCREEN_TIME_PROVIDER=true
```

`.env.example` in the repo mirrors this structure with `REPLACE_ME` values only.

---

## Founder checklist summary

| # | Action | Day | Blocker for | Status |
|---|---|---|---|---|
| 1 | Apple Developer Program | 1 morning | Everything | [ ] |
| 2 | Register bundle ID | 1 morning | Entitlement, Xcode Cloud | [ ] |
| 3 | Submit FamilyControls entitlement | 1 morning | Real-device demo | [ ] |
| 4 | Supabase project | 2 morning | Backend | [ ] |
| 5 | PostHog project | 2 afternoon | Analytics | [ ] |
| 6 | Sentry project | 2 afternoon | Crash telemetry | [ ] |
| 7 | Apple Sign-In service + `.p8` | 3 | Auth flow | [ ] |
| 8 | APNs `.p8` AuthKey | 4 | Push | [ ] |
| 9 | Supabase secrets upload | 4 | Push + receipts | [ ] |
| 10 | App Store Connect app record | 5 | TestFlight | [ ] |
| 11 | Recruit 3–5 IL testers | 6 | Tier-2 validation | [ ] |
| 12 | Mac bridge (optional) | anytime | Local debug only | [ ] |

Tick each item in `plan/status.md` as completed.
