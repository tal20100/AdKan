# Spec 0001 — Onboarding Survey (implementation)

**Implements:** `/prd/0001-onboarding-survey.md`.
**Owner:** ios-engineer + ux-designer. **Reviewers:** qa-engineer (writes tests first), localization-lead.

## Module layout

```
App/Features/Onboarding/
├── Models/
│   ├── SurveyAnswer.swift         # enum with 5 question answer types
│   ├── SurveyState.swift          # @Observable aggregate of all 5 answers
│   └── SurveyFixtures.swift       # test fixtures + DEBUG-only defaults
├── Views/
│   ├── SurveyScreenQ1.swift       # hours confession
│   ├── SurveyScreenQ2.swift       # biggest hit
│   ├── SurveyScreenQ3.swift       # top enemy
│   ├── SurveyScreenQ4.swift       # crew type
│   ├── SurveyScreenQ5.swift       # daily goal
│   ├── SurveyTransitionScreen.swift  # 3s "מכינים את הלוח שלך..."
│   └── AvatarView.swift           # state-machine-driven avatar
├── Logic/
│   ├── AvatarReactor.swift        # maps Q1 answer → avatar morph
│   ├── SurveyEffectDispatcher.swift  # applies each answer's downstream effect
│   └── SurveyStore.swift          # GRDB persistence + retake loader
└── Localization/
    └── Onboarding.xcstrings       # all HE/EN copy
```

## Data model

```swift
enum HoursPerDay: String, Codable, CaseIterable {
    case oneToTwo
    case threeToFour
    case fiveToSix
    case dontAsk
}

enum BiggestHit: String, Codable, CaseIterable {
    case sleep
    case focus
    case people
    case all
}

enum TopEnemy: String, Codable, CaseIterable {
    case tiktok, instagram, youtube, whatsapp, x, other
}

enum CrewType: String, Codable, CaseIterable {
    case friends, roommates, partner, coworkers
}

enum DailyGoal: String, Codable, CaseIterable {
    case oneHour
    case twoHours
    case threeHours
    case appDecides
}

struct SurveyAnswer: Codable {
    var hoursPerDay: HoursPerDay?
    var biggestHit: BiggestHit?
    var topEnemy: TopEnemy?
    var crewType: CrewType?
    var dailyGoal: DailyGoal?
    var completedAt: Date?
    var skippedAtStep: Int?   // 1..5 if skipped, nil if completed
}
```

## Avatar state machine (Q1 effect)

```swift
enum AvatarState: String {
    case chill, stressed, melting, laughingCrying, streakWinning, spiraling
}

struct AvatarReactor {
    static func initialState(for answer: HoursPerDay) -> AvatarState {
        switch answer {
        case .oneToTwo: return .chill
        case .threeToFour: return .stressed
        case .fiveToSix: return .melting
        case .dontAsk: return .laughingCrying
        }
    }
}
```

## Effect dispatcher

```swift
protocol SurveyEffect {
    func apply(to settings: UserSettings)
}

struct PushScheduleEffect: SurveyEffect {
    let hit: BiggestHit
    func apply(to settings: UserSettings) {
        settings.preferredPushWindow = switch hit {
        case .sleep: .evening(22)
        case .focus: .morning(9)
        case .people: .afternoon(17)
        case .all: .rotating
        }
    }
}

struct TopEnemyEffect: SurveyEffect { let enemy: TopEnemy /* updates HomeScreen card */ }
struct GroupTemplateEffect: SurveyEffect { let crew: CrewType /* seeds invite copy + avatar pack */ }
struct GoalBaselineEffect: SurveyEffect { let goal: DailyGoal /* sets progress bar baseline */ }
```

`SurveyEffectDispatcher.applyAll(state:)` runs after Q5 completion AND after any Settings retake.

## Persistence

GRDB table `survey_answers`:
```sql
CREATE TABLE survey_answers (
  id INTEGER PRIMARY KEY,
  user_id TEXT NOT NULL,
  hours_per_day TEXT,
  biggest_hit TEXT,
  top_enemy TEXT,
  crew_type TEXT,
  daily_goal TEXT,
  completed_at TEXT,    -- ISO8601
  skipped_at_step INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Encrypted at rest via SQLCipher (per `/adr/0002-local-storage.md`). Never synced to Supabase — survey answers are device-local only.

## Skip flow

Every `SurveyScreenQX` view has a skip button in the top-trailing position. Tap → `SurveyStore.markSkipped(atStep: X)` → sets `skippedAtStep` and leaves prior answers as-is, THEN navigates directly to the home screen. Skipped users do NOT get `SurveyEffectDispatcher.applyAll` — they get default settings (generic avatar, 4h provisional goal, rotating push window, no top enemy card, `friends` default group template).

## Retake flow

Settings → `עריכת הסקר | Edit onboarding answers` row → re-runs Q1–Q5 from scratch (existing answers shown as defaults in option pickers). On completion, `SurveyEffectDispatcher.applyAll` runs again, overwriting prior effects.

## Tests (TDD — qa-engineer writes first)

`AdKanTests/Onboarding/`:
- `AvatarReactorTests.swift` — for each `HoursPerDay`, assert the correct initial `AvatarState`.
- `SurveyEffectDispatcherTests.swift` — for each effect, assert `UserSettings` post-state.
- `SurveyStoreTests.swift` — persist + reload roundtrip. Skip-then-retake preserves or overwrites correctly.
- `SurveyFlowUITests.swift` (XCUITest) — walk all 5 screens, verify avatar morphs, skip button reachability, RTL layout on HE locale.
- `SurveyLocalizationTests.swift` — for every `.xcstrings` key in `Onboarding.xcstrings`, assert both `he` and `en` values exist and are non-empty.

Snapshot tests via swift-snapshot-testing for each of the 5 screens in HE + EN + light + dark = 20 snapshots per screen baseline.

## RTL correctness checklist

- Skip button: `trailing` alignment resolves to visual-right in LTR, visual-left in RTL.
- Progress dots: reversed flow in RTL (counting from right).
- Avatar animations: mirrored horizontally in RTL where the avatar has facing direction.

## Out of scope for v1

- Branching question paths.
- Custom text input for Q3 `other`.
- A/B testing infrastructure for different copy.
- Animated mascot art (ASCII placeholder; real art is founder-action).
