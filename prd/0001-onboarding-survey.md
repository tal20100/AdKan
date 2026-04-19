# PRD 0001 — Onboarding Survey

**Owner:** product-strategist. **Reviewers:** ux-designer, localization-lead, growth-analytics-engineer.

## Problem

The survey is not lead-gen. It is not a "tell me about yourself" questionnaire. It is a **60-second commitment funnel** whose real job is to deliver three sensations in order:
1. "This app gets me." (Q1, Q2, Q3)
2. "The product already personalized itself for me." (effect-per-answer)
3. "If I leave now, I lose my plan." (Q5 + post-survey board)

These are the Brainrot/Unrot mistakes we avoid: American phrasing, generic options, no visible effect. We replace them with Israeli idioms, direct options, and a user-visible product change within 10 seconds of each answer.

## Scope

5 questions. Skip link top-right (top-left in RTL) always visible. Each answer triggers a visible product change before the next screen. Survey does NOT block the core loop — it leads into it. Users can retake from Settings. Skipped users' answers are not retained.

## The 5 questions (locked copy)

Copy is locked — never machine-translate, never paraphrase. Both HE and EN are first-class; `localization-lead` vetoes changes that drift from the idiomatic tone.

---

### Q1 — The confession
**HE:** `בוא נהיה כנים. כמה שעות ביום אתה במסך?`
**EN:** `Let's be honest. How many hours a day are you on your phone?`

Options (`SurveyAnswer.hoursPerDay`):
- `שעה-שעתיים` | `1-2h` → `one_to_two`
- `3-4 שעות` | `3-4h` → `three_to_four`
- `5-6 שעות` | `5-6h` → `five_to_six`
- `אל תשאל` | `Don't ask` → `dont_ask`

**Visible effect before next screen:** avatar morphs. `one_to_two` → chill. `three_to_four` → stressed. `five_to_six` → melting. `dont_ask` → laughing-crying. Avatar animates the transition as the user taps.

**Why "Don't ask" exists:** Israeli humor. An American app would say "Prefer not to say." We say "אל תשאל." The laughing-crying avatar breaks the guilt frame Brainrot leans on.

---

### Q2 — The real problem
**HE:** `מה הכי נפגע מזה?`
**EN:** `What takes the biggest hit?`

Options (`SurveyAnswer.biggestHit`):
- `שינה` | `Sleep` → `sleep`
- `ריכוז בעבודה/לימודים` | `Focus` → `focus`
- `זמן עם אנשים שחשובים לי` | `Time with people I care about` → `people`
- `הכל` | `Everything` → `all`

**Visible effect:** schedules push-notification preferred window. `sleep` → evening pushes (22:00). `focus` → morning pushes (09:00). `people` → afternoon pushes (17:00). `all` → rotating.
Also seeds the Friday-recap framing: "You won back 2h from your sleep this week" vs "...from your focus time."

---

### Q3 — The enemy
**HE:** `מי האויב? באיזו אפליקציה אתה הכי נתקע?`
**EN:** `Who's the enemy? Which app gets you stuck the most?`

Options (`SurveyAnswer.topEnemy`):
- `TikTok`, `Instagram`, `YouTube`, `WhatsApp`, `X`, `אחר | Other`

**Visible effect:** home screen gets a "Top Enemy" card immediately after the survey. If a user's friends all pick the same app, the group gets a shared challenge around that app. This is the first social signal: "your enemy is our enemy."

Note: AdKan never SHOWS per-app screen time to the backend (privacy boundary — `adr/0004`). The enemy card is generated from this survey answer + the user's local FamilyControls data. Never synced.

---

### Q4 — The crew
**HE:** `עם מי אתה רוצה להתחרות? תבחר את הקבוצה שלך.`
**EN:** `Who do you want to compete with? Pick your crew.`

Options (`SurveyAnswer.crewType`):
- `חברים` | `Friends` → `friends`
- `שותפים לדירה` | `Roommates` → `roommates`
- `בן/בת זוג` | `Partner` → `partner`
- `עמיתים לעבודה` | `Coworkers` → `coworkers`

**Visible effect:** group template applied. Default group name, avatar pack, and invite-message tone differ per selection:
- `friends`: casual, emoji-heavy, "יאללה תצטרף."
- `roommates`: practical, "ששונאים את הטלפון ביחד."
- `partner`: playful, "ננצח אחד את השני?"
- `coworkers`: professional, "מתמודדים על פרודוקטיביות השבוע?"

---

### Q5 — The target
**HE:** `כמה זמן מסך ביום זה המטרה שלך?`
**EN:** `What's your daily screen time goal?`

Options (`SurveyAnswer.dailyGoal`):
- `שעה` | `1h` → `one_hour`
- `שעתיים` | `2h` → `two_hours`
- `שלוש שעות` | `3h` → `three_hours`
- `אני רוצה שהאפליקציה תחליט` | `Let the app decide` → `app_decides`

**Visible effect:** progress bar baseline set.

`app_decides` is the **sunk-cost moment**: the app uses the user's current 7-day average screen time minus 20% as a smart default. Copy frames it: "הגדרנו לך יעד לפי השבוע האחרון שלך — נוריד ב-20%." If the user has no baseline data yet (FamilyControls just authorized, no history), we use 4h as the default and mark the goal as "provisional" until real data arrives.

---

## Post-survey transition (3 seconds)

**HE:** `מכינים את הלוח שלך... נתחיל?`
**EN:** `Setting up your board... Ready?`

Single button: `יאללה | Let's go` → straight into the leaderboard with a placeholder score ("0 min today — let's see what happens").

## Skip behavior

Skip link always visible, top-right in LTR, top-left in RTL. Tap → survey is abandoned, no answers retained, user lands on leaderboard with default state (generic avatar, no top-enemy card, no personalized push schedule, 4h provisional goal).

Skip is offered per-screen, not just at the start. Every question has its own skip affordance.

## Retake from Settings

Settings row: `עריכת הסקר | Edit onboarding answers`. Re-runs Q1–Q5; on completion, re-applies all five effects (avatar, push schedule, top enemy, group template, goal).

## The no-fabricated-stats rule

Pre-launch: no statistics screen appears. Do NOT display "Users with similar goals reduced by X minutes" until we have real data from at least 500 AdKan users, with the aggregate query documented in `/docs/copy/onboarding-claims.md` and the number cited there.

Post-launch: the Q5 screen gets a new line:
**HE:** `אנשים עם יעד דומה ירדו בממוצע X דקות בשבוע הראשון.`
**EN:** `People with a similar goal reduced by an average of X minutes in their first week.`

`X` is sourced from a PostHog aggregate query, refreshed weekly, stored as a build-time constant. Any agent that adds a statistic claim before 500 real users is blocked by `security-reviewer` and `privacy-engineer`.

## Analytics events (PostHog)

- `onboarding_started`
- `onboarding_q1_answered` (property: `hoursPerDay`)
- `onboarding_q2_answered` (property: `biggestHit`)
- `onboarding_q3_answered` (property: `topEnemy`)
- `onboarding_q4_answered` (property: `crewType`)
- `onboarding_q5_answered` (property: `dailyGoal`)
- `onboarding_skipped` (property: `atStep` 1..5)
- `onboarding_completed`

No PII. All events fire with the anonymous Supabase UUID only.

## Out of scope for v1

- Branching question paths.
- A/B testing different question copy.
- Custom text input for "Other" on Q3.
- Video-based survey (Brainrot-style intro video).
- Animated mascot art — ASCII placeholder on Day-2, real art is a founder-action.
