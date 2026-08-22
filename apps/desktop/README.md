# TubeRip Desktop (Flutter)

Linux-first YouTube downloader powered by **yt-dlp** and **ffmpeg**.

## Download

Grab the latest **AppImage** from [GitHub Releases](https://github.com/kevelino/tuberip/releases) (tag `v*`).

```bash
chmod +x TubeRip-*-x86_64.AppImage
./TubeRip-*-x86_64.AppImage
```

yt-dlp and ffmpeg are bundled inside the AppImage.

## Prerequisites (dev / from source)

| Tool | Role |
|------|------|
| [Flutter](https://docs.flutter.dev/get-started/install/linux) 3.13+ | Build / run the UI |
| **yt-dlp** | Downloads and format selection |
| **ffmpeg** | Merge video+audio, extract MP3, embed thumbnails |

Install deps (Fedora / Debian / Arch helpers):

```bash
./scripts/install-deps.sh
```

Or manually:

```bash
# Fedora
sudo dnf install ffmpeg yt-dlp

# Debian/Ubuntu
sudo apt install ffmpeg
pipx install yt-dlp
```

## Run

```bash
cd apps/desktop
flutter pub get
flutter run -d linux
```

## Build

```bash
flutter build linux --release
# Binary: build/linux/x64/release/bundle/desktop
```

### AppImage (distribution)

```bash
./scripts/build-appimage.sh
# Output: dist/TubeRip-<version>-x86_64.AppImage
```

Requires `curl`. Downloads `appimagetool`, yt-dlp, and a static ffmpeg if missing.

## Features (MVP)

- Video (MP4) / audio (mp3, m4a) download
- Quality presets (best, 1080, 720, 480)
- Sequential download queue with live progress, speed, ETA
- Pause / resume (Linux SIGSTOP/SIGCONT) and cancel
- Browser cookies (Firefox/Chrome/…) or cookies.txt
- Subtitles, embed thumbnail & metadata
- Persistent settings
- Brand accent `#0FE5F4` from the TubeRip logo

## How yt-dlp / ffmpeg integrate

Flutter does **not** link yt-dlp as a plugin. The app spawns `yt-dlp` via `dart:io` `Process.start`, streams stdout for progress, and lets yt-dlp invoke **ffmpeg** for merge/extract (`--ffmpeg-location` when a custom path is set).

Bundled AppImage binaries are discovered next to the executable / via `$APPDIR`.

See `lib/services/binary_manager.dart` and `lib/backend/yt_dlp_command.dart`.

## Packaging notes

See [PACKAGING.md](PACKAGING.md) for AppImage / Flatpak / Windows prep.
