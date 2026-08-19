# Flutter Migration Progress Tracker

## Phase 1: Project Setup & Dependencies
- [x] Create Flutter project in `apps/desktop/` (via `flutter create`)
- [x] Add pubspec dependencies (file_picker, shared_preferences, path_provider, window_manager)
- [x] Configure Linux runner for frameless window (gtk_window_set_decorated=FALSE)
- [x] Create `.desktop` file for Linux integration

## Phase 2: Backend Migration
- [x] Create `app.dart` (app entry + theme)
- [x] Implement `core/constants.dart`
- [x] Implement `core/theme.dart` (cyber-cyan dark theme)
- [x] Implement `core/utils.dart` (path expansion, byte formatting, speed parsing)
- [x] Implement `models.dart` (DownloadConfig, DownloadItem, Mode enum)
- [x] Implement `downloader.dart` (yt-dlp/ffmpeg subprocess management)
- [x] Implement `binary_manager.dart` (system PATH resolution, matches Python's shutil.which)
- [x] Implement `settings_service.dart` (SharedPreferences wrapper)
- [x] Implement `download_manager.dart` (queue management, pause/resume/cancel)

## Phase 3: UI Implementation
- [x] Design cyber-cyan dark theme
- [x] Implement custom `TitleBar` with window controls (minimize/max/close)
- [x] Implement `UrlInput` with clear button and keyboard handling
- [x] Implement `ModeSelector` (video/audio toggle)
- [x] Implement `QualitySelector` (quality dropdown + audio format)
- [x] Implement `OutputSelector` with native file_picker folder browser
- [x] Implement `DownloadListItem` with progress bar, status icons, control buttons
- [x] Implement `MainScreen` (sidebar + main content layout)
- [x] Implement `SettingsDialog` (audio quality, subtitles, metadata, rate limit)
- [x] Implement `HelpDialog` (summary, feature list, keyboard shortcuts)

## Phase 4: Integration & Features
- [x] Implement keyboard shortcuts (Ctrl+S settings, Ctrl+/ help, Enter download)
- [x] Wire up state management (ChangeNotifier for DownloadManager)
- [x] Window dragging via window_manager
- [x] Settings persistence via SharedPreferences
- [x] Binary resolution via system PATH (matching Python codebase)

## Phase 5: Build & Distribution
- [ ] Install system dependencies: `scripts/install-deps.sh`
- [ ] Run `flutter pub get` in `apps/desktop/`
- [ ] Build: `flutter build linux --release` or `scripts/build.sh`
- [x] Create Flatpak manifest (`apps/desktop/flatpak-manifest.json`)
- [x] Update CI/CD workflow with Flutter Flatpak build job

## Binary Handling Approach

**Decision: Use system PATH (no bundled binaries)**

Aligned the Flutter approach with the existing Python/PySide6 codebase:

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
- Cannot run `flutter pub get` in this environment (no network access for pub packages)
- User must run `flutter pub get` manually to resolve dependencies
- The `fontFamily: 'Inter'` in TextStyle falls back to Roboto (Material default)
