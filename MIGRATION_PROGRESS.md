# Flutter Migration Progress Tracker

## Phase 1: Project Setup & Dependencies
- [x] Create Flutter project in `apps/desktop/` (via `flutter create`)
- [x] Add pubspec dependencies (file_picker, shared_preferences, path_provider, window_manager)
- [x] Configure Linux runner for frameless window (gtk_window_set_decorated=FALSE)
- [x] Create `.desktop` file for Linux integration

## Phase 1.5: Binary Handling (System PATH approach)
- [x] Simplify `binary_manager.dart` to use system PATH (`which` command) — matches Python's `shutil.which()`
- [x] Fallback paths: `/usr/bin`, `/usr/local/bin`, `~/.local/bin`
- [x] Remove bundled binary asset declarations from `pubspec.yaml`
- [x] Replace `fetch-binaries.sh` with `scripts/install-deps.sh` (pip + apt)
- [x] Create `apps/desktop/flatpak-manifest.json` (KDE runtime + pip3 yt-dlp)
- [x] Update `scripts/build.sh` to check for system deps
- [x] Update `linux/CMakeLists.txt` (app name: tuberip, ID: com.kevelino.tuberip)
- [x] Clean up empty/stub `assets/binaries/` directory

## Phase 2: Backend Migration
- [x] Create `app.dart` (app entry + theme)
- [x] Implement `core/constants.dart` (colors, sizes, strings)
- [x] Implement `core/theme.dart` (cyber-cyan dark theme)
- [x] Implement `core/utils.dart` (path expansion, byte formatting, speed parsing)
- [x] Implement `models.dart` (DownloadConfig, DownloadItem, Mode enum)
- [x] Implement `downloader.dart` (yt-dlp subprocess, command builder, pause/resume/cancel)
- [x] Implement `binary_manager.dart` (system PATH resolution, dependency verification)
- [x] Implement `settings_service.dart` (SharedPreferences wrapper)
- [x] Implement `download_manager.dart` (ChangeNotifier queue management)

## Phase 3: UI Implementation
- [x] Design cyber-cyan dark theme
- [x] Implement custom `TitleBar` with window controls (minimize/maximize/close)
- [x] Implement `UrlInput` with clear button and keyboard handling
- [x] Implement `ModeSelector` (video/audio toggle)
- [x] Implement `QualitySelector` (quality dropdown + audio format)
- [x] Implement `OutputSelector` with native file_picker folder browser
- [x] Implement `DownloadListItem` with progress bar, status icons, control buttons
- [x] Implement `MainScreen` (sidebar navigation + main content layout)
- [x] Implement `SettingsDialog` (audio quality, subtitles, metadata, rate limit)
- [x] Implement `HelpDialog` (summary, feature list, keyboard shortcuts)

## Phase 4: Integration & Features
- [x] Implement keyboard shortcuts (Ctrl+S settings, Ctrl+/ help, Enter download)
- [x] Wire up state management (ChangeNotifier for DownloadManager)
- [x] Window dragging via window_manager
- [x] Settings persistence via SharedPreferences
- [x] Frameless window on Linux (GTK decorated=FALSE)
- [x] Window title and controls (close/minimize/maximize)

## Phase 5: Build & Distribution
- [x] `flutter pub get` — works (dependencies resolved)
- [x] `flutter analyze` — **0 errors, 0 warnings**
- [x] `flutter build linux --release` — **builds successfully**
- [x] Flatpak manifest for CI/CD
- [x] CI/CD workflow updated with `build-flutter-flatpak` job

## Binary Handling Approach

**Decision: Use system PATH (no bundled binaries)**

Aligned with the Python/PySide6 codebase — yt-dlp and ffmpeg are resolved from system PATH:

| Aspect | Python/PySide6 | Flutter |
|--------|----------------|---------|
| yt-dlp | pip3 install (Flatpak manifest) | pip3 install (Flatpak manifest) |
| ffmpeg | KDE runtime (Flatpak) | KDE runtime (Flatpak) |
| Path resolution | `shutil.which()` | `which` via `Process.runSync` |
| Fallback paths | N/A | `/usr/bin`, `/usr/local/bin`, `~/.local/bin` |

Key files:
- `lib/services/binary_manager.dart` — resolves binaries from system PATH
- `lib/backend/downloader.dart` — `checkDependencies()` verifies binaries work
- `scripts/install-deps.sh` — installs yt-dlp (pip) + ffmpeg (apt)
- `flatpak-manifest.json` — installs yt-dlp via pip3, relies on KDE runtime for ffmpeg

## Notes
- User must run `flutter pub get` before building (resolves Dart dependencies)
- User must have yt-dlp and ffmpeg installed on the system (or via Flatpak)
- `fontFamily: 'Inter'` in TextStyle falls back to Roboto (Material default) if Inter isn't installed
