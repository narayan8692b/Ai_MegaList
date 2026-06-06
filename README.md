# DocScanner

> A cross-platform (Android + iOS) document scanner built with Kotlin Multiplatform Mobile and Compose Multiplatform — capture, auto-detect edges, perspective-correct, enhance, OCR, organize, export and sync your documents.

<!-- Badges placeholder -->
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green)
![Kotlin](https://img.shields.io/badge/Kotlin-2.1.20-purple)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Features

- **Smart capture & scanning**
  - Live camera capture (CameraX on Android, AVFoundation on iOS) and gallery import.
  - **Automatic edge / document boundary detection** with a manual **corner-adjustment** step.
  - **Perspective correction** (de-skew / warp) to produce a flat, rectangular page.
  - Multi-page scan sessions with reordering.
- **Image enhancement filters**
  - `Original`, `Magic Color`, `Black & White`, `Grayscale`, `High Contrast`.
- **OCR (text recognition)**
  - Google ML Kit Text Recognition on Android, Apple Vision on iOS.
  - Per-page extracted text concatenated for **full-text search** across titles, tags and OCR content.
- **Organization**
  - Folders (nestable), tags, favorites, and search.
- **Export & sharing**
  - Multi-page **PDF generation** (optionally password-protected), single-page JPG export,
    `.txt` OCR-text export, and native share-sheet integration.
- **Security**
  - App lock via biometric / PIN, encrypted storage for sensitive data, optional locked documents.
- **Cloud sync**
  - Pluggable cloud providers (Google Drive / iCloud) with per-document sync status.
- **Performance targets**
  - Edge detection under ~2s on low-end devices.
  - Memory-efficient PDF generation that streams pages (100+ page documents).
  - All heavy image work runs off the main thread.

---

## Architecture overview

DocScanner is a **Kotlin Multiplatform Mobile (KMM)** project that follows **Clean Architecture**
with an **MVVM** presentation layer, the **Repository** pattern for data access, **Koin** for
dependency injection, **Coroutines + Flow** for async/reactive streams, **SQLDelight** for the local
database, and **Compose Multiplatform** for shared UI.

```
                +-------------------------------------------------+
                |                  Presentation                   |
                |   Compose Multiplatform UI + ViewModels (MVVM)  |
                +-------------------------------------------------+
                                      |
                                      v
                +-------------------------------------------------+
                |                    Domain                        |
                |  Models  ·  Use cases  ·  Repository interfaces  |
                |          Platform interfaces (expect-style)      |
                +-------------------------------------------------+
                          |                         |
                          v                         v
        +---------------------------+   +-----------------------------------+
        |          Data             |   |        Platform (actual)          |
        |  Repository impls         |   |  ImageProcessor / OcrEngine /     |
        |  SQLDelight · Ktor        |   |  PdfGenerator / FileStorage /     |
        |  Settings · mappers       |   |  Camera / Security / providers    |
        +---------------------------+   +-----------------------------------+
                          |                         |
                          +-----------+-------------+
                                      v
                        +-------------------------------+
                        | Android actuals | iOS actuals |
                        +-------------------------------+
```

### Layer breakdown

- **Domain** (`shared/.../domain`) — pure Kotlin, no platform deps.
  - `model/` — immutable data models (`Document`, `Page`, `ScanSession`, `DocumentCorners`,
    `ScanFilter`, `Folder`, `Tag`, `OcrResult`, `AppSettings`, …).
  - `usecase/` — single-responsibility use cases (`SaveScanUseCase`, `ProcessPageUseCase`,
    `DetectEdgesUseCase`, `GeneratePdfUseCase`, `SearchDocumentsUseCase`, `CreateFolderUseCase`, …).
  - `repository/` — repository **interfaces** (`DocumentRepository`, `FolderRepository`, …).
  - `platform/` — platform-capability **interfaces** (`ImageProcessor`, `OcrEngine`,
    `PdfGenerator`, `FileStorage`, `IdGenerator`, `TimeProvider`, camera/security/cloud), implemented
    per-platform via Kotlin `expect`/`actual`.
  - `util/DataResult.kt` — `DataResult.Success/Failure`, the `AppError` taxonomy and
    `runCatchingResult` helper used to model failures without throwing across boundaries.
- **Data** (`shared/.../data`) — repository implementations backed by SQLDelight (local DB),
  Ktor (cloud clients) and multiplatform-settings (preferences); model ↔ entity mappers.
- **Presentation** (`shared/.../presentation` + Compose) — ViewModels and shared Compose UI.
- **Platform actuals** — Android (`androidMain`) and iOS (`iosMain`) implementations of the
  platform interfaces, plus thin host apps in `androidApp/` and `iosApp/`.

### The corner-adjustment / scanning flow

```
Camera Capture
      |
      v
Auto Edge Detection      (ImageProcessor.detectEdges -> normalized DocumentCorners, or .FULL)
      |
      v
Corner Adjustment        (user drags the 4 corners on the captured image)
      |
      v
Perspective Correction   (ImageProcessor.perspectiveCorrect using the chosen corners)
      |
      v
Filters                  (ImageProcessor.applyFilter: Magic Color / B&W / Grayscale / …)
      |
      v
Save                     (SaveScanUseCase: OCR each page, concatenate text, persist Document)
```

`ProcessPageUseCase` encapsulates *perspective-correct → apply-filter*; `SaveScanUseCase`
finalizes a `ScanSession` into a persisted `Document`, running OCR per page and concatenating the
text for search.

---

## Code sharing

DocScanner targets roughly **85–90% shared code**. Everything except OS-specific image processing,
camera, OCR, file IO, security and rendering lives in the shared module — including the UI, thanks
to Compose Multiplatform.

| Concern | Shared (commonMain) | Platform-specific (android/iosMain) |
|---|---|---|
| Domain models & use cases | Yes | — |
| Repository interfaces & implementations | Yes | — |
| Local database (SQLDelight schema & queries) | Yes | Driver (Android/native) only |
| Networking (Ktor) | Yes | Engine (OkHttp/Darwin) only |
| ViewModels & navigation | Yes | — |
| UI (Compose Multiplatform) | Yes | Host wiring only |
| DI graph (Koin modules) | Yes | Platform module bindings |
| Image processing (edge detect / warp / filters) | Interface | Canvas+ColorMatrix / Core Image · Vision |
| OCR | Interface | ML Kit / Apple Vision |
| PDF generation | Interface | `PdfDocument` / `UIGraphicsPDFRenderer` |
| Camera capture | Interface | CameraX / AVFoundation |
| File storage & sharing | Interface | Android FS / iOS FS |
| Security (biometric / encryption) | Interface | androidx.biometric+security-crypto / Keychain+LocalAuth |
| Id / time providers | Interface | UUID / clock per platform |

---

## Project structure

```
DocScanner/
├── androidApp/                 # Android host application
│   └── src/
│       ├── main/               # Android entry point & manifest (platform team)
│       └── test/               # JVM unit tests (ExampleUnitTest)
├── iosApp/                     # iOS host application (Xcode project)
├── shared/                     # Kotlin Multiplatform shared module
│   ├── build.gradle.kts
│   └── src/
│       ├── commonMain/kotlin/com/docscanner/shared/
│       │   ├── domain/         # models · usecase · repository · platform · util
│       │   ├── data/           # repository impls, db, network, settings
│       │   └── presentation/   # ViewModels + Compose UI
│       ├── commonTest/kotlin/com/docscanner/shared/
│       │   ├── fake/           # in-memory fakes (Fakes.kt)
│       │   ├── domain/         # GeometryTest, ScanFilterTest
│       │   └── usecase/        # use-case tests (Turbine + coroutines-test)
│       ├── androidMain/        # Android actuals
│       └── iosMain/            # iOS actuals
├── gradle/libs.versions.toml   # Version catalog
├── .github/workflows/          # CI (ci.yml) + Release (release.yml)
├── docs/ARCHITECTURE.md        # Deeper architecture documentation
├── LICENSE                     # MIT
└── README.md
```

---

## Build & run

### Prerequisites

- **JDK 17** (Temurin recommended)
- **Android SDK 35** (compileSdk/targetSdk 35, minSdk 26)
- **Xcode 15+** (for the iOS app; macOS only)
- A recent **Gradle** is provided via the wrapper (`./gradlew`).

### Android

```bash
# Install & launch the debug build on a connected device / emulator
./gradlew :androidApp:installDebug

# Or just assemble the APK
./gradlew :androidApp:assembleDebug
```

### iOS

```bash
# Build & embed the shared framework for Xcode
./gradlew :shared:embedAndSignAppleFrameworkForXcode
```

Then open `iosApp/iosApp.xcodeproj` in Xcode and run on a simulator or device (signing required for
physical devices).

### Running tests

```bash
# Shared multiplatform unit tests (commonTest, runs on the Android/JVM unit-test target)
./gradlew :shared:testDebugUnitTest

# All shared targets' tests (where supported)
./gradlew :shared:allTests

# Android app unit tests
./gradlew :androidApp:testDebugUnitTest

# Android lint
./gradlew :androidApp:lintDebug
```

The shared test suite uses `kotlin-test`, `kotlinx-coroutines-test` (`runTest`), **Turbine** for
Flow assertions, and `koin-test`. Tests rely on deterministic in-memory fakes (see
`shared/src/commonTest/.../fake/Fakes.kt`) so ids, timestamps and output paths are fully predictable.

---

## Tech stack & versions

| Area | Library / Tool | Version |
|---|---|---|
| Language | Kotlin (Multiplatform) | 2.1.20 |
| Android Gradle Plugin | `com.android.application/library` | 8.7.3 |
| UI | Compose Multiplatform | 1.7.3 |
| DI | Koin (core / compose / viewmodel) | 4.0.2 |
| Async | kotlinx-coroutines | 1.9.0 |
| Serialization | kotlinx-serialization-json | 1.7.3 |
| Date/time | kotlinx-datetime | 0.6.1 |
| Local DB | SQLDelight | 2.0.2 |
| Networking | Ktor client | 3.0.3 |
| Settings | multiplatform-settings | 1.3.0 |
| Logging | Napier | 2.7.1 |
| Camera (Android) | CameraX | 1.4.1 |
| OCR (Android) | ML Kit Text Recognition | 16.0.1 |
| Security (Android) | androidx.biometric / security-crypto | 1.1.0 / 1.1.0-alpha06 |
| Testing | kotlin-test / coroutines-test | 2.1.20 / 1.9.0 |
| Testing | Turbine | 1.2.0 |
| Testing | JUnit (Android) | 4.13.2 |
| Android SDK | compileSdk / targetSdk / minSdk | 35 / 35 / 26 |

---

## Security notes

- Sensitive preferences and (optionally) document data are stored using platform-encrypted storage
  (`androidx.security-crypto` / Keychain).
- App lock is available via biometric authentication or a PIN; individual documents can be marked
  **locked**.
- PDFs can be exported with an owner/user password (`GeneratePdfUseCase(..., password = ...)`).

## Cloud-sync notes

- Each `Document` carries a `SyncStatus` (`LOCAL_ONLY`, `PENDING_UPLOAD`, `SYNCING`, `SYNCED`,
  `ERROR`).
- Cloud providers are abstracted behind an interface and selected via `AppSettings.cloudProvider`
  (`NONE`, `GOOGLE_DRIVE`, `ICLOUD`). Ktor backs the network layer.

## Known simplifications / TODOs

- **Edge detection** uses a heuristic; it falls back to `DocumentCorners.FULL` when no confident
  quadrilateral is found. A more robust contour-based detector is planned.
- **PDF encryption** is currently a thin password pass-through; stronger encryption options are TODO.
- **Cloud clients** are stubbed/abstracted; concrete Google Drive / iCloud sync engines are still in
  progress.
- Full `xcodebuild` of the iOS host app requires code-signing and is therefore not part of CI (CI
  only compiles the shared iOS framework sources).

---

## License

Released under the [MIT License](LICENSE). © 2026 DocScanner.
