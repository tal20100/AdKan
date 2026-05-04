# AdKan — Production Checklist

Updated: 2026-05-03. Items marked **YOU** need founder action. Items marked **CODE** are things Claude Code handles.

---

## 1. Apple Developer Program (YOU) — ENROLLED

- [x] Enroll at developer.apple.com/programs — $99/year
- [ ] Wait for approval (24-48 hours)
- [ ] Once approved, note your **Team ID** from Membership page

**Unlocks:** TestFlight, Apple Sign-In configuration, FamilyControls entitlement request, App Store submission

---

## 2. Bundle ID Registration (YOU — first thing after approval)

- [ ] Go to Certificates, Identifiers & Profiles → Identifiers → Register
- [ ] Register: `com.talhayun.AdKan` (main app)
- [ ] Register: `com.talhayun.AdKan.AdKanWidget` (widget extension)
- [ ] Enable capabilities: Sign In with Apple, App Groups (`group.com.talhayun.AdKan`)
- [ ] Add your Team ID to `project.yml` → `DEVELOPMENT_TEAM: "YOUR_TEAM_ID"`

> **IMPORTANT:** The bundle ID in project.yml is `com.talhayun.AdKan`. Register exactly this.

---

## 3. Supabase Setup (YOU — can do right now, no Apple account needed)

- [ ] Create free project at supabase.com — name it `adkan`, region **Frankfurt** (EU, closest to Israel)
- [ ] Copy the **Project URL** and **anon public key** from Settings → API
- [ ] Go to SQL Editor → New Query → paste contents of `supabase/migration_001_initial.sql` → Run
- [ ] Verify tables appear: `users`, `groups`, `group_members`, `daily_scores`
- [ ] Create `config/SupabaseSecrets.plist` locally:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>SUPABASE_URL</key>
      <string>https://YOUR_PROJECT.supabase.co</string>
      <key>SUPABASE_ANON_KEY</key>
      <string>YOUR_ANON_KEY</string>
  </dict>
  </plist>
  ```
- [ ] **Do NOT commit this file** (it's in .gitignore)

---

## 4. Apple Sign-In Setup (YOU — after Developer Program approved)

- [ ] In Apple Developer Portal → Certificates, Identifiers & Profiles:
  - Enable "Sign In with Apple" on your App ID
- [ ] Create a **Services ID** (used by Supabase to verify tokens):
  - Identifier: `com.talhayun.AdKan.auth`
  - Enable Sign In with Apple
  - Configure: Return URL = `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
- [ ] Create a **.p8 key** → Keys → Create → enable Sign In with Apple
  - Download the .p8 file (you only get one download!)
  - Note the Key ID
- [ ] In Supabase Dashboard → Authentication → Providers → Apple:
  - Client ID: your Services ID
  - Secret Key: paste the .p8 contents
  - Key ID: from the key you just created
  - Team ID: from your Membership page
- [ ] In Xcode: Add "Sign In with Apple" capability to the AdKan target

---

## 5. FamilyControls Entitlement (YOU — after Developer Program approved)

- [ ] Go to developer.apple.com/contact/request/family-controls-distribution
- [ ] Explain: "AdKan is a social screen time competition app that helps users reduce phone usage by competing with friends. It uses FamilyControls to provide app blocking and usage monitoring."
- [ ] This can take days to weeks — Apple reviews manually
- [ ] Until approved, the app works with `StubScreenTimeProvider` in simulator and with limited access on real devices

---

## 6. App Groups Entitlement (YOU — needed for widget)

- [ ] In Apple Developer Portal → Identifiers → App Groups → Register:
  - `group.com.talhayun.AdKan`
- [ ] Add App Groups capability to both:
  - `com.talhayun.AdKan` (main app)
  - `com.talhayun.AdKan.AdKanWidget` (widget)
- [ ] This enables the home screen widget to read screen time data from the main app

---

## 7. App Icon (YOU)

- [ ] Design or commission a 1024x1024 app icon
- [ ] Add it to `App/Assets.xcassets/AppIcon.appiconset/`
- [ ] Xcode auto-generates all required sizes from the 1024px source
- [ ] Tip: The brain mascot could work as the icon base — green/purple gradient background

---

## 8. Legal Pages (YOU)

- [ ] Privacy policy page live at `taltalhayun.com/adkan/privacy`
  - Must mention: only daily total minutes leaves the device, Apple Sign-In, Supabase EU hosting, no per-app data synced
- [ ] Terms of service page live at `taltalhayun.com/adkan/terms`
- [ ] Both URLs are already wired in Settings — just need the pages to exist
- [ ] Can be simple markdown-style pages, Apple just needs them to exist and be accurate

---

## 9. Code Tasks (CODE — Claude Code handles these)

- [x] WidgetKit home screen + lock screen widget
- [x] Streak calendar grid
- [x] Weekly leaderboard card
- [x] Comparison cards (always visible)
- [x] Mascot with state-driven animations
- [x] Group invite deep links (`adkan://join?group=X`)
- [x] Milestone share cards (7/14/30/100 day)
- [x] Gender-aware Hebrew strings
- [x] Debug tools in Settings (toggle premium, trigger milestones)
- [ ] Landing page (separate repo — see `plan/landing-page-prompt.md`)
- [ ] Final Hebrew copy review pass
- [ ] Empty states polish (what users see before they have groups/data)
- [ ] Offline handling — graceful behavior when no network
- [ ] App Store review compliance scan (usage description strings, etc.)
- [ ] StoreKit 2 product configuration in App Store Connect
- [ ] Onboarding flow polish

---

## 10. StoreKit 2 / In-App Purchases (YOU + CODE)

- [ ] In App Store Connect → My Apps → AdKan → In-App Purchases:
  - Create subscription group "AdKan Premium"
  - Add products:
    - `com.talhayun.AdKan.subscription.monthly` — Monthly, ₪7.90
    - `com.talhayun.AdKan.subscription.annual` — Annual, ₪59.90
    - `com.talhayun.AdKan.lifetime` — Non-consumable, ₪99.90
- [ ] CODE: Update product IDs in `StoreManager.swift` to match exactly
- [ ] CODE: Create a `.storekit` configuration file for local testing

---

## 11. TestFlight (YOU + CODE — after steps 1-4 done)

- [ ] CODE: Set up archive scheme and signing
- [ ] YOU: Upload build via Xcode (Product → Archive → Distribute → App Store Connect)
- [ ] YOU: Add yourself as internal tester in App Store Connect → TestFlight
- [ ] YOU: Test on your real iPhone:
  - Apple Sign-In flow
  - ScreenTime permissions dialog
  - Score sync to Supabase
  - Widget appears in widget picker
  - Group creation + invite link sharing
  - Premium paywall (sandbox purchases)
- [ ] YOU: Optionally invite 3-5 friends as external testers

---

## 12. App Store Metadata (YOU — when ready to submit)

- [ ] App name: AdKan
- [ ] Subtitle (30 chars): "תחרות על זמן מסך" / "Screen Time Competition"
- [ ] Description (HE + EN) — Claude Code can draft this
- [ ] Keywords (100 chars): screen time, competition, friends, digital wellbeing, etc.
- [ ] 3-5 screenshots (6.7" iPhone 15 Pro Max + 6.1" iPhone 15 Pro)
- [ ] Category: Health & Fitness
- [ ] Age rating: 4+
- [ ] Support URL: `taltalhayun.com/adkan`
- [ ] Marketing URL: `taltalhayun.com/adkan` (landing page)

---

## Recommended Order

**Now (Developer Program processing):**
1. Set up Supabase (Step 3) — no Apple account needed
2. Start on app icon (Step 7)
3. Create landing page repo (separate)
4. Draft legal pages (Step 8)

**When Apple Developer approved:**
5. Register bundle IDs + App Groups (Steps 2, 6)
6. Apple Sign-In setup (Step 4)
7. Request FamilyControls entitlement (Step 5)
8. Create StoreKit products (Step 10)
9. First TestFlight build (Step 11)

**Before App Store submission:**
10. App Store metadata (Step 12)
11. Final polish pass (Step 9 remaining items)
12. Submit for review

---

## Known Issues to Fix Before Production

- [x] **Bundle ID alignment**: Aligned everything to `com.talhayun.AdKan` (project.yml, app-identity.json, AuthService, KeychainHelper, Tier, Products.storekit, RealScreenTimeProvider).
- [ ] **Deployment target**: `project.yml` says iOS 17.0, `app-identity.json` says 16.0. Recommend keeping 17.0 (simpler code, 95%+ of Israeli iPhones).
- [ ] **Team ID**: Add real Team ID to `project.yml` once Developer Program is approved.
- [ ] **Widget SharedDefaults**: Currently uses `group.com.talhayun.AdKan` — must match the App Group ID you register.
- [ ] **SupabaseSecrets.plist**: Needs to be created locally with real credentials before any backend features work.
- [ ] **Entitlements file**: Create `.entitlements` with App Groups + Sign In with Apple capabilities.
