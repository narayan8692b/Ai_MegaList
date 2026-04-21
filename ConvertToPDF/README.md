# Convert to PDF

A SwiftUI iOS app for creating, managing, and securing PDF documents from
files, photos, the camera, or a remote URL.

## Features

- **My Documents** — search, sort, and browse every PDF stored in the app
- **Create PDF from** — Files, Photo Gallery, Camera, URL, or any other
  document-provider app
- **Document viewer** — powered by `PDFKit` with continuous vertical scrolling
- **Document options** — Rename, Manage Pages, Share, Set Password, Delete
- **Manage Pages** — reorder pages via drag & drop, multi-select for bulk
  delete, append new pages from the gallery
- **Password protection** — encrypt PDFs with a user/owner password using
  `PDFKit` write options

## Project layout

```
ConvertToPDF/
├── ConvertToPDF.xcodeproj/
└── ConvertToPDF/
    ├── ConvertToPDFApp.swift        # App entry point
    ├── Models/PDFDocumentItem.swift # Document metadata model
    ├── Services/
    │   ├── DocumentStore.swift      # Persistent document index
    │   └── PDFManager.swift         # PDFKit-backed creation / editing
    ├── Utils/Theme.swift            # Shared colors + button styles
    └── Views/
        ├── DocumentListView.swift
        ├── SettingsView.swift
        ├── CreatePDFSheet.swift
        ├── CameraCaptureView.swift
        ├── DocumentDetailView.swift
        ├── DocumentOptionsSheet.swift
        ├── ManagePagesView.swift
        ├── RenameDocumentView.swift
        └── SetPasswordView.swift
```

## Requirements

- Xcode 15 or newer
- iOS 16 deployment target
- Swift 5

## Running

Open `ConvertToPDF/ConvertToPDF.xcodeproj` in Xcode and run the `ConvertToPDF`
scheme on an iOS 16+ simulator or device. No third-party dependencies.
