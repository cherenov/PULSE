# PULSE — Space Health Anomaly Detection System

**PULSE** is a 100% offline-first Flutter application designed for astronauts operating in microgravity environments. Developed for the NASA Space Apps Challenge, PULSE monitors vital telemetry, detects physiological anomalies, and provides immediate, reliable text-to-speech (TTS) voice feedback—all without requiring an active internet connection.

---

## Key Features

- **Microgravity-Optimized UI/UX**: Portrait-first mobile layout with adaptive support, large touch targets, and low-friction ergonomics designed for floating/microgravity use.
- **100% Offline Architecture**: Zero cloud dependencies to ensure operational reliability during deep-space communications blackouts.
- **Voice Feedback Engine**: Instant offline speech feedback integrated via Riverpod for critical notifications, alerts, and navigation actions.
- **Local Telemetry Store**: On-device SQLite measurements via Drift, with dashboard stats, indicator history, and a risk detector over blood, urine, tracker, and eye-health biomarkers.
- **Sensor-ready telemetry (alpha)**: Designed to ingest live readings from connected sensors. Automatic collection is currently under testing; manual entry remains available as a fallback and for development.

---

## Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod 3.x](https://riverpod.dev)
- **Local Database**: [Drift](https://drift.simonbinder.eu) (SQLite)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Audio / TTS**: `flutter_tts` (configured with deterministic offline initialization)
- **Design System**: Custom dark-theme Sci-Fi palette with high-contrast UI components

### Project Structure

```text
lib/
├── common/             # Shared UI widgets (Navigation Bars)
│   ├── models/
│   └── widgets/
├── core/               # App-wide infrastructure
│   ├── database/       # Drift schema, providers, metric registry
│   ├── risk_detector/  # Physiological risk rules
│   └── tts/            # Offline TTS service and Riverpod provider wrapper
├── features/           # Feature-based domain modules
│   ├── add_metrics/
│   ├── dashboard/
│   ├── debug/
│   ├── indicators/
│   └── settings/       # Profile, preferences and About PULSE
└── theme/              # Colors, sizes, and Material theme
```

---

## Data Input Status

PULSE is designed to receive telemetry from connected sensors, for example over MQTT or Bluetooth depending on the mission configuration. Automatic sensor ingestion is currently **alpha/planned** and remains under testing.

In the current build:

- **Add record** handles manual readings and is primarily intended for fallback and development/debug scenarios.
- **Debug mode** generates synthetic telemetry so dashboards, charts, risk detection and voice feedback can be exercised without sensor hardware.

---

## Debug Mode (Development Only)

The Debug tab is hidden by default and is not persisted across app restarts.

### Unlock and hide

- Tap **Settings** five times quickly. The tap counter resets after two seconds without a tap.
- Long-press **Settings** to show or hide Debug mode. Unlocking opens the Debug tab; hiding it returns to Settings if Debug is open.

### Random telemetry generator

The **Random** button opens a dialog with these controls:

| Control | Range | Default |
| --- | --- | --- |
| Period | 7–60 days | 30 days |
| Warning chance | 0–60% | 15% |
| Critical chance | 0–40% | 5% |
| Clear existing data first | on/off | on |

Readings are generated every **6 hours** for every registered metric. The generator creates smooth, episode-based anomalies:

- normal episodes last 4–11 samples;
- warning episodes last 3–6 samples;
- critical episodes last 2–4 samples;
- one field per episode carries the anomaly; other fields stay in their normal range;
- values are smoothed, clamped to the metric's allowed limits, and rounded to the configured precision.

Generation inserts a single batch for the active profile and reports the number of measurements created. At the current registry size, a 30-day run produces roughly 2,760 measurements.

### Data tools

- **Clear database** deletes all measurements for the active profile after confirmation. Profiles and settings are not removed.
- The debug metric list shows total records and metric count, supports **Add Random** for a single synthetic measurement (or **Add First Measurement** when empty), and groups records by blood, urine, non-invasive and ocular metrics.
- Each metric expands to show its records; values and timestamps can be edited, and records can be swiped left to delete.
- The top of the screen lists **Confirmed clinical risks** and **Risk suspicions** produced by the latest values, with the metrics that triggered them.

> Debug and generated data are for development and demonstration only. Never use synthetic or test readings for health decisions or mission planning.

---

## Getting Started

### Prerequisites

- **Flutter SDK**: stable channel
- **Dart SDK**: `^3.13.5` or higher
- **Android Studio / Xcode** (for device deployment and native bindings)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/cherenov/pulse.git
   cd pulse
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## Contributing & Git Workflow

We follow a lightweight **GitHub Flow** branching model. Direct commits to `main` are restricted to maintain core stability.

### Branch Conventions

- `setup/` or `chore/` — Project foundation, dependencies, and core configuration (`setup/core-architecture`).
- `feature/` — New end-user features or screens (`feature/dashboard`).
- `fix/` — Bug fixes and crash resolutions (`fix/tts-android-init`).
- `refactor/` — Internal code restructuring without behavioral changes.

### Development Steps

1. Pull the latest state from `main`:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Create your working branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit your changes and push to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```
4. Open a **Pull Request (PR)** targeting `main` and request a review from the Lead Architect.

---

## License

Copyright 2026 PULSE Team

Licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
See the `LICENSE` file in the repository for the full terms.
