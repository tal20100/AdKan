# AdKan — Production Checklist

Everything that needs to happen before TestFlight / App Store. Items marked with **YOU** need founder action. Items marked **CODE** are things I can handle.

---

## 1. Apple Developer Program (YOU)

- [ ] Enroll at [developer.apple.com/programs](https://developer.apple.com/programs) — $99/year
- [ ] Use your personal Apple ID (individual account, not organization)
- [ ] Approval takes 24-48 hours usually

**Unlocks:** TestFlight, Apple Sign-In configuration, FamilyControls entitlement request, App Store submission

---

## 2. Supabase Setup (YOU — can do right now, no Apple account needed)

- [ ] Create free project at [supabase.com](https://supabase.com) — name it `adkan`, region Frankfurt
- [ ] Copy the **Project URL** and **anon public key** from Settings → API
- [ ] Go to SQL Editor → New Query → paste contents of `supabase/migration_001_initial.sql` → Run
- [ ] Verify 4 tables appear in Table Editor: `users`, `groups`, `group_members`, `daily_scores`
- [ ] Create `config/SupabaseSecrets.plist` locally (see `supabase/setup-guide.md` Step 4) — **do NOT commit this file**

---

## 3. Apple Sign-In Setup (YOU — after Developer Program approved)

- [ ] Create Services ID in Apple Developer Portal (full instructions in `supabase/setup-guide.md` Step 2a)
- [ ] Create a .p8 secret key (Step 2b) — download it, save it safe, you only get one download
- [ ] Configure Apple provider in Supabase Dashboard (Step 2c)
- [ ] Add "Sign In with Apple" capability in Xcode (Step 2d)

---

## 4. FamilyControls Entitlement (YOU — after Developer Program approved)

- [ ] Go to [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
- [ ] Fill in the form explaining AdKan is a screen time competition app
- [ ] This can take days to weeks — Apple reviews manually
- [ ] Until approved, the app works fine in simulator with `StubScreenTimeProvider` and on real devices with limited ScreenTime access

---

## 5. App Icon (YOU)

- [ ] Design or commission a 1024x1024 app icon
- [ ] Add it to `App/Assets.xcassets/AppIcon.appiconset/`
- [ ] Xcode auto-generates all required sizes from the 1024px source

---

## 6. Legal Pages (YOU)

- [ ] Privacy policy page live at `taltalhayun.com/adkan/privacy`
  - Must mention: only daily total minutes leaves the device, Apple Sign-In, Supabase hosting, no per-app data synced
- [ ] Terms of service page live at `taltalhayun.com/adkan/terms`
- [ ] Both URLs are already wired in Settings — just need the pages to exist

---

## 7. App Store Metadata (YOU — when ready to submit)

- [ ] App name: AdKan
- [ ] Subtitle (30 chars): e.g. "תחרות על זמן מסך" / "Screen Time Competition"
- [ ] Description (HE + EN)
- [ ] Keywords
- [ ] 3-5 screenshots (6.7" iPhone 15 Pro Max + 6.1" iPhone 15 Pro)
- [ ] Category: Health & Fitness or Lifestyle
- [ ] Age rating: 4+
- [ ] Support URL: `taltalhayun.com/adkan`

---

## 8. Code Tasks (CODE — I can do these)

- [ ] WidgetKit lock screen + home screen widget (daily minutes / streak)
- [ ] Weekly recap shareable card (Instagram Stories format)
- [ ] Final Hebrew review pass — make sure everything reads natural
- [ ] Onboarding polish — make first-open flow feel premium
- [ ] Empty states — what users see before they have groups/scores
- [ ] Offline handling — graceful behavior when no network
- [ ] Deep link for group invites (so friends can join via shared link)
- [ ] App Store review compliance scan (usage description strings, etc.)

---

## 9. TestFlight (YOU + CODE — after steps 1-3 done)

- [ ] I set up the Xcode project for archiving + upload
- [ ] You upload the build via Xcode or Xcode Cloud
- [ ] Add yourself as internal tester first
- [ ] Test on your real iPhone: Apple Sign-In flow, ScreenTime permissions, score sync
- [ ] Optionally invite 3-5 friends as external testers

---

## Recommended order

**Today (no Apple account needed):**
1. Set up Supabase (Step 2)
2. Check the UI in simulator — tell me what to fix
3. Start on app icon if you have ideas

**When Apple Developer approved (24-48h after enrolling):**
4. Apple Sign-In setup (Step 3)
5. Request FamilyControls entitlement (Step 4)
6. First TestFlight build

**Before App Store submission:**
7. Legal pages (Step 6)
8. App Store metadata (Step 7)
9. I finish widgets, share card, final polish (Step 8)
