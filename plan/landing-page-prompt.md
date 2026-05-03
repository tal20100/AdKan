# Claude Code Prompt — AdKan Landing Page

Paste this into a new Claude Code session in your `adkan-landing` repo.

---

```
Build a beautiful, high-converting landing page for AdKan (עד כאן) — an Israeli iOS app that turns screen time reduction into a social competition between friends.

## What AdKan does
- Tracks daily screen time using Apple's ScreenTime API
- Friends compete in groups to use their phones less
- Features: daily leaderboard, streak calendar (like GitHub contribution graph), mascot that reacts to your usage, weekly competitions, milestone sharing, smart blocking rules, "Hard Mode" friction gates
- Hebrew-first (RTL), also supports English
- Privacy-focused: only daily total minutes leaves the device — no per-app data ever synced
- Free tier: 1 group of 5. Premium: unlimited groups, advanced blocking rules, monthly summary, Hard Mode

## Design direction
- Dark-mode hero with green (#34C759) and purple (#AF52DE) accent gradients — these are the app's brand colors
- Premium, modern feel — think Linear or Arc browser landing pages, not corporate
- Mobile-first (most traffic will be Israeli mobile users from Instagram/TikTok)
- Hebrew is the primary language — the page should default to Hebrew (RTL) with an EN toggle
- App name "עד כאן" means "enough / up to here" — it's a statement of taking control

## Sections
1. **Hero** — Bold headline "עד כאן. הזמן שלך, בשליטה שלך." (Enough. Your time, your control.) + app mockup/screenshot area + "Download on App Store" button (link to #, not live yet) + "Coming Soon" badge
2. **How it works** — 3-step visual: Track → Compete → Win back your time
3. **Features grid** — 4-6 cards showing: Group Competition, Streak Calendar, Smart Blocking, Brain Mascot, Weekly Races, Privacy First
4. **Social proof / Competition preview** — Show a fake leaderboard card to illustrate the social element
5. **Privacy callout** — "Only your daily total leaves your phone. We never see which apps you use." — this is a KEY differentiator
6. **Pricing** — Free vs Premium comparison, simple
7. **Footer** — Links to privacy policy (taltalhayun.com/adkan/privacy), terms (taltalhayun.com/adkan/terms), contact (tal.hayun2010@gmail.com)

## Tech stack
- Next.js (App Router) or plain HTML + Tailwind — whatever gets a beautiful result fastest
- Deploy target: Vercel
- Animations: subtle scroll-triggered (framer-motion or CSS), not heavy
- No backend needed — pure static
- OG meta tags for social sharing (Hebrew title + description + preview image)
- Favicon from the app icon (I'll add it later, use a placeholder)

## Must-haves
- RTL layout for Hebrew (use dir="rtl" and lang="he")
- Language toggle (HE/EN) — can be client-side state, no i18n framework needed
- Responsive: looks great on iPhone 15 Pro screen width
- Fast: aim for 95+ Lighthouse performance score
- Dark background (#0A0A0A or similar), light text, green/purple gradients on CTAs
- App Store badge (use Apple's official badge SVG, Hebrew version)

## Don't
- Don't use stock photos of people
- Don't make it look like a medical/health app — it should feel like a game/competition
- Don't add a blog, changelog, or docs section — just the landing page
```

---
