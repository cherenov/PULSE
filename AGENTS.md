# AGENTS.md — PULSE

Biomedical & astronaut telemetry monitoring cross-platform application built with Flutter, Riverpod, Drift (SQLite), and `fl_chart`.

---

## 1. Tech Stack & Key Packages
- **Framework:** Flutter (Dart, null-safety)
- **State Management:** `flutter_riverpod` (`NotifierProvider`, `StreamProvider.autoDispose`, `family`)
- **Local Database:** `drift` + `drift_flutter` (SQLite, UTC timestamps)
- **Charts:** `fl_chart` (custom multi-zone segmented lines, dashed thresholds, sparklines)
- **Audio / Feedback:** Text-to-Speech (`ttsServiceProvider`)

---

## 2. Project Structure
- `lib/main.dart` — App entry point and theme initialization
- `lib/home_screen.dart` — Main `PageView` navigation, `FloatingBottomNavBar`, and TTS hooks
- `lib/common/models/nav_item.dart` — Navigation destination model
- `lib/common/widgets/floating_bottom_nav_bar.dart` — Custom floating navigation bar
- `lib/core/database/db.dart` — Drift database definition, queries, streams, and batch operations
- `lib/core/database/db.g.dart` — Generated Drift code (regenerate via `build_runner` if schema changes)
- `lib/core/database/db_tables.dart` — `Profiles`, `ProfileSettings`, `Measurements` tables
- `lib/core/database/db_providers.dart` — Riverpod providers wrapping `Db` streams
- `lib/core/database/metrics_registory.dart` — Single source of truth for all `MetricDef` thresholds, limits, and units
- `lib/core/tts/tts_provider.dart` — Text-to-speech service provider
- `lib/features/dashboard/` — Overview cards per `MetricGroup` (pushes `IndicatorsGroupScreen`)
- `lib/features/indicators/` — Group lists, `IndicatorListTile` (with sparklines), `IndicatorDetailScreen`, `IndicatorChart`
- `lib/features/add_metrics/` — Manual measurement input & validation against `MetricDef.limits`
- `lib/features/settings/` — Profile & app preferences
- `lib/features/debug/` — `TelemetryGenerator` (wave-based synthetic data) & DB reset tools
- `lib/theme/app_colors.dart` — Semantic status colors (`ok`, `warning`, `critical`) & dark cockpit surfaces
- `lib/theme/theme.dart` — App `ThemeData` configuration

---

## 3. Core Architectural Rules & Conventions

### Metrics Registry (`lib/core/database/metrics_registory.dart`)
- **Never hardcode medical thresholds, units, or decimal precisions in UI widgets.** Always read from `MetricDef` via `metrics` or `metricsById`.
- Multi-field metrics (e.g., `bp` with `SYS`/`DIA`, `bp_ext` with 4 arm pressures, `alt_ast` with `ALT`/`AST`) store values in `v0..v3` columns of `Measurements`.
- Status evaluation (`MetricStatus.ok`, `MetricStatus.warning`, `MetricStatus.critical`) is strictly determined by `MetricDef.fieldStatus()` and `MetricDef.status()`.
- Always format numbers in UI with `metric.format(value)` and round stored floats with `double.parse(val.toStringAsFixed(metric.decimals))` to avoid IEEE-754 floating-point tails.

### Database & Riverpod Performance (`db.dart` & `db_providers.dart`)
- **Timestamps:** Store all `takenAt` values in **UTC** (`.toUtc()`); convert to local time (`.toLocal()`) only in the presentation layer.
- **Avoid unbounded queries in list views:**
  - Use `latestAllProvider` (`watchAllLatest`) for dashboards and group overview lists.
  - Use `recentIndicatorHistoryProvider` (`watchRecent(..., limit: 16)`) for card sparklines instead of loading full history.
  - Use `seriesProvider` (`watchRange`) for time-bounded detail charts (`7D`, `30D`, `90D`, `1Y`).
- **Batch writes:** Bulk inserts (such as `TelemetryGenerator`) must use `db.batch((batch) => batch.insertAll(...))`.
- If `db.dart` or `db_tables.dart` is modified, regenerate Drift files:
  `dart run build_runner build --delete-conflicting-outputs`

### Navigation & PageView State (`home_screen.dart`)
- Top-level tabs use `PageView` synchronized with `selectedIndexProvider`.
- Every tab screen inside `PageView` must remain wrapped in `_KeepAlivePage` (`AutomaticKeepAliveClientMixin`) so swiping between screens does not dispose active Drift streams or rebuild state.
- Secondary drill-downs (e.g., tapping a category card on `DashboardScreen` -> `IndicatorsGroupScreen` -> `IndicatorDetailScreen`) must use `Navigator.of(context).push(...)` so hardware/system back gestures pop routes cleanly instead of exiting the app.

### Charts & Visual Design (`indicator_chart.dart` & `indicator_list_tile.dart`)
- **Color semantics:** `AppColors.ok` (normal), `AppColors.warning` (caution/review), `AppColors.critical` (critical).
- **Multi-field charts:** Render all fields on a shared real-value Y-axis using **Overlay + field focus**:
  - Highlight only the active `selectedField` (full opacity, zone-colored segments, `warning`/`critical` glow via `Shadow`, `belowBarData` tint, and dashed normal/critical threshold lines with right-axis labels).
  - Render non-focused fields as thin, muted context lines (`alpha: ~0.28`).
  - Keep lines clean without point markers (`FlDotData(show: false)`).
- Wrap list-item sparklines in `RepaintBoundary` and set `duration: Duration.zero` on `LineChart` to maintain 60/120 FPS scrolling.

---

## 4. Verification Workflow
Before finishing any task:
1. Run static analysis and ensure zero errors or warnings: `flutter analyze`
2. Verify that generated files (`*.g.dart`) are up to date if database schemas changed.
3. Keep commits atomic and scoped to the feature being modified.