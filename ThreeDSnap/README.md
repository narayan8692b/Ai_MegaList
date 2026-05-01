# 3D Snap — iOS Swift App

A SwiftUI iOS app that scans rooms in 3D and turns them into floor plans with
dimensions, modeled after the "3D Snap: Measure Tape Tool" concept seen on the
App Store.

## Features

- **Room Scan** — uses Apple's `RoomPlan` framework on LiDAR devices to capture
  a 3D model of the room while you walk around it.
- **3D Viewer** — interactive SceneKit view with three modes that match the
  reference UI: **View** (isometric), **Top View**, and **Floor Plan**.
- **Floor Plan** — generated 2D plan with per-room area labels, total area pill,
  and dimension lines on all four sides (matching the second reference screenshot).
- **AR Measure** — tap two points on any surface to get an instant distance,
  toggleable between meters and feet.
- **Library** — saved scans with rename, search, swipe-to-delete, and share.
- **Settings** — default unit, haptics, auto-save, and supported export formats
  (PDF / USDZ / PNG / OBJ).
- **Persistence** — scans persist as JSON in the Documents directory.

## Tech

- SwiftUI (iOS 16+)
- ARKit + SceneKit for live measure
- RoomPlan for room capture (iPhone Pro / iPad Pro with LiDAR)
- Swift Canvas for floor-plan rendering
- `@AppStorage` + `JSONEncoder` for persistence
- iOS Deployment Target: **16.0**

## Project layout

```
ThreeDSnap/
├── ThreeDSnap.xcodeproj
└── ThreeDSnap/
    ├── ThreeDSnapApp.swift
    ├── Info.plist
    ├── Views/
    │   ├── RootView.swift          # tab bar
    │   ├── HomeView.swift          # hero + tools grid + recent scans
    │   ├── LibraryView.swift       # saved scans list
    │   ├── RoomScannerView.swift   # RoomPlan capture
    │   ├── MeasureView.swift       # AR ruler
    │   ├── ScanDetailView.swift    # View / Top View / Floor Plan toolbar
    │   ├── ScanSceneView.swift     # SceneKit room renderer
    │   ├── FloorPlanView.swift     # 2D Canvas plan with dimensions
    │   └── SettingsView.swift
    ├── Models/Scan.swift
    ├── Persistence/ScanStore.swift
    ├── Scanner/RoomScannerCoordinator.swift
    ├── Scanner/MeasureSession.swift
    └── Resources/Assets.xcassets   # app icon (cube on indigo)
```

## Running

1. Open `ThreeDSnap/ThreeDSnap.xcodeproj` in Xcode 15+.
2. Select your team in *Signing & Capabilities*.
3. Pick a real device (LiDAR for full room scanning, any A12+ for AR measure).
4. Build & run.

> RoomPlan and ARKit features only work on physical devices, not the simulator.
> The simulator will still show the app UI, library, and saved-scan viewer.
