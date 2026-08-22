# Flutter Migration Plan: PySide6 → Flutter Desktop

> **Status (2026-08): complete.** The PySide6 / Python app (`src/tuberip`) has been removed.
> The source of truth is [`apps/desktop/`](apps/desktop/). This document is kept as historical reference.

## Former Architecture (Python/PySide6)

- **`src/tuberip/`** — Main package with:
  - `app.py` — QApplication bootstrap
  - `backend/downloader.py` — yt-dlp subprocess wrapper with pause/resume/cancel
  - `backend/models.py` — DownloadConfig, DownloadItem dataclasses
  - `ui/main_window.py` — MainWindow, DownloadWorker (QThread)
  - `ui/widgets.py` — SettingsDialog, URLInput, FormatSelector, SaveToRow, HelpDialog
  - `ui/download_item_widget.py` — Queue item row with pause/cancel buttons
  - `ui/styles.qss` — Dark cyber-cyan stylesheet

## Target Architecture (Flutter)

```
tuberip/
├── apps/
│   └── desktop/                    # Flutter project root
│       ├── pubspec.yaml            # Dependencies + asset declarations
│       ├── lib/
│       │   ├── main.dart           # Entry point
│       │   ├── app.dart            # App widget + theme
│       │   ├── core/
│       │   │   ├── constants.dart  # Colors, strings, sizes
│       │   │   ├── theme.dart      # Custom dark theme (cyber-cyan)
│       │   │   └── utils.dart      # Path expansion, string helpers
│       │   ├── backend/
│       │   │   ├── downloader.dart # yt-dlp subprocess wrapper
│       │   │   ├── models.dart     # DownloadConfig, DownloadItem, Mode
│       │   │   └── metadata.dart   # Title fetching
│       │   ├── ui/
│       │   │   ├── screens/
│       │   │   │   ├── main_screen.dart      # Main window with queue
│       │   │   │   └── settings_screen.dart  # Settings dialog
│       │   │   ├── widgets/
│       │   │   │   ├── url_input.dart
│       │   │   │   ├── format_selector.dart
│       │   │   │   ├── quality_selector.dart
│       │   │   │   ├── save_to_row.dart
│       │   │   │   ├── download_item.dart
│       │   │   │   ├── action_buttons.dart   # Window controls
│       │   │   │   └── help_dialog.dart
│       │   │   └── dialogs/
│       │   │       └── settings_dialog.dart
│       │   └── services/
│       │       ├── settings_service.dart     # SharedPreferences wrapper
│       │       ├── binary_manager.dart       # yt-dlp/ffmpeg asset extraction
│       │       └── tray_service.dart         # System tray (optional)
│       └── assets/
│           ├── binaries/
│           │   ├── yt-dlp                  # Bundled binary
│           │   └── ffmpeg                  # Bundled binary
│           ├── icons/
│           │   └── tuberip.svg
│           └── styles/
│               └── (none - handled by Flutter theme)
├── scripts/
│   └── fetch-binaries.sh         # Download yt-dlp/ffmpeg into assets/binaries/
└── tuberip.desktop                 # Desktop entry (reuse existing)
```

## Phase 1: Project Setup & Dependencies

1. **Create Flutter project**: `flutter create --platforms=linux --org=com.kevelino desktop` in `apps/`
2. **Add pubspec dependencies**:
   - `process` — for spawning yt-dlp/ffmpeg subprocesses
   - `path_provider` — for save directory defaults
   - `file_picker` — native folder browser dialog
   - `shared_preferences` — for settings persistence
   - `intl` — for formatted text (speed, ETA)
   - `window_manager` — frameless window with custom title bar
   - `provider` — state management
   - `google_fonts` — typography
   - `flutter_svg` — SVG icon rendering
3. **Asset declaration in `pubspec.yaml`**:
   ```yaml
   assets:
     - assets/icons/tuberip.svg
     - assets/binaries/yt-dlp
     - assets/binaries/ffmpeg
   ```
4. **Binary fetch script** (`scripts/fetch-binaries.sh`):
   - Download latest yt-dlp binary
   - Download latest ffmpeg binary (BtbN build or similar)
   - Place in `apps/desktop/assets/binaries/`

## Phase 2: Backend Migration

### `models.dart`
Translate Python dataclasses to Dart:
- `Mode` enum: `video`, `audio`
- `DownloadConfig`: mode, quality, audioFormat, audioQuality, subtitleLang, downloadSubtitles, embedThumbnail, embedMetadata, rateLimit, outputDir
- `DownloadItem`: url, title, status, progress, error, config

### `downloader.dart`
Replace subprocess wrapper:
- Use `dart:io` `Process` to spawn `yt-dlp` binary
- `fetchMetadata(url)` — `yt-dlp --dump-json` → parse stdout
- `download(item)` — yt-dlp subprocess with progress parsing
- `pause/resume` — SIGSTOP/SIGCONT via `ProcessSignal`
- `cancel` — `Process.kill()`
- `_parseSpeedInfo(line)` — same regex logic from Python port

**Key difference**: Dart's `Process.start()` + `stdout.listen()` for real-time progress instead of Python's `for line in proc.stdout`.

### `binary_manager.dart`
At app startup, copy yt-dlp/ffmpeg from assets to a writable location:
```dart
static Future<String> get ytDlpPath async {
  // Check system PATH first, fall back to bundled binary
  final systemPath = await _findInPath('yt-dlp');
  if (systemPath != null) return systemPath;
  return await _prepareBundledBinary('yt-dlp');
}

static Future<String> _prepareBundledBinary(String name) async {
  final supportDir = await getApplicationSupportDirectory();
  final dest = '${supportDir.path}/$name';
  if (!await File(dest).exists()) {
    final data = await rootBundle.load('assets/binaries/$name');
    await File(dest).writeAsBytes(data.buffer);
    await Process.run('chmod', ['+x', dest]);
  }
  return dest;
}
```

## Phase 3: Beautiful UI Design

### Overall Aesthetic
Retain the dark cyber-cyan theme (`#111113` background, `#11eef9` cyan accent) but enhance with Flutter's capabilities.

### Main Screen (`main_screen.dart`)
- **Custom title bar**: Gradient logo, window control buttons (minimize/maximize/close) with hover animations
- **Animated URL input**: Smooth focus transitions, hint text that slides, paste icon button
- **Format & Quality selector**: `SegmentedButton` or custom pill-shaped toggle buttons with hover animations
- **Download button**: Gradient background, loading spinner overlay, press-scale animation
- **Save-to row**: Folder picker via `file_picker`, path display with truncate/ellipsis
- **Live queue**: `ListView.builder` or `AnimatedList` for smooth item insertion/removal
- Each queue item: animated progress bar, status dot with pulse animation, pause/cancel buttons

### Queue Item (`download_item.dart`)
- **Animated status indicators**:
  - Dot that changes color with `AnimatedContainer` (yellow=queued, cyan=downloading with pulse, green=done, red=error)
  - Pause button toggles between ⏸ and ⏵ with `AnimatedSwitcher`
  - Cancel button morphs to 📁 on completion
- **Custom progress bar**: `CustomPainter` with gradient fill and smooth width animation
- **Speed info**: Real-time display with fade-in/out animations
- **Title display**: Fades from URL to actual video title

### Settings Dialog (`settings_dialog.dart`)
- Card-based layout with `ListTile` entries
- Audio quality slider with live preview label
- Subtitle toggle with expand/collapse animation
- Rate limit input with validation
- Embed thumbnail/metadata checkboxes with smooth check animations

### Help Dialog (`help_dialog.dart`)
- Card layout with `ExpansionTile` sections
- Icon buttons for each section
- Copyable content in `SelectableText`

## Phase 4: State Management

- **`ChangeNotifier`** classes:
  - `DownloadManager` — manages download list, pause/cancel, calls backend
  - `SettingsManager` — wraps SharedPreferences for settings persistence
  - `UrlInputModel` — form validation state
- Use `provider` package for state management
- Each download runs via `Process.start()` with `stdout.listen()` callbacks

## Phase 5: Keyboard Shortcuts

- **Enter**: Start download
- **Ctrl+S**: Open settings
- **Ctrl+Q**: Quit application
- **Ctrl+/** or **?**: Open help
- **Escape**: Close dialogs
- Implement via `Shortcuts` widget or `RawKeyboardListener`

## Phase 6: Build & Distribution

1. **Linux build**: `flutter build linux --release`
2. **AppImage**: Wrap Flutter output in AppImage using `appimage-builder`
3. **Flatpak**: Create manifest bundling Flutter app + yt-dlp/ffmpeg assets
4. **CI/CD**: Update `.github/workflows/release.yml` to build Flutter Linux binary + AppImage + Flatpak

## Key UI Enhancements Using Flutter Power

| Feature | Flutter Implementation |
|---------|----------------------|
| Smooth animations | `AnimatedContainer`, `AnimatedSwitcher`, `AnimatedCrossFade`, `AnimatedBuilder` |
| Custom title bar | `SizedBox` with `Row` + custom buttons + drag via `GestureDetector` |
| Gradient accents | `LinearGradient` shader masks on text and buttons |
| Progress bars | Custom `CustomPainter` with gradient fill |
| Status indicators | `AnimatedContainer` with color transitions + pulse via `AnimationController` |
| Hover effects | `MouseRegion` + `AnimatedDefaultTextStyle` |
| Loading states | `CircularProgressIndicator` with press-scale overlay |
| Dialog transitions | `showGeneralDialog` with custom page transitions |
| Typography | Google Fonts via `google_fonts` package |
| Icons | `Icon` widgets or SVG from `flutter_svg` |

## Migration Checklist

| Task | Status |
|------|--------|
| ✅ Plan created | — |
| ⬜ Create Flutter project in `apps/` |  |
| ⬜ Add pubspec dependencies |  |
| ⬜ Create asset directory with scripts/fetch-binaries.sh |  |
| ⬜ Implement models.dart |  |
| ⬜ Implement downloader.dart |  |
| ⬜ Implement binary_manager.dart |  |
| ⬜ Implement SettingsManager |  |
| ⬜ Design custom dark theme (cyber-cyan) |  |
| ⬜ Implement URLInput with animations |  |
| ⬜ Implement FormatSelector & QualitySelector |  |
| ⬜ Implement SaveToRow with file_picker |  |
| ⬜ Implement DownloadItem with pause/cancel animations |  |
| ⬜ Implement MainScreen with AnimatedList queue |  |
| ⬜ Implement SettingsDialog |  |
| ⬜ Implement HelpDialog |  |
| ⬜ Implement keyboard shortcuts |  |
| ⬜ Test download flow end-to-end |  |
| ⬜ Build AppImage |  |
| ⬜ Build Flatpak |  |
| ⬜ Update CI/CD workflows |  |
| ✅ Remove PySide6 codebase | Done — Flutter-only |

## Risks & Mitigations

1. **Risk**: Flutter desktop apps are larger (50-100MB+ vs ~20MB PyInstaller)
   **Mitigation**: Acceptable trade-off for cross-platform readiness and better UI

2. **Risk**: yt-dlp/ffmpeg can't be directly executed from Flutter assets
   **Mitigation**: Copy to `getApplicationSupportDirectory()` at startup (standard approach)

3. **Risk**: SIGSTOP/SIGCONT may not work on all platforms
   **Mitigation**: Only target Linux for now; use platform channels if needed later

4. **Risk**: Custom window dragging complexity
   **Mitigation**: Use `window_manager` package for reliable cross-platform window management

5. **Risk**: Long-running Dart `Process` stdout listening complexity
   **Mitigation**: Mirror the proven Python logic — `Process.start()` + `stdout.transform(utf8.decoder).listen()`

## Notes on yt-dlp/ffmpeg as `pubspec.yaml` Assets

Per your request, yt-dlp and ffmpeg binaries will be declared as assets in `pubspec.yaml` and bundled in `apps/desktop/assets/binaries/`. At runtime, they are extracted to the application support directory and made executable. This approach:

- **Guarantees the exact binaries are available** without requiring the user to install anything
- **Works in Flatpak/AppImage sandboxes** where system PATH access is limited
- **Falls back to system binaries** if they exist (for users who have yt-dlp/ffmpeg installed)
- **Keeps the app self-contained** — zero external dependencies for end users
