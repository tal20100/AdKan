# Plan 07 — Localization Strategy

Hebrew + English are first-class. No machine translation. `localization-lead` has VETO on UI copy PRs.

---

## Source of truth

`App/Localization/Localizable.xcstrings` — Xcode 15+ string catalog format. Single file, all keys. Versioned, diffable, merge-friendly.

Naming: `Feature.Screen.ElementPurpose`. Examples:
- `onboarding.q1.prompt`
- `onboarding.q1.options.low`
- `leaderboard.empty.inviteCta`
- `paywall.hero.title`
- `paywall.tier.lifetime.badge`
- `push.rankUp.title`
- `push.rankUp.body`
- `settings.privacy.boundarySentence`

Dot-separated, lowercase, no hyphens. Plural variations via string catalog's built-in `variations.plural.%arg` structure.

---

## Access pattern

Typed key accessor `App/Localization/L10n.swift`:

```swift
enum L10n {
    enum Onboarding {
        enum Q1 {
            static let prompt = LocalizedStringKey("onboarding.q1.prompt")
            enum Options {
                static let low = LocalizedStringKey("onboarding.q1.options.low")
                static let medium = LocalizedStringKey("onboarding.q1.options.medium")
                static let high = LocalizedStringKey("onboarding.q1.options.high")
                static let extreme = LocalizedStringKey("onboarding.q1.options.extreme")
            }
        }
        // ...
    }
}
```

Views read `Text(L10n.Onboarding.Q1.prompt)`. Pre-commit hook grep flags any bare string literal in a `Text(...)` outside `L10n.*`. Exempt: SF Symbol names, debug-only text.

Interpolation: use string catalog's `%@` / `%lld` placeholders. Swift-side:
```swift
Text("push.rankUp.body \(friendName)")
```
String catalog handles positional argument reordering per locale (important because Hebrew sentence order often differs from English).

---

## Parity enforcement (pre-commit hook 6)

`pre-commit-localization-gate.mjs`:

```js
// pseudocode
for (const file of stagedXcstringsFiles) {
  const catalog = JSON.parse(readFileSync(file));
  for (const [key, entry] of Object.entries(catalog.strings)) {
    const he = entry.localizations?.he?.stringUnit?.value;
    const en = entry.localizations?.en?.stringUnit?.value;
    if (!he || !he.trim()) fail(`${key}: missing 'he'`);
    if (!en || !en.trim()) fail(`${key}: missing 'en'`);
  }
}
```

Block-level. No commit passes with a missing language.

---

## RTL semantics

`config/app-identity.json` sets `textDirectionDefault: "rtl"`. At app root:

```swift
ContentView()
    .environment(\.layoutDirection, locale.isHebrew ? .rightToLeft : .leftToRight)
```

where `locale` is derived from `Locale.current` but overridable via Settings.

SwiftUI honors `layoutDirection` for:
- `HStack` → flows right-to-left.
- `Image(systemName: "chevron.right")` → stays pointing right (the **symbol** does not flip by default — use `.flipsForRightToLeftLayoutDirection(true)` for directional symbols).
- `.padding(.leading)` → leading edge is right in RTL.
- Scroll view bounce direction, navigation chevron, default nav-bar title alignment.

Hand-rolled gotchas:
- `.offset(x: 10)` — x is absolute, not direction-relative. Use `.offset(x: layoutDirection == .rightToLeft ? -10 : 10)`.
- `Path` and `Shape` drawings — absolute coordinates. Flip manually.
- Number formatting — use `NumberFormatter` with `locale: Locale(identifier: "he_IL")` for Hebrew numerals (which are actually Arabic digits 0-9 same as English, but formatting separators differ).
- Currency: ₪ (sheqel) symbol renders correctly in both directions when using `NumberFormatter.numberStyle = .currency` with `currencyCode = "ILS"`.

---

## Hebrew typography rules

1. **No machine translation.** Every Hebrew string is written or reviewed by a Hebrew native speaker. `localization-lead` is that gate. If I (Claude) draft Hebrew, I mark it `[HE-DRAFT — needs native review]` in the catalog's `comment` field.
2. **No Latin punctuation where Hebrew punctuation is correct.** E.g., use `–` (en dash) not `-` for ranges; quotation marks: `״` (gershayim) in formal contexts, though modern Hebrew UI typically uses `"` curly for readability.
3. **Gender neutrality where possible.** Modern Hebrew is heavily gendered. Use neutral forms (imperative plural, infinitive, or gender-inclusive `/` constructs like `עשה/עשי`) when addressing an unknown user. `localization-lead` chooses per string.
4. **No imported anglicisms when Hebrew has a clean word.** Avoid `אפליקציה` when `יישום` works; avoid `פוסט` when `פרסום` / `הודעה` fits. Context-dependent — `localization-lead` decides.
5. **Concise > literal.** English "Tap to continue" is `להמשיך` not `הקש כדי להמשיך`. Mobile UX favors brevity; Hebrew does too.
6. **Numbers in Hebrew sentences.** Digits stay LTR within RTL text runs — the OS handles bidi automatically. Do NOT wrap digits in `\u202A` / `\u202C` marks manually.

---

## String ownership matrix

| Feature | Initial author | Native review | Signs off |
|---|---|---|---|
| Onboarding 5 questions | Founder (already locked HE + EN in PRD 0001) | Founder (native) | localization-lead |
| Leaderboard UI | ux-designer draft | localization-lead + founder | localization-lead |
| Paywall | product-strategist draft | founder (native) | localization-lead |
| Push notifications | social-virality-designer draft | founder (native) | localization-lead |
| Error messages | ios-engineer draft | localization-lead | localization-lead |
| Settings | ux-designer draft | localization-lead | localization-lead |
| App Store description | product-strategist + founder | founder | localization-lead |

---

## Locale detection

First launch logic:
```swift
let defaultLocale: String = {
    let preferred = Locale.preferredLanguages.first ?? "en"
    return preferred.hasPrefix("he") ? "he" : "en"
}()
```

Stored in `users.preferred_locale`. User can switch in Settings → Language.

Server-side (Edge Functions): `users.preferred_locale` is the single source for push localization. If null (older user row), default to `he` per the IL-primary audience.

---

## Testing

- `LocalizableParityTests.swift` (Unit) — runs in-process assertion that the string catalog has both `he` and `en` for every key used via `L10n.*`. Complements the pre-commit hook (defense in depth).
- `RTLMirroringSnapshotTests.swift` (Snapshot) — renders key screens under both `ltr` and `rtl` environments, asserts no layout regressions.
- `HebrewInterpolationTests.swift` (Unit) — assert variable interpolation works correctly for plural keys across `he` and `en` (Hebrew has dual + plural + special forms; `en` has one/other).

---

## First 20 keys to write Day 2

To unblock the scaffold:

| Key | EN | HE |
|---|---|---|
| `app.displayName` | AdKan | עד כאן |
| `onboarding.welcome.title` | Welcome to AdKan | ברוך/ה הבא/ה לעד כאן |
| `onboarding.welcome.cta` | Let's go | יאללה |
| `onboarding.skip` | Skip | דלג/י |
| `onboarding.next` | Continue | המשך |
| `permission.prompt.title` | Accurate minutes, please | דקות מדויקות, אם אפשר |
| `permission.prompt.body` | AdKan needs Screen Time access to show your daily total. Nothing per-app leaves your phone. | עד כאן צריך גישה ל-Screen Time כדי להציג את הסך היומי שלך. שום מידע לפי אפליקציה לא עוזב את הטלפון. |
| `permission.prompt.allowCta` | Got it | הבנתי |
| `permission.prompt.skipCta` | Skip | דלג |
| `leaderboard.empty.title` | Your leaderboard is empty | הלוח שלך ריק |
| `leaderboard.empty.body` | Invite a friend to compare your day | הזמן חבר כדי להשוות את היום שלכם |
| `leaderboard.empty.cta` | Invite a friend | להזמין חבר |
| `leaderboard.myRow.self` | You | את/ה |
| `paywall.hero.title` | Be the hero — forever | היה הגיבור - לתמיד |
| `paywall.tier.lifetime.badge` | Best value | הכי משתלם |
| `paywall.tier.lifetime.price` | ₪99 once | ₪99 פעם אחת |
| `paywall.tier.annual.price` | ₪69 / year · 3-day trial | ₪69 לשנה · 3 ימים ניסיון |
| `paywall.tier.monthly.price` | ₪12.90 / month · 3-day trial | ₪12.90 לחודש · 3 ימים ניסיון |
| `push.rankUp.title` | Rank change | שינוי בדירוג |
| `push.rankUp.body` | You just passed %@ | עכשיו עברת את %@ |

All Hebrew strings above are founder-written (tal20100 is a native speaker) per Rule 6 ("no machine translation"). `localization-lead` verifies on final review.
