# Changelog

All notable changes to TubeRip will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-22

### Added
- Flutter Linux desktop app (`apps/desktop`) as the sole UI
- Video (MP4) and audio (mp3 / m4a) download modes via yt-dlp
- Quality presets: best, 1080, 720, 480
- Sequential download queue with live progress, speed, and ETA
- Pause / resume (Linux) and cancel
- Browser cookies or cookies.txt; optional subtitles; embed thumbnail & metadata
- Persistent settings and dependency check
- AppImage packaging with bundled yt-dlp and ffmpeg
- GitHub Actions release workflow on tags `v*`

### Removed
- PySide6 / Python desktop application (`src/tuberip`)
- PyInstaller packaging scripts

## [0.1.0] - 2024-08-18

### Added
- Initial MVP (Python / PySide6 era)
- Video and audio download modes
- Quality selection and download queue
- Dependency check for `yt-dlp` and `ffmpeg`
