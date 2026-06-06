# DocScanner (PWA)

A CamScanner-style document scanner that runs entirely in the browser as an installable
Progressive Web App. Capture pages with the camera, auto-detect document edges, correct
perspective, apply enhancement filters, run OCR, organize into folders, and export to PDF
or JPG — all offline, with everything stored locally on-device.

This web app is the Progressive Web App sibling of the DocScanner Kotlin Multiplatform
(KMM) app and deliberately mirrors its architecture and domain model so the two stay
mentally aligned.

---

## Features

- **Camera capture** via `getUserMedia`, plus import from the gallery / file picker.
- **Automatic edge detection** and **perspective correction** ("deskew" to a flat page).
- **Manual corner adjustment** when auto-detection is imperfect.
- **Enhancement filters**: Original, Magic Color, Black & White, Grayscale, High Contrast.
- **Multi-page documents** — append, reorder, and re-filter pages.
- **OCR** (text recognition) powered by Tesseract.js; extracted text is searchable.
- **Organization**: folders, tags, favorites, and full-text search across documents.
- **Export**: combine pages into a **PDF** or export a page as **JPG**, then download or
  share via the Web Share API.
- **Dark mode** with light / dark / system themes (Material-3-inspired tokens).
- **PIN lock** to gate access to the app on shared devices.
- **Installable & offline-first** — works as a standalone app with a service worker.

---

## Tech stack

- **React 18** + **TypeScript** (strict mode) + **Vite 6**
- **react-router-dom 6** for routing
- **vite-plugin-pwa** (Workbox) for the service worker, manifest, and runtime caching
- **idb** for IndexedDB access (documents, pages, blobs, settings)
- **tesseract.js** for in-browser OCR
- **jsPDF** for PDF generation; Canvas APIs for image processing and JPG export

No UI component library — styling is hand-rolled CSS custom properties for a small,
fast bundle.

---

## Architecture

The codebase follows a layered, dependency-inverted design mirroring the KMM app. UI code
depends only on **interfaces** (the Repository / Service pattern); concrete implementations
are wired together at a single composition root.

```
domain/      Pure models + service & repository interfaces (no platform code).
  models.ts        Document, Page, Folder, Tag, AppSettings, ScanFilter, ThemeMode, ...
  services.ts      DocumentRepository, FolderRepository, SettingsRepository,
                   CameraService, ImageProcessor, OcrEngine, PdfService, ShareService, ...

data/        Persistence layer — IndexedDB via `idb`.
  db.ts, *RepositoryImpl.ts, createDataLayer.ts
  Stores documents/pages metadata and image Blobs; requests persistent storage.

services/    Cross-cutting service implementations + the composition root.
  impl/            Camera, ImageProcessor, Ocr, Pdf, Share implementations.
  container.ts     The `Services` interface (the contract the UI consumes).
  container.impl.ts  `createServices()` — the ONLY module importing both data + services.

app/         App-wide React infrastructure.
  ServicesProvider.tsx   Builds `Services` once, exposes it via `useServices()`.
  theme.ts               ThemeProvider / useTheme — resolves LIGHT/DARK/SYSTEM.

ui/          Presentation.
  components/   BottomNav, LockGate, ...
  screens/      Home, Scan, CornerAdjustment, Filter, Documents, DocumentDetail,
                FolderDetail, Search, Settings.
  scan/         ScanSessionProvider — shared in-progress scan session state.

styles/global.css   Design tokens (color, elevation, shape, motion), reset, components.
App.tsx             Root: ServicesProvider → ThemeProvider → Router → LockGate → routes.
main.tsx            createRoot + global styles + service-worker registration.
```

**Data flow:** `domain` (contracts) ← `data` (IndexedDB) + `services` (impls) →
`container.impl` assembles a `Services` object → `ServicesProvider` exposes it →
`ui` screens consume it through `useServices()`. The dependency arrow always points at
the domain interfaces, never the other way around.

### Routes

| Path                | Screen                  | Notes                          |
| ------------------- | ----------------------- | ------------------------------ |
| `/`                 | HomeScreen              | Bottom nav                     |
| `/scan`             | ScanScreen              | Immersive (no bottom nav)      |
| `/scan/adjust`      | CornerAdjustmentScreen  | Immersive                      |
| `/scan/filter`      | FilterScreen            | Immersive                      |
| `/documents`        | DocumentsScreen         | Bottom nav                     |
| `/documents/:id`    | DocumentDetailScreen    |                                |
| `/folders/:id`      | FolderDetailScreen      |                                |
| `/search`           | SearchScreen            |                                |
| `/settings`         | SettingsScreen          | Bottom nav                     |

The `/scan/*` routes are wrapped in `ScanSessionProvider`, which owns the shared,
not-yet-persisted scan session (captured pages, corners, filters) across the flow.
Screens are code-split with `React.lazy` + `Suspense` to keep the initial bundle small.

---

## How the scanning pipeline works on the web

- **Camera** — `navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })`
  streams into a `<video>`; a still frame is grabbed onto a `<canvas>` to produce a Blob.
  Gallery import uses a hidden `<input type="file" accept="image/*">`.
- **Edge detection / perspective correction** — implemented with Canvas/typed-array image
  processing (heavy work runs in a Web Worker to keep the UI responsive). The four detected
  corners are stored **normalized** (0..1) so they survive image resizes, then used to warp
  the page to a flat rectangle.
- **Filters** — pixel transforms over the image data (thresholding for B&W, contrast/
  saturation curves for Magic Color, etc.).
- **OCR** — Tesseract.js loads a WASM core and a language `traineddata` file on demand and
  recognizes text off the processed image. Results (full text + blocks) are stored on the
  page/document and indexed for search.
- **PDF / JPG export** — jsPDF assembles processed page images into a PDF at the chosen
  quality; JPG export re-encodes a single page via Canvas. Files are saved with a download
  link or shared through the Web Share API where available.

---

## Getting started

Requires Node 18+ (Node 20+ recommended).

```bash
npm install        # install dependencies
npm run dev        # start the Vite dev server (http://localhost:5173)
npm run build      # type-check (tsc -b) + production build to dist/
npm run preview    # serve the production build locally
npm run typecheck  # type-check only
npm run lint       # ESLint
```

> Camera access requires a **secure context**. `localhost` counts as secure for dev; any
> other host must be served over **HTTPS**.

### App icons

The manifest references `public/icons/icon-192.png` and `icon-512.png`. The source
artwork is `public/icons/icon.svg` (and `public/favicon.svg`); the PNG raster sizes are
generated separately by the maintainer from that SVG.

---

## PWA & offline behavior

- The service worker (vite-plugin-pwa, `registerType: 'autoUpdate'`) precaches the app
  shell (JS/CSS/HTML/SVG/PNG/fonts) so the app loads offline after the first visit.
- Tesseract's WASM core and language data are **not** precached (they're large); they're
  fetched on demand and cached at runtime (`CacheFirst`, `ocr-assets` cache). The first
  OCR run therefore needs a network connection.
- All user data — documents, pages, image Blobs, settings — lives in **IndexedDB** on the
  device. Nothing is uploaded; there is no backend.
- On startup the app requests **persistent storage** to reduce the chance of automatic
  eviction.
- A small banner notifies you when the app is **ready offline** or when an **update** is
  available (tap *Reload* to activate the new version).
- Install it from the browser's "Install app / Add to Home Screen" prompt for a
  standalone, full-screen experience.

---

## Known web limitations

The web platform is more constrained than native iOS/Android. Be aware of the following:

- **iOS storage eviction (~7 days).** On iOS/iPadOS, data for web apps that aren't used
  for roughly **7 days** may be evicted by the system, even with persistent-storage
  requested (which Safari largely ignores). Treat the web app as best-effort local storage
  on iOS and **export important documents** (PDF) to keep them safe.
- **No iCloud / native cloud sync.** There is no web API for iCloud. Cross-device sync would
  require a custom backend; this app is local-only by design.
- **OCR is slower and less accurate.** Tesseract.js (WASM) is meaningfully slower and
  generally less accurate than native ML Kit (Android) / Vision (iOS) text recognition,
  especially on low-quality scans or non-Latin scripts. The first run also downloads the
  language model.
- **No reliable Background Sync on iOS.** The Background Sync / Periodic Background Sync
  APIs are unsupported on iOS Safari and unreliable elsewhere, so deferred work (e.g.
  uploading later) cannot be guaranteed.
- **Limited password-protected PDF.** Client-side PDF encryption via jsPDF is limited
  (weak/legacy encryption at best) and should not be relied on for strong security.
- **Camera quirks.** Live-camera capture depends on `getUserMedia`, requires HTTPS, and
  resolution/torch/focus controls vary widely by device and browser. iOS only allows the
  camera in Safari-based contexts.
- **Web Share API gaps.** Sharing files (`navigator.canShare({ files })`) isn't available
  in every browser; the app falls back to a plain download when sharing isn't supported.
- **Memory limits.** Very large multi-page scans can hit per-tab memory limits, particularly
  on mobile Safari; processing happens in-memory on the device.
