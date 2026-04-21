# Stamp & Antique Identifier (iOS / SwiftUI)

A SwiftUI iOS app that scans, identifies, values, and catalogs both **postage
stamps** and **antiques / vintage items** — modeled on the App Store listings
for *"Stamp Identifier: Scan Value"* and *"Antique Identifier: Appraiser+"*.

## Features

### Two modes, one app

A segmented mode toggle on Scan, Collection, and Learn switches the whole
surface between **Stamps** and **Antiques**. The toggle persists via
`@AppStorage` and retints all accents.

### Scan & Identify

- Camera capture and photo library picker.
- Corner-framed scanner viewfinder (orange for stamps, gold for antiques).
- Progress overlay during identification.
- Language chip (pickable from 15 languages) — mirrors the App Store
  "Ask in Your Language" screenshot.

### Stamp details

- Estimated dollar value, AI confidence pill, rarity badge, value range.
- Catalog numbers (Stanley Gibbons, Scott), country, year, denomination.
- Collapsible sections: Description, Physical Analysis, Historical Context,
  Value Analysis, Collector Info.

### Antique details

- `BRONZE VASE 1880` headline format with AI conf. pill (matches screenshot).
- Value-range banner in gold.
- Metadata: Category, Subcategory, Style, Year Made, Origin, Maker.
- Nine collapsible sections: Item Identification, Dating & Age,
  Origin & Provenance, Materials & Construction, Physical Characteristics,
  Condition Assessment, Valuation, Rarity & Significance,
  Authenticity & Authentication.

### Collection / Identification History

- Persisted per-mode in UserDefaults.
- Total count + total value summary tiles.
- 2-column grid with rarity tags (stamps) or date-added labels (antiques).
- Search by name, country/category, catalog number, style.
- Long-press to remove.

### Learn

- Two curated topic sets — stamps (catalog numbers, grading, watermarks,
  storage, authentication) and antiques (dating, provenance, construction,
  condition, authenticity, valuation).

## Project layout

```
StampIdentifier/
├── project.yml                       # XcodeGen project spec
├── README.md
└── StampIdentifier/
    ├── StampIdentifierApp.swift      # App entry (injects both stores)
    ├── Theme.swift                   # Brand colors (stamp + antique)
    ├── Info.plist
    ├── Assets.xcassets/              # AppIcon, AccentColor, BrandOrange,
    │                                 # BrandCream, AntiqueGold, AntiqueCream
    ├── Models/
    │   ├── CollectibleMode.swift     # .stamp / .antique enum
    │   ├── Stamp.swift
    │   └── Antique.swift
    ├── Services/
    │   ├── CurrencyFormatter.swift
    │   ├── StampStore.swift
    │   ├── AntiqueStore.swift
    │   ├── StampIdentificationService.swift
    │   └── AntiqueIdentificationService.swift
    └── Views/
        ├── RootTabView.swift         # Scan / Collection / Learn tabs
        ├── ScanView.swift            # Mode + language + camera / library
        ├── CameraPicker.swift
        ├── CollectionView.swift      # Mode-aware grid + totals + search
        ├── LearnView.swift           # Stamp + antique topic sets
        ├── LanguagePickerView.swift  # 15-language selector
        ├── StampDetailView.swift
        ├── AntiqueDetailView.swift
        └── Components/
            ├── RarityBadge.swift
            ├── StampCardView.swift
            └── AntiqueCardView.swift
```

## Building

### Option A — XcodeGen (recommended)

```bash
brew install xcodegen            # one-time
cd StampIdentifier
xcodegen generate                # creates StampIdentifier.xcodeproj
open StampIdentifier.xcodeproj
```

### Option B — fresh Xcode project

1. Open Xcode → **File › New › Project › iOS › App**, name it
   `StampIdentifier`, choose **SwiftUI** / **Swift** / iOS 17+.
2. Delete Xcode's stub `ContentView.swift` / `*App.swift`.
3. Drag the repo's `StampIdentifier/` source folder into the project
   navigator ("Copy items if needed", "Create groups").
4. Ensure the asset catalog and `Info.plist` are included in the app target.

## Swapping the mock identifiers for real ones

`StampIdentifying` and `AntiqueIdentifying` protocols live in `Services/`. The
mock implementations return plausible seed data after a short delay. Replace
either with a Vision / Core ML / Anthropic Claude vision backend — no UI
changes required.

## Requirements

- Xcode 15+
- iOS 17+ (uses `NavigationStack`, `PhotosPicker`, `safeAreaInset`,
  `navigationDestination(item:)`)

## License

MIT
