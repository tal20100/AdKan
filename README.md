# AdKan / עד כאן

Screen time competition app for Israeli friend groups. Track your daily phone usage, compete with friends to use less, and build healthy habits through social accountability.

"עד כאן" (ad kan) means "enough" in Hebrew — a declaration of taking control of your time.

## Features

- **Social Competition** — Create groups, invite friends, compete on daily screen time
- **Streak Calendar** — Visual 35-day dot grid showing your consistency (like GitHub contributions)
- **Weekly Races** — Monday-to-Sunday leaderboards with fresh starts each week
- **Brain Mascot** — Animated character that reacts to your usage (thriving → spiraling)
- **Smart Blocking** — Schedule-based app blocking rules with "Hard Mode" friction gates
- **Milestone Sharing** — Shareable cards at 7/14/30/100-day streaks
- **Home Screen Widget** — Circular progress ring + streak count on your lock screen
- **Privacy First** — Only your daily total minutes leaves your phone. Never per-app data.

## Tech Stack

- **iOS**: Swift 5.9, SwiftUI, iOS 17.0+, iPhone only
- **Backend**: Supabase (PostgreSQL + Auth + REST API), EU Frankfurt region
- **Auth**: Apple Sign-In only
- **Screen Time**: FamilyControls / DeviceActivityMonitor (stub provider for development)
- **Payments**: StoreKit 2 (monthly / annual / lifetime)
- **Widget**: WidgetKit (systemSmall + accessoryCircular)
- **Localization**: Hebrew (primary, RTL) + English
- **Project Generation**: XcodeGen (`project.yml` → `.xcodeproj`)

## Getting Started

### Prerequisites

- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- iOS 17.0+ simulator or device

### Setup

```bash
# Clone
git clone https://github.com/tal20100/AdKan.git
cd AdKan

# Generate Xcode project
xcodegen generate

# Open in Xcode
open AdKan.xcodeproj
```

The app runs in **stub mode** by default (no Supabase needed). All backend services return mock data, and screen time uses a simulated provider.

### Connecting Supabase (optional)

1. Create a Supabase project at supabase.com
2. Run `supabase/migration_001_initial.sql` in the SQL Editor
3. Create `config/SupabaseSecrets.plist` with your project URL and anon key (see `config/SupabaseSecrets.plist.example`)

### Testing Premium Features

In `#if DEBUG` builds, go to Settings → scroll to the Debug section:
- **Toggle Premium** — enables/disables premium features instantly
- **Trigger 7-day Milestone** — shows the milestone share card
- **Reset Streak** — clears streak data

## Project Structure

```
App/
├── AdKanApp.swift          # App entry point, deep link handling
├── RootView.swift           # Tab bar (Home, Groups, Settings)
├── Router.swift             # Navigation state
├── Backend/                 # Supabase services (auth, sync, leaderboard, groups)
├── DesignSystem/            # Theme, buttons, cards, premium gate
├── Groups/                  # Group list, detail, create, invite
├── Home/                    # Home screen, mascot, streak calendar, leaderboard
├── Localization/            # LanguageManager (HE/EN runtime switch)
├── Models/                  # Group, StreakTracker, SharedDefaults, RankHistory
├── Notifications/           # Evening reminder, weekly check-in, streak-at-risk
├── Onboarding/              # Survey + onboarding flow
├── Paywall/                 # StoreKit 2 paywall, StoreManager, tiers
├── ScreenTime/              # Provider protocol, stub, real, blocking rules, Hard Mode
├── Settings/                # Settings screen
├── Visualization/           # Comparisons, progress bar, rank indicator, monthly summary
├── Assets.xcassets          # Images, colors, app icon
└── Localizable.xcstrings    # All HE+EN strings

Widget/
├── AdKanWidget.swift        # WidgetKit timeline + views
└── SharedDefaults.swift     # App Groups bridge (reads from main app)

AdKanTests/                  # Unit tests
```

## Architecture

- **No third-party dependencies** — pure Apple frameworks (URLSession, not Alamofire; native JSON, not SwiftyJSON)
- **Protocol-oriented backend** — all services are protocols with real (Supabase) and stub implementations
- **Privacy boundary** — enforced at the protocol level; only `dailyTotalMinutes: Int` crosses the network
- **XcodeGen** — `.xcodeproj` is not committed; generated from `project.yml`

## License

Proprietary. All rights reserved.
