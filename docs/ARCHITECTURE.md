# DocScanner — Architecture

This document expands on the high-level overview in the [README](../README.md) and describes the
internal structure, conventions and rationale of the DocScanner codebase.

## Goals

1. **Maximize code sharing (~85–90%)** across Android and iOS while keeping platform-specific code
   small, explicit and replaceable.
2. **Keep the domain pure** — no Android/iOS/framework types leak into `domain`, so business logic is
   trivially unit-testable on the JVM.
3. **Fail without throwing** across coroutine/platform boundaries via a single `DataResult` type.
4. **Deterministic, fast tests** — all platform capabilities are interfaces that can be faked.

## Module & dependency direction

```
presentation  ─────────────►  domain  ◄─────────────  data
   (UI, VMs)                 (models,                (repository impls,
                              use cases,              SQLDelight, Ktor,
                              interfaces)             settings)
                                  ▲
                                  │ implements (actual)
                                  │
                         platform actuals
                       (androidMain / iosMain)
```

Dependencies point **inward** toward the domain. The domain depends on nothing platform-specific; it
declares *interfaces* (`repository/`, `platform/`) that outer layers implement. This is classic
Clean Architecture dependency inversion.

## Clean Architecture layers

### Domain (`shared/src/commonMain/.../domain`)

Pure Kotlin. Subpackages:

- **`model/`** — immutable `data class`/`enum` types. Notable:
  - `Geometry.kt`: `PointF` and `DocumentCorners` (normalized `0f..1f` coordinates, `@Serializable`,
    `DocumentCorners.FULL`, `fromList`/`toList`). Normalization keeps corners valid across resizes.
  - `ScanFilter`: the five enhancement filters with display names.
  - `ScanSession`/`ScanPage`: the in-memory state of an active multi-page scan.
  - `CapturedImage`: a raw capture before it becomes a `Page`.
  - `Document`/`Page`: the persisted result; `Document.ocrText` is the concatenation of every page's
    text for full-text search.
  - `OcrResult`/`OcrBlock`/`BoundingBox`, `Folder`, `Tag`, `SyncStatus`, `AppSettings`/`PdfQuality`.
- **`usecase/`** — each use case is a small class with an `operator fun invoke`. Examples:
  - `DetectEdgesUseCase`, `ProcessPageUseCase` (perspective-correct → filter), `ApplyFilterUseCase`.
  - `SaveScanUseCase` — orchestrates per-page processing + OCR + persistence.
  - `GeneratePdfUseCase`, `ExportJpgUseCase`, `ExportOcrTextUseCase`, `ShareFileUseCase`.
  - `SearchDocumentsUseCase`, `GetDocumentsUseCase`, `CreateFolderUseCase`, etc.
- **`repository/`** — data-access interfaces returning `Flow` for observation and `DataResult` for
  mutations (`DocumentRepository`, `FolderRepository`, `SettingsRepository`, `SyncRepository`).
- **`platform/`** — capability interfaces fulfilled by `actual` implementations: `ImageProcessor`,
  `OcrEngine`, `PdfGenerator`, `FileStorage`, `MediaCapture`, `SecurityPlatform`, `CloudStorageClient`,
  and the small `IdGenerator` / `TimeProvider` / `PlatformInfo` providers.
- **`util/DataResult.kt`** — see below.

### Data (`shared/src/commonMain/.../data`)

Implements the repository interfaces. Backed by **SQLDelight** for local persistence (the
`DocScannerDatabase` schema in `com.docscanner.shared.database`), **Ktor** for cloud clients, and
**multiplatform-settings** for preferences. Mappers convert between DB rows and domain models.

### Presentation (`shared/src/commonMain/.../presentation` + Compose)

**MVVM**: ViewModels expose immutable UI state as `StateFlow` and accept intents/events; shared
**Compose Multiplatform** screens render that state on both platforms. Hosts (`androidApp`, `iosApp`)
provide only the entry point and any platform chrome.

### Platform actuals (`androidMain` / `iosMain`)

Concrete implementations of the `platform/` interfaces using OS APIs (CameraX & ML Kit & PdfDocument
on Android; AVFoundation & Vision & UIGraphicsPDFRenderer on iOS), plus the SQLDelight driver and
Ktor engine for each platform.

## Error handling: `DataResult` & `AppError`

Instead of throwing across suspend/platform boundaries, the codebase uses:

```kotlin
sealed interface DataResult<out T> {
    data class Success<T>(val data: T) : DataResult<T>
    data class Failure(val error: AppError) : DataResult<Nothing>
}
```

with helpers `getOrNull()`, `map`, `onSuccess`, `onFailure`, and the `runCatchingResult { }` bridge
for code that may throw. `AppError` is a sealed taxonomy (`Storage`, `Network`, `Ocr`,
`PdfGeneration`, `Camera`, `Auth`, `NotFound`, `Unknown`). Use cases translate failures into the
appropriate `AppError` subtype (e.g. `GeneratePdfUseCase` returns `AppError.PdfGeneration` for an
empty document).

## Concurrency

Coroutines + Flow throughout. Repositories expose `Flow` streams (`observeDocuments`,
`searchDocuments`, …); use cases return `DataResult` from suspend functions. Heavy image work runs on
background dispatchers per the `ImageProcessor` contract. Tests drive everything via
`kotlinx.coroutines.test.runTest` and assert Flow emissions with **Turbine**.

## Dependency injection

**Koin** wires the graph. The shared module defines the common Koin modules (use cases, repositories,
ViewModels); each platform contributes a module binding the `actual` platform implementations and the
SQLDelight driver / Ktor engine. `koin-test` is available for verifying module definitions.

## Testing strategy

- **Location:** `shared/src/commonTest` — runs as multiplatform tests (executed on the JVM/Android
  unit-test target in CI via `:shared:testDebugUnitTest`).
- **Fakes:** `fake/Fakes.kt` provides deterministic in-memory implementations of every interface a
  use case needs (`FakeImageProcessor`, `FakeOcrEngine`, `FakePdfGenerator`, `FakeFileStorage`,
  `FakeDocumentRepository`, `FakeFolderRepository`, `FixedIdGenerator`, `FixedTimeProvider`). The
  repository fakes are backed by `MutableStateFlow`, so observation can be asserted with Turbine.
- **Determinism:** fixed ids (`"$prefix-0"`, `-1`, …), fixed timestamps and predictable derived
  paths (`"<path>.corrected"`, `"<path>.<FILTER>"`, `"/exports/file0.pdf"`) make assertions exact.
- **Coverage:** geometry & serialization round-trips, filter enum invariants, the
  perspective→filter ordering and failure propagation in `ProcessPageUseCase`, full `SaveScanUseCase`
  persistence/ordering/OCR-concatenation, search filtering, folder creation, and PDF/OCR export paths
  (including the empty-document failure).

## CI/CD

GitHub Actions (`.github/workflows/`):

- **`ci.yml`** (push & PR):
  - `build-shared` (ubuntu): JDK 17 + Android SDK + Gradle cache → `:shared:testDebugUnitTest`,
    `:shared:compileKotlinMetadata`, `:androidApp:assembleDebug`, `:androidApp:testDebugUnitTest`.
  - `lint-android` (ubuntu): `:androidApp:lintDebug`.
  - `build-ios` (macOS): `:shared:compileKotlinIosSimulatorArm64` — compiles the Kotlin/Native iOS
    framework sources without a booted simulator. A full `xcodebuild` needs code-signing and is out of
    scope for CI.
- **`release.yml`** (tag push `v*`): builds and uploads a release APK artifact.

Gradle caching uses `gradle/actions/setup-gradle@v4`; workflows declare `permissions: contents: read`.

## Known simplifications / TODOs

- Edge detection is heuristic and falls back to `DocumentCorners.FULL`.
- PDF "encryption" is a password pass-through; stronger schemes are TODO.
- Cloud sync clients are abstracted/stubbed pending concrete provider engines.
