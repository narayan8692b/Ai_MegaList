# Stamp Identifier (iOS / SwiftUI)

An iOS app that scans, identifies, values, and catalogs postage stamps — modeled
on the App Store listing screens for *"Stamp Identifier: Scan Value"*.

## Features

- **Scan & Identify** — capture a stamp with the camera or pick a photo from your
  library. A mock AI identifier returns a plausible result with confidence score.
- **Actual Stamp Value** — detail page with estimated dollar value, rarity
  badge, value range, AI confidence pill, and rich description.
- **Build Your Collection** — persistent grid of saved stamps with totals
  (stamp count and portfolio value) and rarity labels.
- **Learn Everything About Stamps** — catalog numbers (Stanley Gibbons, Scott,
  Michel, Yvert), grading, watermarks, storage, authentication.
- **Collapsible analysis sections** — Physical Analysis, Historical Context,
  Value Analysis, Collector Info.

## Project layout

```
StampIdentifier/
├── project.yml                       # XcodeGen project spec
├── README.md
└── StampIdentifier/
    ├── StampIdentifierApp.swift      # App entry
    ├── Theme.swift                   # Brand colors
    ├── Info.plist
    ├── Assets.xcassets/              # AppIcon, AccentColor, BrandOrange, BrandCream
    ├── Models/
    │   └── Stamp.swift               # Stamp, Rarity, StampValueRange + seed data
    ├── Services/
    │   ├── StampStore.swift          # Persistence via UserDefaults
    │   └── StampIdentificationService.swift   # Mock AI identifier
    └── Views/
        ├── RootTabView.swift         # TabView: Scan / Collection / Learn
        ├── ScanView.swift            # Camera + photo library entry points
        ├── CameraPicker.swift        # UIImagePickerController wrapper
        ├── StampDetailView.swift     # Value card, metadata, sections
        ├── CollectionView.swift      # Grid with totals, search, delete
        ├── LearnView.swift           # Reference topics
        └── Components/
            ├── RarityBadge.swift
            └── StampCardView.swift
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

1. Open Xcode → **File › New › Project › iOS › App**.
2. Name it `StampIdentifier`. Choose **SwiftUI** / **Swift** / iOS 17+.
3. Delete the stub `ContentView.swift` and `*App.swift` Xcode generated.
4. Drag the entire `StampIdentifier/` source folder from this repo into the
   Xcode project navigator. Check **"Copy items if needed"** and
   **"Create groups"**.
5. Make sure the asset catalog is added and `Info.plist` is set as the target's
   Info file (or let Xcode auto-generate from build settings and add the two
   usage strings manually).

## Swapping the mock identifier for a real one

`Services/StampIdentificationService.swift` defines the `StampIdentifying`
protocol. `MockStampIdentificationService` is the default wired into
`ScanView`. Replace it with a type that calls your preferred backend (Core ML
model, Vision framework, Anthropic Claude vision API, etc.) — the rest of the
UI needs no changes.

## Requirements

- Xcode 15+
- iOS 17+ deployment target (uses `NavigationStack`, `PhotosPicker`, and
  `ScrollView` pin-to-safe-area bottom bar)

## License

MIT
