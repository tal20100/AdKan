# AdKan Landing Page — Claude Code Agent Brief

Use this file as the complete context for building the AdKan landing page in a separate repo (`adkan-landing`).

---

## What is AdKan?

**AdKan** (Hebrew: **עד כאן**, meaning "enough / stop right there") is an Israeli iOS app that turns screen-time reduction into a social competition. You compete with friends in groups to see who uses their phone the least each day. A brain mascot reacts to your daily usage, streaks motivate consistency, and OS-level app blocking enforces your commitment.

**Target audience:** Israeli 18-35 year olds who know they're on their phones too much and want a fun, social way to cut down. They came from Instagram or TikTok ads. They respond to Hebrew-first copy, competitive framing, and privacy assurance.

**Positioning:** This is NOT a wellness/health app. It's a game. Frame it as competitive, fun, slightly provocative. Think "Duolingo for screen time" not "meditation tracker."

---

## Brand Identity

### Name & Meaning
- English: **AdKan**
- Hebrew: **עד כאן**
- The name is a Hebrew expression meaning "that's enough" or "this is where I draw the line" — it captures the moment of taking control

### Color Palette

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| Brand Green | `#78C96F` | (120, 201, 111) | Primary accent, success states, CTA buttons |
| Brand Green Light | `#C5ED BA` | (197, 237, 186) | Hover states, light green accents |
| Brand Purple | `#A68BF7` | (166, 139, 247) | Premium features, badges, upgrade CTAs |
| Brand Purple Light | `#D6BAF1` | (214, 186, 241) | Premium hover/light accents |
| Surface Dark | `#1E1F20` | (30, 31, 32) | Dark backgrounds, hero sections |
| Brand Navy | `#1F4E6F` | (31, 78, 111) | Dark gradient endpoint, depth |
| Success Green | `#33C773` | (51, 199, 115) | Positive indicators |
| Warning Orange | `#FF9E0A` | (255, 158, 10) | Caution states |
| Danger Red | `#F24049` | (242, 64, 73) | Over-limit, danger states |

### Gradients
- **Hero Gradient:** Surface Dark → Brand Navy (top-left to bottom-right)
- **Primary Gradient:** Brand Green → Brand Green Light
- **Premium Gradient:** Brand Purple → Brand Purple Light

### Typography
- **Font:** SF Pro Rounded (or Inter/Plus Jakarta Sans as web equivalent with rounded alternates)
- **Design feel:** Rounded, friendly, approachable — not clinical or corporate
- All headings should feel bold and punchy

### Visual Style
- Dark mode primary (dark backgrounds, light text)
- No stock photos of people
- App mockups and screenshots only
- Brain mascot is the visual anchor
- RTL-first layout for Hebrew, with LTR English toggle

---

## The Mascot

A split brain — half gray (unfocused/scrolling) and half green (focused/thriving). It has 5 emotional states that react to daily usage:

| State | When | Mood |
|-------|------|------|
| Thriving | Under 50% of goal | Celebrating, thumbs up, glowing green |
| On Track | 50-100% of goal | Calm, encouraging smile |
| Slipping | 100-150% of goal | Worried, starting to sweat |
| Warning | 150-200% of goal | Distressed, red tint |
| Spiraling | Over 200% of goal | Full panic, on fire |

Use the mascot throughout the landing page — it's the personality of the brand.

---

## App Features (for feature grid/sections)

### Free Features
- **Daily Screen Time Tracking** — See your total daily usage at a glance
- **Brain Mascot** — Your personal accountability buddy that reacts to your habits
- **Streak Calendar** — Track consecutive days under your goal
- **3 Groups** — Compete with up to 3 friend groups (3 members each in free)
- **Daily Leaderboard** — See who's winning each day in your group
- **App Blocking (Basic)** — Block distracting apps when you hit your limit
- **Home Screen Widget** — Progress ring showing usage at a glance

### Premium Features (₪7.90/month)
- **Unlimited Groups** — Create as many competition groups as you want
- **Big Groups (30 members)** — Expand groups for larger competitions
- **Weekly Challenges** — Themed weekly competitions with your groups
- **Custom App Limits** — Set per-app time limits (e.g., 30 min TikTok, 1 hr YouTube)
- **Time-Based Blocking Rules** — Block apps during specific hours (e.g., bedtime, work hours)
- **Global Screen Time Limit** — Auto-block everything when total usage exceeds your threshold
- **Hard Mode** — Adds friction before you can open blocked apps (countdown timer, math problem, or type-a-phrase)
- **Custom Shield Design** — Personalize the blocking screen with your own motivational text and color themes
- **Premium Badges** — Exclusive streak badges and score multipliers
- **Enhanced Weekly Recap** — Detailed charts and insights
- **Monthly Summary Report** — Deep-dive trends and patterns
- **Custom Themes** — Personalize the app's look and feel

---

## Pricing

| Plan | Price | Notes |
|------|-------|-------|
| **Free** | ₪0 | Core features, 3 groups, basic blocking |
| **Monthly** | ₪7.90/mo | 3-day free trial |
| **Annual** | ₪59.90/yr | 3-day free trial, ~37% savings |
| **Lifetime** | ₪99.90 once | Best value badge |

All payments through Apple's App Store (StoreKit 2). No external payment processing needed.

---

## The Privacy Story (Critical Selling Point)

This is a MAJOR differentiator. Most screen time apps are data-hungry. AdKan is not.

**The rule:** Only your daily total minutes ever leaves your device. That's it. One number per day.

**What NEVER leaves the phone:**
- Which apps you use
- How long you use each app
- Per-hour usage patterns
- Your location
- Your contacts
- Device identifiers
- Health data

**How to frame it on the landing page:**
> "Your screen time data stays on your phone. Always. We only sync one number — your daily total — so your friends can see the leaderboard. That's it. No per-app tracking. No profiles. No ads. No selling your data."

This should be a prominent section, not buried in a footer. Israeli users are increasingly privacy-aware.

---

## How It Works (3-step narrative)

**Step 1: Set your goal**
Choose your daily screen time target. The app tracks your total usage automatically via Apple Screen Time.

**Step 2: Compete with friends**
Create a group, invite friends. See who uses their phone the least each day. Build streaks together.

**Step 3: Block what steals your time**
Select apps to block. When you try to open them, a shield screen stops you with a motivational message. Hard Mode adds extra friction so you really have to want it.

---

## Onboarding Flow (for screenshots/mockups)

The app opens with a 6-step personalization survey:
1. Welcome screen with mascot
2. "How should we talk to you?" (gender-aware Hebrew pronouns)
3. "How many hours a day are you on your phone?" (1-2h / 3-4h / 5-6h / 7+h)
4. "When do you scroll the most?" (Morning / Afternoon / Evening / All day)
5. "Your #1 enemy app?" (TikTok / Instagram / YouTube / Other)
6. "Who will you compete with?" (Friends / Roommates / Partner / Coworkers)
7. Daily goal selection
8. Screen Time permission request (one tap)

---

## Copy Direction

### Hero Section
**Hebrew (primary):** "עד כאן. הזמן שלך, בשליטה שלך."
**English:** "Enough. Your time, your control."

**Subheadline:** "Compete with friends to use your phone less. Track streaks, block distractions, and win back your day."

### Tone
- **Confident, not preachy** — "Take back your time" not "Screen addiction is a problem"
- **Competitive, not clinical** — "Beat your friends" not "Improve your digital wellbeing"
- **Playful, not corporate** — Use the mascot, use emojis sparingly, keep it human
- **Hebrew-first** — The primary audience reads Hebrew. English is secondary but must be equally polished
- **Slightly provocative** — "Your phone is winning. Change that." / "הטלפון מנצח. בואו נשנה את זה."

### Social proof copy ideas
- Fake leaderboard showing competition (no real user data)
- "Join X groups already competing" (placeholder number)
- Screenshot of streak calendar with 30-day streak

---

## Page Structure

### 1. Hero
- Bold headline + subheadline
- App mockup (phone frame with home screen screenshot)
- "Coming Soon to App Store" badge (or "Download" when live)
- Mascot peeking from behind the phone mockup

### 2. How It Works
- 3 cards/steps with icons: Track → Compete → Block

### 3. Features Showcase
- 2x3 or 3x2 grid of feature cards
- Highlight: Group Competition, Streak Calendar, Smart Blocking, Brain Mascot, Weekly Races, Privacy
- Premium features get a subtle purple glow/badge

### 4. The Mascot Section
- Show all 5 mascot states side by side
- "Your brain, visualized" — brief explanation of how it reacts

### 5. Blocking Demo
- Show the shield screen mockup
- Explain: "When you try to open a blocked app, this is what you see"
- Show Hard Mode friction (countdown, math gate, phrase typing)

### 6. Privacy Callout
- Big, bold section
- "One number. That's all that leaves your phone."
- Visual: phone icon with a single "72 min" bubble going to cloud, everything else stays on device

### 7. Pricing Table
- Free vs Premium comparison
- Monthly / Annual / Lifetime toggle
- CTA: "Start Free" or "Try Premium Free for 3 Days"

### 8. FAQ (optional)
- "Is my data safe?" → Yes, only daily total syncs
- "Does it actually block apps?" → Yes, OS-level blocking via Apple Screen Time
- "Can I use it alone?" → Yes, but it's more fun (and effective) with friends
- "What if I don't have an iPhone?" → iOS only for now, Android coming soon

### 9. Footer
- App Store badge (when available)
- Links: Privacy Policy, Terms of Service, Contact
- Contact email: tal.hayun2010@gmail.com
- Social links (if applicable)
- "Made in Israel" 🇮🇱

---

## Technical Requirements

### Stack
- **Framework:** Next.js (App Router) or Astro
- **Styling:** Tailwind CSS
- **Deployment:** Vercel
- **Domain:** taltalhayun.com/adkan or adkan.app (TBD)

### Performance
- Lighthouse score: 95+ on all metrics
- Mobile-first (most traffic from Instagram/TikTok ads on phones)
- Images: WebP, lazy loaded, properly sized
- Fonts: Subset only needed characters

### Internationalization
- Hebrew (RTL) is the PRIMARY language
- English (LTR) as secondary
- Language toggle in header (HE / EN)
- `dir="rtl"` on Hebrew, `dir="ltr"` on English
- Test both directions thoroughly — RTL layout bugs are common

### SEO
- Hebrew meta tags primary
- `<html lang="he" dir="rtl">` default
- Open Graph tags with app mockup image
- Twitter card tags
- Structured data (SoftwareApplication schema)

### Accessibility
- Proper heading hierarchy
- Alt text on all images
- Color contrast ratios meet WCAG AA
- Keyboard navigable

### Assets Available
- App icon (brain mascot, 1024x1024)
- 5 mascot state images (PNG)
- Text logo (adkan_logo_text.png)
- App screenshots can be mocked from the design system colors

---

## What NOT to do

- Don't frame it as a health/medical/wellness app — it's a game
- Don't use stock photos of people staring at phones
- Don't make the English version feel like a translation — it should feel native
- Don't use light mode as the primary design — the app is dark-themed
- Don't collect emails or personal data on the landing page (stays consistent with privacy story)
- Don't mention specific competitor apps by name
- Don't claim medical/health benefits
- Don't use "addiction" language — use "habits" and "control"
