# Ruum — AI Interior Design (iOS / SwiftUI)

A SwiftUI clone of the "AI Interior Design: Ruum" iPad/iPhone app:
upload a photo of any room, pick a style, and get a reimagined render
with a before/after comparison and history of past designs.

## Features

- **Four design modes**: Interior restyle, Empty Room fill-in, Exterior
  refresh, Remove Objects.
- **Room picker**: Living Room, Bedroom, Kitchen, Bathroom, Dining, Home
  Office, Study, Gaming Room, Kids Room, Garden, Backyard, Exterior.
- **12 design styles** (Modern, Minimalist, Industrial, Scandinavian,
  Bohemian, Coastal, Mid-Century, Farmhouse, Japandi, Art Deco, Tropical,
  Luxury) with generated palette previews.
- **Photo input** via PhotosUI `PhotosPicker`.
- **Generate flow** with animated progress.
- **Before/After slider** on the result screen, plus save-to-Photos, share
  sheet, and "Reimagine" regeneration.
- **History** of every generated design, persisted to the app's Documents
  directory.
- **Settings** tab with app info and library stats.

## Requirements

- Xcode 15+
- iOS 16.0+
- Swift 5.9

## Project layout

```
RuumApp/
├── project.yml                   # XcodeGen spec (optional)
└── RuumApp/
    ├── Info.plist
    ├── RuumApp.swift             # @main App entry
    ├── Theme.swift               # Colors, layout, button styles
    ├── Assets.xcassets/
    ├── Models/
    │   ├── Room.swift
    │   ├── DesignStyle.swift
    │   ├── DesignMode.swift
    │   └── Design.swift
    ├── Services/
    │   ├── AIDesignService.swift # Plug-in point for remote AI backends
    │   └── DesignStorage.swift   # Persists designs + images
    └── Views/
        ├── RootTabView.swift
        ├── HomeView.swift
        ├── InteriorDesignView.swift
        ├── DesignResultView.swift
        ├── HistoryView.swift
        ├── DiscoverView.swift
        ├── SettingsView.swift
        └── Components/
            ├── PhotoPicker.swift
            ├── ModeTile.swift
            ├── RoomChip.swift
            ├── StyleCard.swift
            ├── BeforeAfterSlider.swift
            └── SectionHeader.swift
```

## Generating the Xcode project

### Option A: XcodeGen (recommended)

```bash
brew install xcodegen
cd RuumApp
xcodegen generate
open RuumApp.xcodeproj
```

### Option B: Manual

1. In Xcode: **File → New → Project → iOS App**, name it `RuumApp`,
   language Swift, interface SwiftUI, bundle id `com.ruum.RuumApp`,
   deployment target iOS 16.0.
2. Delete the auto-generated `ContentView.swift` and `RuumAppApp.swift`.
3. Drag the `RuumApp/` folder from this repo into the project (check
   "Copy items if needed", add to target `RuumApp`).
4. Replace Info.plist with the one provided (or copy its keys —
   specifically `NSPhotoLibraryUsageDescription` and
   `NSCameraUsageDescription`).
5. Build & run.

## Hooking up a real AI backend

`AIDesignService` ships with a `LocalAIDesignService` that applies a
Core Image pipeline keyed to the selected style — enough to demo the UX
without any network calls.

To swap in a real model, implement `AIDesignGenerating` and assign it to
`AIDesignService.remote`:

```swift
final class ReplicateDesignService: AIDesignGenerating {
    func generate(from image: UIImage, room: Room, style: DesignStyle, mode: DesignMode) async throws -> UIImage {
        // 1. POST the image + a prompt like
        //    "A \(style.name) \(room.name), \(style.tagline)"
        //    to your endpoint of choice (Replicate `adirik/interior-design`,
        //    OpenAI Images edits, Stability img2img, etc.)
        // 2. Poll/stream the result, decode the returned image.
        // 3. Return it as a UIImage.
        fatalError("Implement me")
    }
}

// In RuumApp.swift or a DI container:
// designService.remote = ReplicateDesignService()
```

## Roadmap ideas

- Mask-based "Remove Objects" using Vision + generative inpainting.
- On-device Stable Diffusion via Core ML for fully offline generation.
- Inspiration feed + save-style collections.
- In-app purchase paywall for unlimited generations.
