# ADR 0006 — Distribution and Apple Developer Account

**Status:** Accepted.
**Date:** 2026-04-18.
**Deciders:** founder, release-engineer, app-store-reviewer.

## Context

AdKan is being built and distributed by a single founder (tal20100) operating as an individual in Israel. Apple offers two enrollment paths for the Apple Developer Program ($99/yr): **Individual** and **Organization**. The two paths differ in:

1. What appears as the "Seller" on the App Store listing (personal name vs. company name).
2. Whether a D-U-N-S number is required (Organization: yes; Individual: no).
3. Tax and legal exposure (Individual: personal liability; Organization: limited by entity form).
4. VAT collection model (both: Apple collects and remits; no change to the founder).
5. Eligibility for certain entitlements (Family Sharing features; MDM; etc. — none of which AdKan v1 uses).

Distribution method also has multiple paths: TestFlight internal (≤100 testers, no review), TestFlight external (≤10k testers, beta review required), App Store public submission (full 4.x + 5.x review).

## Decision

1. **Enroll as an Individual.** Personal name appears on the App Store listing.
2. **Bundle ID: `com.taltalhayun.adkan`.** Reverse-DNS based on founder's name; no domain ownership required.
3. **MVP distribution goal is TestFlight only.** External TestFlight (3–5 Israeli testers) is the validation surface for v1.
4. **App Store submission is deferred to a post-MVP milestone** with its own review-prep plan.
5. **Apple collects and remits VAT.** Founder reports earnings as personal income to the Israeli Tax Authority.
6. **CI is Xcode Cloud**, using the 25 free compute hrs/mo included in the Apple Developer Program (as of the 2026 update). No third-party CI required for v1.

## Alternatives considered

### Enroll as Organization with D-U-N-S
- **Pros:** company name on listing, perceived legitimacy, separates personal + business liability (with proper entity).
- **Cons:** D-U-N-S request is 3–14 business days; company registration in Israel (חברה בע"מ or עוסק מורשה) is a separate process; founder does not yet have an entity; accelerates an incorporation decision that is not yet product-justified.

Rejected for v1. Revisit post-launch if revenue warrants incorporation.

### Distribute via Ad Hoc provisioning profiles to known device UDIDs
- **Pros:** no TestFlight review cycle.
- **Cons:** caps at 100 devices total per year; UDIDs must be collected manually; no auto-update; no Apple-side crash telemetry; incompatible with the "remote eyes via Sentry + PostHog" strategy.

Rejected — TestFlight is strictly better for the device-less validation plan.

### Submit direct to App Store, skip TestFlight
- **Pros:** one review cycle instead of two.
- **Cons:** first-submission rejections are common; no feedback loop from real users before they hit Apple review; higher-risk path.

Rejected — TestFlight first, App Store when metrics + copy are validated.

### Self-hosted GitHub Actions macOS runner or Bitrise/CircleCI
- **Pros:** flexibility.
- **Cons:** Xcode Cloud is included with the Apple Developer Program fee; 25 hrs/mo is sufficient for a weekly TestFlight cadence; no additional vendor to manage; dSYMs upload to App Store Connect natively.

Rejected — added cost + complexity for no v1 benefit.

## Founder action items (blocking Day 1)

1. Enroll in the Apple Developer Program as an Individual at https://developer.apple.com/programs/enroll/. Cost: $99 USD (~₪360). ETA: hours to 2 days.
2. Register bundle ID `com.taltalhayun.adkan` in Apple Developer portal → Identifiers → App IDs. Enable capabilities: Sign in with Apple, Push Notifications, App Groups (`group.com.taltalhayun.adkan`), Family Controls.
3. Submit the Family Controls entitlement request via the developer contact form. Use the language suggested in `/plan/02-infrastructure-setup.md §family-controls-wording`. **Do this on Day 1 regardless of code state — the 1–30 day wildcard is the #1 timeline risk.**
4. Create the App Store Connect app record: Bundle ID as above, primary language Hebrew (he), secondary English (en), category "Health & Fitness" primary, "Lifestyle" secondary. Pricing tier placeholder; real IAPs configured later per `/specs/0003-monetization-and-paywall.md`.

## Tax and legal (Israel, individual)

- Apple collects VAT in the EU and remits. Apple does NOT collect Israeli VAT on sales to Israeli residents when the seller is outside Israel for VAT purposes; the founder as an Israeli resident earning via the App Store reports income as personal income.
- Founder should register as an `עוסק פטור` or `עוסק מורשה` if annual App Store revenue approaches the relevant threshold (approximately ₪108k/yr for `עוסק פטור` status in 2026; confirm with the Israeli Tax Authority or a qualified accountant — this ADR is not legal advice).
- Monthly Apple payouts are in USD to the bank account on file. Foreign-currency reporting is the founder's responsibility.
- This ADR is NOT legal or tax advice. The founder is responsible for confirming obligations with a licensed accountant before first payout. Logged here so the build phase doesn't pretend tax doesn't exist.

## Consequences

**Positive:**
- Zero blocker from D-U-N-S waits.
- Smallest paperwork surface.
- Apple collects and remits VAT (EU) automatically.
- $99/yr covers the developer program, TestFlight, Xcode Cloud, and App Store submission.

**Negative:**
- Personal name is visible on the App Store listing. Not a problem for v1; may want to revisit if scale warrants a company.
- No limited-liability shield. Personal liability exposure on the founder.
- Some advanced entitlements (MDM, specific Family Sharing features) are not available to Individual accounts. None are in v1 scope.
- Switching to Organization later requires contacting Apple Developer Support and involves a manual transfer; not a drop-in change.
