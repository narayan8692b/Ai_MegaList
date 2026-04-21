# Bumpi — Baby Heartbeat Monitor

A SwiftUI iOS app that lets expectant parents listen for and record their baby's heartbeat using the device microphone. Inspired by the App Store listing *Baby Heartbeat Monitor: Bumpi*.

> ⚠️ **Not a medical device.** Bumpi is for comfort and bonding only. It does not replace prenatal care. Consult a doctor or midwife for medical questions.

## Features

- **Tutorial onboarding** — 4-page swipeable intro explaining what the app does and its limitations.
- **Baby profile** — Name and due date captured on first launch, persisted in `UserDefaults`.
- **Live countdown** — Home screen shows `Meeting <name> in Xd Yh Zm`, updated every minute.
- **One-touch recording** — Full-screen recorder with live waveform meter and elapsed timer.
- **Approximate BPM detection** — `HeartbeatDetector` extracts peaks from the microphone amplitude envelope and estimates BPM in the 80–200 range.
- **Recordings library** — Saved clips listed on home screen with date, duration, detected BPM, play/pause, share (via `UIActivityViewController`), and delete.
- **In-app playback** — `AudioPlayer` drives a progress bar on the active row.
- **Settings** — Edit baby name/due date or reset the profile.

## Project layout

```
Bumpi/
├── Bumpi.xcodeproj/
└── Bumpi/
    ├── BumpiApp.swift              # App entry (@main)
    ├── Info.plist                  # NSMicrophoneUsageDescription, portrait-only
    ├── Assets.xcassets/            # AppIcon + AccentColor
    ├── Preview Content/
    ├── Theme/
    │   └── Theme.swift             # Colors, gradients, button styles
    ├── Models/
    │   ├── BabyProfile.swift       # Profile + BabyProfileStore + DueDateCountdown
    │   └── Recording.swift         # HeartbeatRecording value type
    ├── Services/
    │   ├── AudioRecorder.swift     # AVAudioRecorder wrapper + metering
    │   ├── AudioPlayer.swift       # AVAudioPlayer wrapper
    │   ├── HeartbeatDetector.swift # Peak-based BPM estimator
    │   └── RecordingStore.swift    # Disk-backed recording index
    ├── Components/
    │   ├── BabyIllustrationView.swift  # Stylized SF-Symbol illustration
    │   ├── WaveformView.swift          # Live + static waveform views
    │   └── RecordingRow.swift          # Row with play/share/delete
    └── Views/
        ├── RootView.swift          # Tutorial → Onboarding → Home router
        ├── TutorialView.swift
        ├── OnboardingView.swift
        ├── HomeView.swift
        ├── RecordingView.swift
        └── SettingsView.swift
```

## Requirements

- Xcode 15 or later
- iOS 16+ deployment target
- Physical iPhone recommended for microphone recording (the simulator has no real mic input)

## Build & run

1. Open `Bumpi/Bumpi.xcodeproj` in Xcode.
2. Select the `Bumpi` scheme.
3. Set a development team under **Signing & Capabilities** if deploying to a device.
4. Run (⌘R).

On first launch the app will:

1. Walk the user through the tutorial.
2. Ask for a baby name + due date.
3. Land on the home screen. Tap **Start Listening** — iOS will prompt for microphone permission.

## Notes on heartbeat detection

The detector in `HeartbeatDetector.swift` is a **UI feedback approximation**, not a clinical measurement. It:

1. Reads average power via `AVAudioRecorder.averagePower(forChannel:)` every 50 ms.
2. Normalizes to 0–1.
3. Detects local peaks above a dynamic threshold (1.5× recent average + 0.08 floor).
4. Rejects peaks outside the plausible inter-beat interval (300–750 ms).
5. Averages the last several valid intervals to produce a BPM estimate.

A production app would use the accelerometer or an ultrasonic Doppler peripheral for real fetal heart rate measurement.

## Privacy

- Microphone permission is requested only when the user initiates a recording.
- Audio is stored as `.m4a` files in the app's Documents directory.
- Nothing is uploaded anywhere.
