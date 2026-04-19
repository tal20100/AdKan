# Brainrot + Unrot — what to copy, what to avoid

Source material: App Store listings, public reviews (2026), product websites. Required reading for every implementation agent BEFORE designing a feature. Every claim here is sourced. When a claim is unverifiable from public material, it's marked `[UNVERIFIED]`.

---

## Brainrot (id6744338972) — `Brainrot: Screen Time Control`

Publisher: Yonatan Smolyar (solo founder). Launch May 2025. Requires iOS 17.6+. ~1,400 App Store ratings at 4.67–4.8★ (US, April 2026). Climbed to Productivity #59 in its first week.

### Pricing (USD)
- Weekly $4.99 — the controversial one.
- Monthly $3.99.
- Annual $19.99–$29.99.
- No free tier. Full-feature paywall.
- Exit-discount (50% off) surfaced when users back out.

### Onboarding
- Video demo + problem framing.
- American "tell me about you" style, not direct.
- Mid-onboarding App Store review prompt.
- Smooth animations.

### Retention mechanic
- Brain mascot visually degrades as usage accumulates, heals as usage drops. This is the single most-praised mechanic in reviews.
- Intervention walls before accessing blocked apps.
- "Brainrot Streaks" (mechanics unclear from public material).

### What reviewers love
1. Dramatic usage reduction stories (9h → 4h week one is cited).
2. The cute mascot + degradation mechanic.
3. "Data never leaves your phone" privacy positioning.
4. Multiple friction walls before launching blocked apps.

### What reviewers hate
1. **"$5/week is insane."** This is the single loudest complaint. Directly informs our no-weekly pricing.
2. **Exit-discount feels scammy.** "Don't manipulate me into paying." Directly informs our no-exit-discount rule.
3. **Too many confusing bottom tabs.** UI clutter complaint.
4. **50-app block cap + single-group limitation.** Feature ceiling users hit and leave.
5. **Widget misbehaves, automations disappear.**
6. **No free trial** — must pay before knowing if the app even works.

### FamilyControls usage
Uses Apple Screen Time APIs; on-device only. No social / leaderboard in the main app. A separate companion app **Brainrot Friends** (id6747565760) adds social, but it is not integrated into the core product and has shallow adoption `[UNVERIFIED ADOPTION DATA]`.

### No Hebrew / RTL support `[NOT FOUND IN SOURCES]`.

---

## Unrot (id6746537171) — `Unrot: Earn your Screen Time`

Publisher: Unrot OÜ. Launch ~2025. Freemium — less controversial pricing structure than Brainrot.

### Pricing (USD)
- Free tier: open delay / friction, session limits, hard lock, daily limits, usage tracking, math challenge, pause.
- Paid: from $4.99/mo. Unlocks Focus/DND Mode + Refocus Activities.
- Multiple higher tiers surface in App Store ($9.99, $13.99, $29.99, $34.99, $69.99) — likely annual/promotional variants `[UNVERIFIED breakdown]`.
- ILS pricing not available in public sources.

### Retention mechanic
- **Brain credits** — earn them via walking, journaling, breathing, gratitude prompts. Spend credits for guilt-free app access.
- Mascot reflects dopamine/mood state in real time.
- 28-day challenge with bronze/silver/gold medals.
- Brain Rot Index ranks apps by aggressiveness — gives the app a sense of shared enemy.

### Onboarding
- Three-step funnel: pick your apps (presets for TikTok, IG, YouTube Shorts, X, Snapchat, Reddit), set rules, live intentionally.
- Direct and prescriptive. Not "tell me about you."
- No account required for free tier.

### What reviewers love
1. Credit-based "earn your screen time" framing — non-punitive vs. pure blockers.
2. Immediate visible results ("48% reduction first day" is a pitched figure).
3. Mental-health framing — anxiety reduction, grade improvement.
4. Mood check-ins.
5. Structured 28-day progression with medals.

### What reviewers hate
1. Unlocking credits via healthy-habit chores is effortful; some prefer buying directly `[UNVERIFIED depth of complaint]`.
2. Focus/DND locked behind paid tier; no free trial for advanced features.
3. AI usage concerns in creative features (vague but present).
4. Subscription dependency for sustained behavior change.

### No social / leaderboard / friend competition.
### No Hebrew / RTL support `[NOT FOUND]`.

---

## What AdKan copies

1. **Cute mascot + visual degradation** (from Brainrot). Avatar state-machine is in `/prd/0001-onboarding-survey.md` Q1 — avatar morphs from chill to melting based on the honest-hours answer.
2. **Credit / earn framing** (from Unrot). Our version: **social credit** — rank-gained minutes are celebrated in front of friends, not consumed alone.
3. **Freemium with meaningful free tier** (from Unrot). Brainrot's full paywall drove the loudest hate. Our free tier includes tracking, leaderboard of ≤3 friends, basic recap, avatar. Paywall only triggers on the 4th friend.
4. **Direct onboarding, no "tell me about you"** (from Unrot). Our 5 Israeli questions are direct, funny, each one changes the product within 10 seconds.

## What AdKan avoids

1. **Weekly subscriptions.** Never. Monthly ₪12.90, Annual ₪69, Lifetime ₪99. That's the entire price deck forever.
2. **Exit discounts.** Never. Transparent pricing builds trust. Discount-on-exit feels scammy (exact phrase from Brainrot reviews).
3. **Pay-to-start paywalls.** Paywall only after onboarding, only when users hit a value-earning limit (4th friend).
4. **Tab clutter.** Max 3 primary tabs (leaderboard, recap, settings). Top Enemy card and everything else lives inside.
5. **Fabricated statistics.** The post-survey stat claim is blank at launch. Populated only once we have real data, cited in `/docs/copy/onboarding-claims.md`.

## AdKan's unique wedge (no competitor does this)

1. **Hebrew-native.** Brainrot, Unrot, Opal, Jomo, One Sec, ScreenZen, Clearspace — none support Hebrew or RTL. This is structural advantage in IL.
2. **Social competition as PRIMARY loop**, not an afterthought. Brainrot has no social. Unrot has no social. Jomo buries "Squads." AdKan's home screen IS the leaderboard.
3. **Lifetime-as-hero at ₪99**, cheaper than Opal's $399 lifetime by an order of magnitude. Israeli buyers over-index on lifetime vs subscription — cultural "don't lock me in" preference `[UNVERIFIED — founder judgment]`.
4. **Friend-group templates** tuned for Israeli social contexts: חברים / שותפים לדירה / בן/בת זוג / עמיתים לעבודה. Each carries different invite tone.

---

## Sources

- Brainrot App Store listing — https://apps.apple.com/us/app/brainrot-screen-time-control/id6744338972
- Brainrot product site — https://thebrainrotapp.com/ and https://thebrainrotapp.com/faq.html
- Brainrot Friends listing — https://apps.apple.com/us/app/brainrot-friends/id6747565760
- Unrot App Store listing — https://apps.apple.com/us/app/unrot-earn-your-screen-time/id6746537171
- Unrot product site — https://www.unrotapp.com/
