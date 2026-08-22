# TubeRip

Linux-first desktop app for downloading YouTube videos or extracting audio.
Built with **Flutter**, **yt-dlp**, and **ffmpeg**.

## Download

Grab the latest **AppImage** from [GitHub Releases](https://github.com/kevelino/tuberip/releases) (tags `v*`).

```bash
chmod +x TubeRip-*-x86_64.AppImage
./TubeRip-*-x86_64.AppImage
```

yt-dlp and ffmpeg are bundled in the AppImage.

## Features

- Video (MP4) and audio (mp3 / m4a) modes
- Quality presets: best, 1080, 720, 480
- Sequential download queue with live progress, speed, and ETA
- Pause / resume (Linux) and cancel
- Browser cookies or cookies.txt
- Optional subtitles, embed thumbnail & metadata
- Persistent settings
- Brand accent `#0FE5F4` from the TubeRip logo

## Requirements (development)

- [Flutter](https://docs.flutter.dev/get-started/install/linux) 3.13+
- yt-dlp and ffmpeg on `PATH` (or use the AppImage, which bundles them)

```bash
cd apps/desktop
./scripts/install-deps.sh
```

## Development

```bash
git clone https://github.com/kevelino/tuberip.git
cd tuberip/apps/desktop
flutter pub get
flutter run -d linux
```

## Project structure

```
tuberip/
├── apps/desktop/          # Flutter Linux desktop app (source of truth)
│   ├── lib/               # UI, services, yt-dlp command builder
│   ├── scripts/           # install-deps.sh, build-appimage.sh
│   ├── test/
│   └── README.md
├── .github/workflows/     # CI + AppImage release on tags v*
└── README.md
```

## Testing

```bash
cd apps/desktop
flutter analyze
flutter test
```

## Building

```bash
cd apps/desktop
flutter build linux --release
./scripts/build-appimage.sh
# → dist/TubeRip-<version>-x86_64.AppImage
```

## Architecture

Flutter spawns `yt-dlp` via `dart:io` `Process`. ffmpeg is invoked by yt-dlp for merge / audio extract. See [`apps/desktop/README.md`](apps/desktop/README.md).

## Migration note

The former PySide6 / Python UI (`src/tuberip`) has been removed. Stack is Flutter-only. Historical notes: [`MIGRATION.md`](MIGRATION.md).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
