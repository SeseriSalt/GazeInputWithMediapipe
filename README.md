# IrisEyeGlance — Eye Glance Input Interface

An iOS research app for hands-free text entry. The front camera tracks the face with
MediaPipe Iris; the nose tip moves a cursor over a 4×4 character panel, and a **wink** or a
quick **glance toward a screen corner** (an "Eye Glance") selects the character.

![Sample](https://github.com/SeseriSalt/GazeInputWithMediapipe/assets/103529116/161a3427-6455-4876-a152-a72a6d5d8147)

## Features

- Japanese (gojūon) and English (alphabet) input panels, switchable with the 🌐 key or in Settings
- Wink selects the first character of a row, a glance toward one of the four corners selects the others
- Automatic calibration of the glance thresholds, plus manual sliders for every threshold
- Typing experiment mode: random characters are presented and the input accuracy is reported
- CSV logging of every frame (waveforms, thresholds, events) for offline analysis
- Debug overlay with the live detector state

## Requirements

| Item | Value |
|---|---|
| Xcode | 16 or later (tested with Xcode 27) |
| iOS | 17.0 or later, iPhone only, portrait |
| Device | A physical arm64 iPhone. `SYIris.framework` has no simulator slice, so the app cannot run in the simulator. |
| Tests | `swift test` on macOS 14 or later |

## Getting started

1. Clone the repository. `sources/Iris/SYIris.framework` (the MediaPipe Iris tracker, ~80 MB) is checked in, so no extra download is needed to build.
2. Open `IrisEyeGlance.xcodeproj`, select your team under *Signing & Capabilities*, choose your iPhone and run.
3. On first launch allow camera access. Hold the phone about 30 cm from your face.

### Operation

- Move the blue cursor with the tip of your nose and rest it on a panel cell.
- **Wink** to enter the cell's first character (あ, か, … or a, d, …).
- **Glance** toward a corner of the screen and back to enter one of the other characters shown in the four hint bubbles.
- Drag the panel to move it, double-tap it to cycle through three sizes.
- Toolbar: **Reset** (restart the experiment and detectors), **Record** (start / stop CSV logging), **Calibration**, **Settings**, **Debug** (overlay, also toggled by a long press).

### Calibration

1. Press *Calibration*, then *Start*, and stare at the ＋ for about 5 seconds. Press *Next*.
2. Press *Start* again and glance toward each arrow as it appears, pressing *Next* after each one (8 arrows).
3. The computed glance threshold and integral multiplier are saved and shown in Settings. Press *閉じる* to return.

### Recording

*Record* writes `Documents/yyyyMMdd_HHmmss.csv` with one row per tracked frame (about 30 rows per second
while a face is visible). Columns include the frame number, entered character, selected region, gesture
event, eyelid differences, depth, wink and glance waveform values with their thresholds, integrated areas
and iris / head motion. The files are reachable from the Files app (*On My iPhone › IrisEyeGlance*) and
from Finder.

## Project layout

```
IrisEyeGlance/                 iOS app (UIKit, UI built in code)
  Camera.swift                   AVCaptureSession on a dedicated queue
  TrackerBridge.swift            Feeds frames to SYIris, forwards landmarks
  FrameProcessor.swift           Runs the core pipeline off the main thread
  MainViewController.swift       The input screen
  SettingsViewController.swift   Thresholds and input mode
  UI/                            Panel, cursor, status, debug and calibration views
Packages/IrisEyeGlanceCore/    Local Swift package, pure logic, no UIKit
  Landmarks/                     Face mesh indices, normalisation
  Features/                      Eyelid / iris features, depth estimation, filters
  Detection/                     Blink, wink and glance detectors, thresholds, pipeline
  Input/                         Keyboard layouts, region resolver, text composer, experiment
  Calibration/                   Calibration state machine
  Recording/                     CSV recorder
  Presentation/                  View models for the panel, feedback and calibration UI
  Tests/                         Swift Testing suites
sources/Iris/SYIris.framework  Prebuilt MediaPipe Iris tracker (arm64)
docs/REFACTORING_PLAN.md       Design notes behind the current structure
```

Data flow: `Camera → TrackerBridge → FrameProcessor → MainViewController → UI`.

## Development

### Tests

All detection, input and calibration logic lives in the package and is tested with synthetic
waveforms, so no device is needed:

```sh
cd Packages/IrisEyeGlanceCore
swift test
```

The same suite runs in GitHub Actions (`.github/workflows/tests.yml`). It also validates the
project configuration (Info.plist keys, privacy manifest, deployment target).

### Building without a signing identity

```sh
xcodebuild -project IrisEyeGlance.xcodeproj -scheme IrisEyeGlance \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

### Rebuilding `SYIris.framework`

The tracker is a thin Objective-C wrapper around MediaPipe's iris tracking graph, built with Bazel
from the `simple_iris_framework` branch of
[SeseriSalt/mediapipe](https://github.com/SeseriSalt/mediapipe/tree/simple_iris_framework/mediapipe/develop/iris)
(`SYIris.h`, `SYIris.mm`, `info.plist`).

```sh
export BAZEL_VERSION=5.2.0
curl -fLO "https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-darwin-x86_64.sh"
# in the mediapipe checkout
bazel build --config=ios_fat --define 3D=true mediapipe/develop:HandTracker
```

Unzip the archive produced in `bazel-bin/mediapipe/develop/` and replace `sources/Iris/SYIris.framework`.

Reference: https://qiita.com/noppefoxwolf/items/99cb1da63c093f668d71
