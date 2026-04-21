# SobrMate — Days Clean Tracker (iOS, SwiftUI)

A clean, dark-themed iOS app for tracking sober / clean streaks across multiple habits. Inspired by the SobrMate: Days Clean Tracker screenshot, built with SwiftUI.

## Features

- **Multiple trackers** — track any habit (Alcohol, Social Media, Smoking, etc.) with its own color, emoji, and start date.
- **Live countdown** — each card updates every second with DAYS / HOURS / MINS / SECS clean.
- **Detail view** — animated streak ring, current / longest streak, start date, and monthly calendar grid.
- **Monthly calendar** — visualizes clean days, with month navigation.
- **Achievements** — 6 milestone badges (First Step, One Week, One Month, Three Months, Six Months, One Year).
- **Insights tab** — total habits, average streak, best current streak, per-habit progress bars.
- **Add / edit / reset / delete** — full lifecycle via sheets and context menus.
- **Daily motivational quote** — rotates based on the day of year.
- **Persistence** — all habits saved locally via `UserDefaults` (JSON-encoded).
- **Dark mode native** — designed for dark appearance.

## Project Layout

```
SobrMate/
├── SobrMateApp.swift          # @main entry
├── Models/
│   ├── Habit.swift            # Habit model + streak math
│   ├── Achievement.swift      # Milestone catalogue
│   └── Quote.swift            # Rotating daily quotes
├── Stores/
│   └── HabitStore.swift       # ObservableObject + persistence + 1s tick
├── Theme/
│   └── Theme.swift            # App colors + habit gradient palette
├── Views/
│   ├── RootView.swift         # TabView shell
│   ├── TrackersListView.swift # "My Trackers" list
│   ├── HabitDetailView.swift  # Ring + stats + calendar + actions
│   ├── AddHabitView.swift     # New tracker form
│   ├── EditHabitView.swift    # Edit existing tracker
│   ├── AchievementsView.swift # Badge grid
│   ├── InsightsView.swift     # Aggregate stats
│   ├── SettingsView.swift     # App settings
│   └── Components/
│       ├── HabitCardView.swift
│       ├── TimeCounterView.swift
│       ├── StreakRingView.swift
│       ├── CalendarGridView.swift
│       ├── BadgeView.swift
│       └── StatRow.swift
└── Resources/
    └── Info.plist
```

## Requirements

- Xcode 15+
- iOS 17+ (uses `toolbarTitleDisplayMode`, `ContentUnavailableView`)
- Swift 5.9+

## Running

1. Open Xcode → **File > New > Project > iOS App**.
2. Name it `SobrMate`, language **Swift**, interface **SwiftUI**, minimum deployment **iOS 17.0**.
3. Replace the generated sources by dragging the `SobrMate/` folder from this repo into the project navigator (choose **Copy items if needed**).
4. Delete the auto-generated `ContentView.swift` and `<Name>App.swift` if they conflict.
5. Build & run on an iPhone simulator or device.

## Customization

- **Colors / gradients** — edit `HabitPalette` in `Theme/Theme.swift`.
- **Milestones** — edit `Achievement.catalogue` in `Models/Achievement.swift`.
- **Quotes** — edit `Quote.library` in `Models/Quote.swift`.
- **Starter habits** — edit `Habit.samples`. On first launch the store seeds itself with these.

## Notes

- All data is stored locally; there is no account or server. To add iCloud sync, swap `UserDefaults` for `NSUbiquitousKeyValueStore` or a CloudKit-backed model.
- For a WidgetKit extension, reuse `Habit` and `HabitStore.load()` inside a timeline provider — the live countdown cards map directly to accessory widgets.
