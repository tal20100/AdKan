# AdKan — Production Publishing Guide

Complete step-by-step guide to get AdKan from code to TestFlight to App Store.

Updated: 2026-05-10

---

## Table of Contents

1. [Apple Developer Portal Setup](#1-apple-developer-portal-setup)
2. [Supabase Backend Setup](#2-supabase-backend-setup)
3. [Xcode Project Configuration](#3-xcode-project-configuration)
4. [Entitlements & Capabilities](#4-entitlements--capabilities)
5. [Apple Sign-In Configuration](#5-apple-sign-in-configuration)
6. [FamilyControls Entitlement Request](#6-familycontrols-entitlement-request)
7. [App Store Connect — Create the App](#7-app-store-connect--create-the-app)
8. [In-App Purchases (StoreKit 2)](#8-in-app-purchases-storekit-2)
9. [Code Changes Before First Build](#9-code-changes-before-first-build)
10. [Building & Archiving](#10-building--archiving)
11. [TestFlight](#11-testflight)
12. [App Store Submission](#12-app-store-submission)
13. [Branding & Credit](#13-branding--credit)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Apple Developer Portal Setup

**Prerequisite:** Apple Developer Program enrollment approved ($99/year). You enrolled 2026-05-03.

### 1.1 Find Your Team ID

1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Click **Membership Details** in the sidebar
3. Copy the **Team ID** (10-character alphanumeric string like `A1B2C3D4E5`)
4. Save this — you'll need it in several places

### 1.2 Register Bundle Identifiers

Go to **Certificates, Identifiers & Profiles → Identifiers → (+)**

Register these **App IDs** (type: App) one by one:

| # | Bundle ID | Description |
|---|-----------|-------------|
| 1 | `com.talhayun.AdKan` | AdKan — Main App |
| 2 | `com.talhayun.AdKan.AdKanWidget` | AdKan — Widget |
| 3 | `com.talhayun.AdKan.ShieldConfiguration` | AdKan — Shield Configuration |
| 4 | `com.talhayun.AdKan.DeviceActivityMonitor` | AdKan — Device Activity Monitor |

For each, choose **iOS** as the platform.

### 1.3 Register App Group

Go to **Identifiers → (+) → App Groups**

- Register: `group.com.talhayun.AdKan`

### 1.4 Enable Capabilities on Main App ID

Go to **Identifiers → `com.talhayun.AdKan` → Edit**

Enable these capabilities:

- [x] **App Groups** → select `group.com.talhayun.AdKan`
- [x] **Sign In with Apple**
- [x] **Family Controls** (won't appear until Apple approves your entitlement request — see Step 6)

### 1.5 Enable Capabilities on Widget

Go to **Identifiers → `com.talhayun.AdKan.AdKanWidget` → Edit**

- [x] **App Groups** → select `group.com.talhayun.AdKan`

### 1.6 Enable Capabilities on Extensions

For both `ShieldConfiguration` and `DeviceActivityMonitor`:

- [x] **App Groups** → select `group.com.talhayun.AdKan`
- [x] **Family Controls** (after approval)

---

## 2. Supabase Backend Setup

### 2.1 Create Project

1. Go to [supabase.com](https://supabase.com) → New Project
2. **Name:** `adkan`
3. **Region:** Frankfurt (EU) — closest to Israel, GDPR-friendly
4. **Database password:** generate a strong one, save it somewhere safe
5. Wait for project to provision (~2 minutes)

### 2.2 Get API Credentials

1. Go to **Settings → API**
2. Copy:
   - **Project URL** (looks like `https://abcdefghij.supabase.co`)
   - **anon public key** (starts with `eyJ...`)
3. You'll use these in Step 2.4

### 2.3 Run Database Migrations

Go to **SQL Editor → New Query**. Run these files **in order**, one at a time:

1. Paste contents of `supabase/migration_001_initial.sql` → **Run**
2. Paste contents of `supabase/migration_002_social.sql` → **Run**
3. Paste contents of `supabase/migration_003_premium_enforcement.sql` → **Run**

Verify tables exist: go to **Table Editor** and confirm you see:
`users`, `groups`, `group_members`, `daily_scores` (and any others from the migrations)

### 2.4 Create SupabaseSecrets.plist (Local Only)

Create the file `config/SupabaseSecrets.plist` on your machine:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://YOUR_PROJECT_ID.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_ANON_KEY_HERE</string>
</dict>
</plist>
```

Replace the placeholder values with your actual credentials from Step 2.2.

**This file is gitignored.** Never commit it. The app loads it at runtime via `SupabaseConfig.swift`. In DEBUG mode, it prints a warning if missing. In RELEASE mode, it crashes — so you must include it before archiving.

### 2.5 Add Plist to Xcode Build

After generating the Xcode project (Step 3), make sure `SupabaseSecrets.plist` is in the **Copy Bundle Resources** build phase of the AdKan target. If using XcodeGen, you may need to add it to `project.yml` resources or drag it manually in Xcode.

---

## 3. Xcode Project Configuration

### 3.1 Set Your Team ID

Open `project.yml` and replace:

```yaml
DEVELOPMENT_TEAM: ""
```

with:

```yaml
DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
```

Use the Team ID from Step 1.1. This applies to ALL targets.

### 3.2 Regenerate the Xcode Project

If you use XcodeGen:

```bash
xcodegen generate
```

Then open `AdKan.xcodeproj`.

### 3.3 Verify Signing in Xcode

1. Open Xcode → select the **AdKan** target
2. Go to **Signing & Capabilities** tab
3. Confirm:
   - **Team:** your Apple Developer team (should auto-populate from Team ID)
   - **Signing:** Automatically manage signing ✓
   - **Bundle Identifier:** `com.talhayun.AdKan`
4. Repeat for **AdKanWidget**, **AdKanShieldConfiguration**, **AdKanDeviceActivityMonitor**

If you see a provisioning profile error, Xcode will auto-create profiles when you first build. Make sure you're signed into your Apple Developer account in **Xcode → Settings → Accounts**.

---

## 4. Entitlements & Capabilities

### 4.1 Main App Entitlements

The file `App/AdKan.entitlements` is currently empty. It needs to contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.talhayun.AdKan</string>
    </array>
    <key>com.apple.developer.family-controls</key>
    <true/>
</dict>
</plist>
```

**Note:** The `family-controls` entitlement only works after Apple approves your request (Step 6). Until then, you can leave it in — Xcode will warn but the app still runs on simulator with `StubScreenTimeProvider`.

### 4.2 Widget Entitlements

Create `Widget/AdKanWidget.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.talhayun.AdKan</string>
    </array>
</dict>
</plist>
```

### 4.3 Extension Entitlements

Create similar entitlements for the Shield and DeviceActivity extensions with both App Groups and FamilyControls. These extensions also need `family-controls` to access screen time APIs.

### 4.4 Add Entitlements in Xcode

For each target in Xcode:

1. Select the target → **Signing & Capabilities** → **+ Capability**
2. Add **App Groups** → check `group.com.talhayun.AdKan`
3. For main app + extensions: Add **Family Controls**
4. For main app: Add **Sign In with Apple**

Xcode will update the entitlements files and provisioning profiles automatically.

### 4.5 Configure Entitlements in project.yml

Add entitlements references to each target in `project.yml`:

```yaml
# Under AdKan target settings:
CODE_SIGN_ENTITLEMENTS: App/AdKan.entitlements

# Under AdKanWidget target settings:
CODE_SIGN_ENTITLEMENTS: Widget/AdKanWidget.entitlements
```

---

## 5. Apple Sign-In Configuration

### 5.1 Create a Services ID

1. Go to **Certificates, Identifiers & Profiles → Identifiers → (+)**
2. Choose **Services IDs**
3. **Identifier:** `com.talhayun.AdKan.auth`
4. **Description:** AdKan Sign In
5. Check **Sign In with Apple** → Configure:
   - **Primary App ID:** `com.talhayun.AdKan`
   - **Domains:** `YOUR_PROJECT_ID.supabase.co`
   - **Return URLs:** `https://YOUR_PROJECT_ID.supabase.co/auth/v1/callback`
6. Save

### 5.2 Create a Sign-In Key (.p8)

1. Go to **Keys → (+)**
2. **Name:** AdKan Sign In Key
3. Enable **Sign In with Apple** → Configure → select `com.talhayun.AdKan`
4. **Register** → **Download** the `.p8` file
5. Note the **Key ID** displayed after creation

**CRITICAL:** You can only download the .p8 file ONCE. Store it securely. Never commit it to git.

### 5.3 Configure Supabase Auth Provider

1. In Supabase Dashboard → **Authentication → Providers → Apple**
2. Enable the Apple provider
3. Fill in:
   - **Client ID (Services ID):** `com.talhayun.AdKan.auth`
   - **Secret Key:** paste the entire contents of the `.p8` file
   - **Key ID:** from Step 5.2
   - **Team ID:** from Step 1.1
4. Save

### 5.4 Native iOS Sign-In

The app uses native Apple Sign-In (not web redirect). The `AuthService` sends the identity token to Supabase for verification. No additional web-flow configuration is needed for the iOS app itself — the Services ID + .p8 are for Supabase's server-side token validation.

---

## 6. FamilyControls Entitlement Request

This is the most critical and slowest step. Without it, the app cannot access real screen time data.

### 6.1 Request the Entitlement

1. Go to [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
2. Fill in the form:
   - **App Name:** AdKan
   - **Bundle ID:** `com.talhayun.AdKan`
   - **Description:** (suggested wording below)

> AdKan is a social screen time competition app that helps users reduce their phone usage by competing with friends in groups. Users set daily screen time goals and compete on leaderboards based on who uses their phone the least.
>
> The app uses FamilyControls to:
> - Monitor daily total screen time (aggregate minutes only, never per-app data)
> - Allow users to set app blocking schedules during focus sessions
> - Display shield screens when users attempt to open blocked apps
>
> Privacy: Only the daily total minutes number leaves the device. No per-app usage data, no category breakdowns, and no device identifiers are synced. The app is not targeted at children — it is a peer competition tool for adults.

### 6.2 Timeline

- Apple reviews these manually
- Expect **1-4 weeks** for a response
- They may ask follow-up questions
- You'll receive an email when approved

### 6.3 While Waiting

The app runs with `StubScreenTimeProvider` in the simulator and in TestFlight (without the entitlement, it shows fake data). This is fine for testing everything except actual screen time reading.

Once approved:
1. Re-enable `RealScreenTimeProvider.swift` in `project.yml` sources (remove the exclude)
2. Uncomment the Shield/DeviceActivity extension dependencies in `project.yml`
3. Swap the provider in `AdKanApp.swift`:
   ```swift
   return RealScreenTimeProvider()
   ```

---

## 7. App Store Connect — Create the App

### 7.1 Create a New App

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps → (+) New App**
2. Fill in:
   - **Platforms:** iOS
   - **Name:** `AdKan`
   - **Primary Language:** Hebrew
   - **Bundle ID:** `com.talhayun.AdKan` (select from dropdown — it appears after Step 1.2)
   - **SKU:** `adkan` (any unique string, internal use only)
   - **User Access:** Full Access

### 7.2 App Information

Under **App Information:**

| Field | Value |
|-------|-------|
| Name | AdKan |
| Subtitle (30 chars) | תחרות על זמן מסך |
| Category | Health & Fitness |
| Secondary Category | Social Networking |
| Content Rights | Does not contain third-party content |
| Age Rating | 4+ (no objectionable content) |

### 7.3 Pricing

- **Price:** Free (the app is free with in-app purchases)
- **Availability:** Israel first, expand later if desired

### 7.4 App Privacy

Under **App Privacy → Get Started:**

| Data Type | Collected? | Linked? | Tracking? |
|-----------|-----------|---------|-----------|
| Identifiers (User ID) | Yes | Yes | No |
| Usage Data (screen time minutes) | Yes | Yes | No |
| Purchases | Yes | Yes | No |

All other categories: **No**

This matches the `PrivacyInfo.xcprivacy` manifest (no tracking, only UserDefaults API).

---

## 8. In-App Purchases (StoreKit 2)

### 8.1 Create Subscription Group

In App Store Connect → **My Apps → AdKan → In-App Purchases → Manage**

1. Click **Subscription Groups → (+)**
2. **Group Name:** AdKan Premium
3. **Reference Name:** adkan_premium

### 8.2 Create Subscriptions

Inside the "AdKan Premium" group, add:

**Monthly:**
| Field | Value |
|-------|-------|
| Reference Name | Monthly |
| Product ID | `com.talhayun.AdKan.subscription.monthly` |
| Duration | 1 Month |
| Price | Tier matching ₪7.90 (check Israel pricing tier) |
| Display Name (HE) | חודשי |
| Display Name (EN) | Monthly |
| Description (HE) | קבוצות ללא הגבלה, אתגרים שבועיים וכל מה שצריך |
| Description (EN) | Unlimited groups, weekly challenges, and everything you need |

**Annual:**
| Field | Value |
|-------|-------|
| Reference Name | Annual |
| Product ID | `com.talhayun.AdKan.subscription.annual` |
| Duration | 1 Year |
| Price | Tier matching ₪59.90 |
| Display Name (HE) | שנתי |
| Display Name (EN) | Annual |
| Description (HE) | כל התכונות. חיסכון של 37%. בלי לחשוב על זה. |
| Description (EN) | All features. Save 37%. Set it and forget it. |

### 8.3 Create Non-Consumable (Lifetime)

Go to **In-App Purchases → (+) → Non-Consumable**

| Field | Value |
|-------|-------|
| Reference Name | Lifetime |
| Product ID | `com.talhayun.AdKan.premium.lifetime` |
| Price | Tier matching ₪99.90 |
| Display Name (HE) | לכל החיים |
| Display Name (EN) | Lifetime |
| Description (HE) | תשלום אחד. גישה מלאה. לתמיד. |
| Description (EN) | One payment. Full access. Forever. |

### 8.4 Review Status

Each product needs a screenshot to submit for review. You can use a screenshot of the paywall screen. Products stay in "Ready to Submit" status until you submit the app itself.

### 8.5 Product IDs Must Match Code

These product IDs are hardcoded in `App/Paywall/Tier.swift` and configured in `App/Products.storekit`. They must match EXACTLY:

- `com.talhayun.AdKan.subscription.monthly`
- `com.talhayun.AdKan.subscription.annual`
- `com.talhayun.AdKan.premium.lifetime`

The `.storekit` file is for local testing in Xcode simulator. Real purchases go through App Store Connect.

---

## 9. Code Changes Before First Build

### 9.1 Set Team ID

In `project.yml`, set `DEVELOPMENT_TEAM` to your real Team ID (Step 1.1).

### 9.2 Fill Entitlements

Update `App/AdKan.entitlements` with App Groups (and FamilyControls once approved). See Step 4.1.

### 9.3 Create SupabaseSecrets.plist

Create `config/SupabaseSecrets.plist` with real credentials. See Step 2.4.

### 9.4 Regenerate Xcode Project

```bash
xcodegen generate
```

### 9.5 Swap to Real Screen Time Provider (After FamilyControls Approval)

In `project.yml`, remove the exclude for `RealScreenTimeProvider.swift`:

```yaml
# Remove this line from excludes:
- "ScreenTime/RealScreenTimeProvider.swift"
```

In `App/AdKanApp.swift`, swap the provider:

```swift
private static func makeScreenTimeProvider() -> any ScreenTimeProvider {
    return RealScreenTimeProvider()
}
```

Uncomment the extension dependencies:

```yaml
dependencies:
  - target: AdKanWidget
    embed: true
  - target: AdKanShieldConfiguration
    embed: true
  - target: AdKanDeviceActivityMonitor
    embed: true
```

**Don't do this until FamilyControls is approved.** The stub provider works fine for TestFlight testing of everything else.

---

## 10. Building & Archiving

### 10.1 Pre-Build Checklist

- [ ] Team ID set in `project.yml`
- [ ] `SupabaseSecrets.plist` created with real credentials
- [ ] Xcode project regenerated (`xcodegen generate`)
- [ ] Signed into Apple Developer account in Xcode (Settings → Accounts)
- [ ] All targets show valid signing in Signing & Capabilities
- [ ] App icon added to `App/Assets.xcassets/AppIcon.appiconset/` (1024x1024)

### 10.2 Build for Testing (Simulator)

1. Select **AdKan** scheme
2. Select an iPhone simulator (iPhone 15 Pro recommended)
3. **Product → Build** (⌘B)
4. Fix any errors (most common: missing entitlements, unsigned targets)

### 10.3 Build for Device

1. Connect your iPhone via USB or select it in the device list
2. **Product → Build** (⌘B)
3. First time: Xcode auto-creates provisioning profiles
4. On your iPhone: **Settings → General → VPN & Device Management → trust your developer certificate**

### 10.4 Archive for TestFlight/App Store

1. Select **Any iOS Device (arm64)** as the build destination (not a simulator)
2. **Product → Archive** (or ⌘⇧B won't work — must use menu)
3. Wait for the archive to complete
4. The **Organizer** window opens automatically
5. Select the archive → **Distribute App**
6. Choose **App Store Connect** → **Upload**
7. Follow the prompts (keep defaults for bitcode, symbols, etc.)
8. Wait for upload to complete (~5-10 minutes)

### 10.5 Xcode Cloud (Alternative)

You have 25 free compute hours/month with your Developer Program. To set up:

1. In Xcode: **Product → Xcode Cloud → Create Workflow**
2. Select the AdKan scheme
3. Configure: build on push to `main`, archive for TestFlight
4. This automates the archive+upload step

---

## 11. TestFlight

### 11.1 After Upload

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps → AdKan → TestFlight**
2. The build appears after processing (~10-30 minutes)
3. If it says "Missing Compliance": click **Manage** → select "None of the above" for encryption (the app uses standard HTTPS only)

### 11.2 Internal Testing (You)

1. Under **Internal Testing → (+) Internal Group**
2. Add your Apple ID as a tester
3. The build is auto-available to internal testers (no review needed)
4. On your iPhone: open **TestFlight app** → install AdKan

### 11.3 What to Test

| Area | What to Check |
|------|---------------|
| **Launch** | App opens, shows onboarding (or home if already onboarded) |
| **Apple Sign-In** | Sign in flow works, creates user in Supabase |
| **Screen Time** | Permissions dialog appears (real device only, after FamilyControls) |
| **Home Screen** | Mascot shows, usage card shows minutes, streak calendar works |
| **Groups** | Create group, share invite link, leaderboard renders |
| **Widget** | Shows in widget picker, small + medium variants, updates data |
| **Notifications** | Toggle in settings, check notification center for scheduled ones |
| **Premium** | Paywall displays, sandbox purchase works |
| **Settings** | All toggles work, language switch, appearance, sign out |
| **Deep Links** | `adkan://join?group=X` opens the app to group detail |
| **RTL** | Hebrew layout correct, no text clipping, numbers correct |

### 11.4 Sandbox Purchases

TestFlight builds use the **sandbox** environment for StoreKit. To test purchases:

1. On your device: **Settings → App Store → Sandbox Account**
2. Sign in with your Apple ID (or create a sandbox tester in App Store Connect → Users → Sandbox Testers)
3. Purchases won't charge real money
4. Subscriptions auto-renew at accelerated rates (monthly = 5 min, annual = 30 min)

### 11.5 External Testing (Optional)

1. Under **External Testing → (+) External Group**
2. Add testers by email
3. **Requires Beta App Review** (usually approved in <24 hours)
4. Add a brief description of what to test
5. Testers receive a TestFlight invite email

---

## 12. App Store Submission

### 12.1 App Store Metadata

Fill in under **App Store → App Information** and **Prepare for Submission:**

**Descriptions:**

| Language | Field | Value |
|----------|-------|-------|
| Hebrew | Name | AdKan |
| Hebrew | Subtitle | תחרות על זמן מסך |
| Hebrew | Description | (draft — competitive screen time app for friends) |
| English | Name | AdKan |
| English | Subtitle | Screen Time Competition |
| English | Description | (draft — mirror of Hebrew) |

**Keywords (100 chars max):**
`screen time,competition,friends,digital wellbeing,focus,groups,leaderboard,streak,מסך,תחרות`

**URLs:**

| Field | Value |
|-------|-------|
| Support URL | `https://adkan.app` (or your domain) |
| Marketing URL | `https://adkan.app` |
| Privacy Policy URL | `https://adkan.app/privacy` |

### 12.2 Screenshots

Required sizes:
- **6.7" (iPhone 15 Pro Max):** 1290 × 2796 px
- **6.1" (iPhone 15 Pro):** 1179 × 2556 px

Recommended screens to screenshot:
1. Home screen with mascot + usage card
2. Group leaderboard with podium
3. Streak calendar
4. Widget on home screen (use a real home screen screenshot)
5. Focus/blocking mode active

Capture in both Hebrew and English.

### 12.3 Review Notes

Add in the **App Review Information** section:

> AdKan uses the FamilyControls framework to read the user's aggregate daily screen time (total minutes only). The app helps adults compete with friends to reduce phone usage. No per-app data leaves the device — only the daily total minutes number is synced for leaderboard rankings.
>
> Sign-in: Apple Sign-In only.
> Demo account: N/A (requires real Apple Sign-In).

### 12.4 Submit for Review

1. Ensure all metadata, screenshots, and privacy info are filled
2. Select the build from TestFlight
3. Click **Submit for Review**
4. Review typically takes 24-48 hours (can be faster or slower)

---

## 13. Branding & Credit

### 13.1 Public Branding

Everywhere users see the app, it's **AdKan**:

- App Store listing name: **AdKan**
- App icon display name: **AdKan** (set in `project.yml` → `INFOPLIST_KEY_CFBundleDisplayName`)
- Website/marketing: **adkan.app** (or your chosen domain)
- Support email: use a branded email if possible (e.g., `support@adkan.app`)

### 13.2 Where "Tal Hayun" Appears

These are required by Apple or Supabase and cannot be avoided:

| Location | What Shows | Why |
|----------|-----------|-----|
| App Store "Developer" line | Your legal name or entity name | Apple requires this for Individual accounts |
| Bundle ID (`com.talhayun.AdKan`) | Hidden from users | Internal identifier only, users never see it |
| Privacy Policy / Terms | Author/contact name | Legal requirement |
| Support email | Your email | Users see this only if they contact support |

**Note:** If you want to hide your personal name on the App Store, you would need to enroll as an **Organization** (requires a D-U-N-S number and business entity). With an Individual account, Apple shows your legal name as the developer. This cannot be changed without re-enrolling.

### 13.3 To Minimize Personal Name Exposure

- Use **AdKan** as the seller name where Apple allows customization
- Set the copyright to: `© 2026 AdKan`
- In the app's About/Settings, no name is shown (current implementation is correct)
- The privacy policy and terms pages can say "AdKan" with "by Tal Hayun" in small legal text at the bottom

---

## 14. Troubleshooting

### Common Issues

**"No signing identity found"**
→ Open Xcode → Settings → Accounts → make sure your Apple Developer account is listed. Click the team → Manage Certificates → create an Apple Distribution certificate if none exists.

**"Provisioning profile doesn't include the entitlement"**
→ Go to Apple Developer Portal → Identifiers → your App ID → make sure the capability (App Groups, Sign In with Apple, etc.) is enabled. Then in Xcode, toggle the capability off and on to regenerate the profile.

**"FamilyControls not available"**
→ The FamilyControls entitlement hasn't been approved yet. Use `StubScreenTimeProvider` until Apple approves. The app works fully except for real screen time data.

**Widget doesn't show data**
→ Check that both the main app and widget have the same App Group ID in their entitlements. Verify `SharedDefaults` uses `UserDefaults(suiteName: "group.com.talhayun.AdKan")`.

**"SupabaseSecrets.plist missing"**
→ Create the file (Step 2.4). Make sure it's added to the main app target's Copy Bundle Resources. In DEBUG, it shows a warning; in RELEASE, the app crashes intentionally.

**TestFlight build stuck on "Processing"**
→ Normal — can take up to 30 minutes. If it's stuck for hours, check your email for a rejection notice from Apple (usually due to missing privacy manifest or invalid binary).

**Sandbox purchases not working**
→ Make sure you have a sandbox tester account set up in App Store Connect → Users → Sandbox Testers. On device: Settings → App Store → sign in with the sandbox account.

**App rejected for "Guideline 5.1.1 — Data Collection and Storage"**
→ Ensure the privacy policy URL is live and accurately describes data handling. Mention that only daily total minutes leave the device.

---

## Quick Reference: All Identifiers

| Item | Value |
|------|-------|
| Bundle ID (Main) | `com.talhayun.AdKan` |
| Bundle ID (Widget) | `com.talhayun.AdKan.AdKanWidget` |
| Bundle ID (Shield) | `com.talhayun.AdKan.ShieldConfiguration` |
| Bundle ID (DeviceActivity) | `com.talhayun.AdKan.DeviceActivityMonitor` |
| App Group | `group.com.talhayun.AdKan` |
| Services ID (Sign-In) | `com.talhayun.AdKan.auth` |
| Product ID (Monthly) | `com.talhayun.AdKan.subscription.monthly` |
| Product ID (Annual) | `com.talhayun.AdKan.subscription.annual` |
| Product ID (Lifetime) | `com.talhayun.AdKan.premium.lifetime` |
| URL Scheme | `adkan://` |
| Deployment Target | iOS 17.0 |
| Primary Language | Hebrew |

---

## Recommended Order of Operations

### Phase 1 — Do Now (No Apple Approval Needed)
1. ✅ Set up Supabase project + run migrations (Step 2)
2. ✅ Create `SupabaseSecrets.plist` (Step 2.4)
3. ✅ Design app icon (1024×1024)
4. ✅ Write privacy policy + terms of service pages

### Phase 2 — After Developer Program Active
5. Register all bundle IDs + App Group (Steps 1.2-1.3)
6. Enable capabilities on App IDs (Steps 1.4-1.6)
7. Set Team ID in `project.yml` (Step 3.1)
8. Fill entitlements files (Step 4)
9. Set up Apple Sign-In (Step 5)
10. Request FamilyControls entitlement (Step 6)
11. Create app in App Store Connect (Step 7)
12. Set up in-app purchases (Step 8)

### Phase 3 — First TestFlight Build
13. Make code changes (Step 9)
14. Build + archive + upload (Step 10)
15. Test via TestFlight (Step 11)

### Phase 4 — App Store Launch
16. Add screenshots + metadata (Step 12)
17. Submit for review (Step 12.4)
18. Wait for approval (24-48 hours typically)
19. Release!
