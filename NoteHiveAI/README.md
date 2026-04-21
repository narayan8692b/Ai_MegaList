# NoteHive AI

An iOS note-taking app that records audio, transcribes it into text, and uses on-device heuristics to generate a **summary**, **bullet points**, **flash cards**, and a **multiple-choice quiz** from each recording.

Built with **SwiftUI**, `AVFoundation` (recording + playback), and `Speech` (transcription in 50+ locales).

## Features

- Audio capture with live level meter and elapsed time display
- Speech-to-text transcription via Apple's on-device `SFSpeechRecognizer`
- Automatic post-processing into:
  - Summary
  - Bullet points
  - Flash cards (Q/A, tap to flip)
  - Multiple-choice quiz with scoring
- 50+ language picker with search
- Searchable, sortable recordings list
- Per-recording playback with scrub bar
- Copy / Share any generated section
- Dark UI matching the reference design

## Requirements

- Xcode 16 or later
- iOS 17+ deployment target
- A real device is recommended for microphone + speech recognition testing

## Running

1. Open `NoteHiveAI/NoteHiveAI.xcodeproj` in Xcode.
2. Select an iPhone or iPad simulator (or a connected device) and press **Run**.
3. On first launch the app asks for microphone and speech-recognition permissions.

If the build system complains about synchronized folders on older Xcode versions, regenerate the project with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd NoteHiveAI
xcodegen generate
```

The `project.yml` at the repo root configures the target identically.

## Project Structure

```
NoteHiveAI/
├── NoteHiveAI.xcodeproj/          Xcode project (synchronized folder groups)
├── project.yml                    XcodeGen spec (optional alternative build)
└── NoteHiveAI/
    ├── NoteHiveAIApp.swift        SwiftUI entry point
    ├── Info.plist                 Microphone + speech permissions
    ├── Models/                    Recording, FlashCard, QuizQuestion, Language
    ├── Services/                  AudioRecorder, AudioPlayer, Storage, Transcription, AI
    ├── ViewModels/                RecordingsStore, AppSettings
    ├── Views/                     List, Recorder sheet, Detail, Flash cards, Quiz, Language picker, Settings
    └── Resources/Assets.xcassets  App icon, accent color
```

## Swapping in the Claude API

`AIService` produces summaries, bullets, flash cards, and quizzes offline.
To upgrade to Claude, replace the body of `AIService.analyze(transcription:)`
with a call to the Anthropic SDK and parse the JSON response into the same
`Analysis` struct.
