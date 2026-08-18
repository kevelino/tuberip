# Changelog

All notable changes to TubeRip will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-08-18

### Added
- Initial MVP release
- Video and audio download modes
- Quality selection for video (`best`, `1080`, `720`, `480`)
- Audio format and quality selection (`mp3`, `m4a`, `best`; VBR 0–9)
- Optional subtitle download with language selection
- Download queue with live progress bars
- Dependency check for `yt-dlp` and `ffmpeg`
- Output folder browser
- Qt stylesheet for cross-DE theming
- Threaded downloads via `QThread`
- PyInstaller build scripts
