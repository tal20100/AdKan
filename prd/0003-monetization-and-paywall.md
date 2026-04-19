# PRD 0003 — Monetization and Paywall

**Owner:** payments-engineer + product-strategist. **Reviewers:** app-store-reviewer, security-reviewer, localization-lead.

## Problem

Brainrot's $5/week lit the "insane pricing" backlash reviewers still cite daily. Brainrot's exit-discount felt scammy. Opal's $399 lifetime is unreachable for most IL buyers. AdKan's price deck needs to be: (a) transparent, (b) cheap enough to feel fair, (c) with a lifetime hero that converts the "I don't subscribe to anything" segment.

## Pricing (locked, ILS)

| Product | Price ILS | Trial | StoreKit Product ID |
|---|---|---|---|
| Monthly | ₪12.90 | 3-day free | `com.taltalhayun.adkan.subscription.monthly` |
| Annual | ₪69.00 | 3-day free | `com.taltalhayun.adkan.subscription.annual` |
| Lifetime | ₪99.00 | NO trial | `com.taltalhayun.adkan.lifetime` |

Non-negotiables:
- **No weekly tier. Ever.** (Brainrot review backlash.)
- **No exit discount.** (Scammy perception.)
- **No introductory A/B pricing.** Same price for every user, every region.
- **Lifetime is the hero.** Paywall layout puts lifetime first, visually larger, with a "best value" chip. Annual second, monthly third.
- **Apple collects VAT** on Israeli sales. Founder's Apple Developer Agreement handles this automatically for individual accounts.

## Intro-offer mechanics

Monthly and annual products carry a 3-day free trial configured as a StoreKit 2 introductory offer, one per subscription group. Lifetime is a non-consumable — StoreKit does not support intro offers on non-consumables, so no trial.

After the 3-day trial, the subscription auto-renews at the above price. The trial-to-paid transition fires a `paywall_trial_converted` PostHog event.

## The only paywall trigger

AdKan has ONE in-product paywall trigger in v1: attempting to invite a **4th friend** to a group on the free tier.

Copy (locked):
- HE: `הקבוצה שלך מלאה. שדרג כדי להזמין עד 15 חברים.`
- EN: `Your group is full. Upgrade to invite up to 15 friends.`

After this copy, the user sees the 3-tier paywall. Lifetime hero. Annual next. Monthly third.

Additional paywall entry points (secondary, not triggers):
- Settings → "Upgrade to Premium" row.
- Trial countdown on home → tap Day 6 message → paywall.
- Any Premium-gated setting toggled → paywall.

**No paywall before onboarding.** The survey (PRD 0001) and first leaderboard view must complete before the user ever sees a price. This is the Brainrot lesson — pay-to-start kills trust.

## Trial countdown

When a user has a 3-day trial active, the home-screen top bar shows:
- Day 1: `נסיון עד {date}` | `Trial through {date}`
- Day 3 (last day): `היום האחרון בנסיון — {hours_left}h נשארו` | `Last day of trial — {hours_left}h left`

If the user cancels before the trial ends, the home-screen top bar shows:
- `נסיון מסתיים ב-{date}. אתה חוזר לחינם.` | `Trial ends {date}. You'll return to free tier.`

No dark patterns. No hidden auto-renew. If the user does NOT cancel, auto-renew is on by default (standard StoreKit behavior).

## Lifetime + subscription coexistence

Both are listed in the App Store Connect submission. App Review Guideline 3.1.1 permits both in the same app. Rationale documented in the submission notes: *"Users who prefer to subscribe-for-flexibility can do so monthly or annually. Users who prefer a one-time purchase can do so. Feature set is identical across tiers — the only difference is payment model."*

Unlock matrix (Entitlement enum):
- `.none` — free tier. ≤3 friends, one group.
- `.trial` — viral-unlock 7-day trial OR 3-day intro trial. Full Premium features.
- `.subscriber` — monthly or annual active. Full Premium.
- `.lifetime` — once paid, forever. Full Premium. No refund window handled specifically beyond Apple's standard 14-day.

`TransactionObserver` listens to `Transaction.updates`. On every transaction result, `EntitlementResolver.resolve()` computes the current entitlement. Result cached in `@AppStorage` for offline launch resilience; reverified on foreground.

## Receipt validation

All transactions verified server-side by Supabase Edge Function `validate-receipt`, using Apple's `App Store Server API` with a per-transaction JWS signature check. Never trust client-side verification alone — tool-assisted bypass is trivially easy on iOS.

`.p8` server auth key stored in Supabase secrets (never in repo, matches `AuthKey_*` radioactive pattern from Rule 2).

## Refund handling

Apple's 14-day refund window stands. If a refund is processed:
1. Apple sends `REFUND` notification to our Edge Function.
2. Edge Function updates the user's `entitlements` row to `.none`.
3. On next app foreground, the user sees a non-shaming message:
   - HE: `ההחזר עובד. אתה חזרת לחינם — הקבוצה שלך הוגבלה ל-3 חברים.`
   - EN: `Refund processed. You're back on free — your group is limited to 3 friends again.`

No rage-bait. No manipulation.

## Out of scope for v1

- Promo codes.
- Referral discounts beyond the viral-unlock 7-day trial.
- Family Sharing of Premium (supported by StoreKit but deferred to v1.1).
- Gift subscriptions.
- Discounted annual offers for monthly subscribers.
- Region-varying prices beyond ILS default.
