# TubeRip

Cross-distro Linux desktop app for downloading YouTube videos or extracting audio. Built with PySide6 and `yt-dlp`.

## Screenshot

> Screenshot placeholder — add a screenshot once available.

## Features

- Video and audio download modes
- Quality presets: `best`, `1080`, `720`, `480` for video; `mp3`, `m4a`, `best` for audio
- Audio quality selection (VBR 0–9)
- Optional subtitle download with language selection
- Download queue with live status and progress
- Dependency check on startup (`yt-dlp`, `ffmpeg`)
- Output folder browser with default `~/Downloads/YouTube`
- Qt stylesheet for consistent look across GNOME/KDE/XFCE
- Threaded downloads via `QThread` to keep the UI responsive
- PyInstaller packaging support for distribution as a single binary

## Requirements

- Python >= 3.9
- PySide6 >= 6.6
- yt-dlp >= 2024.1
- ffmpeg

## Development Setup

```bash
git clone https://github.com/kevelino/tuberip.git
cd tuberip
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
```

## Project Structure

```
tuberip/
├── src/tuberip/
│   ├── __init__.py
│   ├── app.py              # QApplication bootstrap, stylesheet, icon
│   ├── main.py             # Entry point
│   ├── backend/
│   │   ├── __init__.py
│   │   ├── models.py       # Mode enum, DownloadConfig, DownloadItem
│   │   └── downloader.py   # yt-dlp command builder, subprocess runner
│   └── ui/
│       ├── __init__.py
│       ├── main_window.py  # MainWindow, DownloadWorker (QThread)
│       ├── widgets.py      # URLInput, ModeSelector, QualityCombo, etc.
│       └── styles.qss      # Qt stylesheet
├── tests/
│   └── test_downloader.py  # Backend unit tests
├── scripts/
│   ├── build.sh
│   └── build.spec
├── pyproject.toml
└── README.md
```

## Running the App

```bash
PYTHONPATH=src python3 src/tuberip/main.py
```

## Testing

```bash
PYTHONPATH=src pytest tests/
```

## Building a Standalone Binary

```bash
pip install pyinstaller
bash scripts/build.sh
```

The executable will be in `dist/`.

## Architecture

### Backend

The backend is a thin wrapper around `yt-dlp`. It does not reimplement download logic. Key classes:

- `DownloadConfig`: user-selected options (mode, quality, output dir, subtitles)
- `DownloadItem`: runtime state (URL, title, progress, status, error)
- `Downloader`: builds the `yt-dlp` command and runs it in a subprocess, parsing stdout for progress

### Frontend

- `MainWindow` owns the UI state and spawns a `DownloadWorker` per download.
- `DownloadWorker` is a `QThread` that calls `Downloader.download()` and emits `progress`, `status_changed`, and `finished` signals.
- Widgets are kept small and reusable (`widgets.py`) to make future layout changes easy.

### Threading Model

Each download runs in its own `QThread`. The UI never blocks. Progress is parsed from `yt-dlp` stdout lines containing `[download]` and `%`.

## Packaging

- Development install: `pip install -e '.[dev]'`
- Binary distribution: PyInstaller (`scripts/build.spec`)
- Future target: Flatpak for distro-agnostic packaging

## Roadmap

- [ ] Playlist support
- [ ] Download history persisted to disk
- [ ] System tray integration
- [ ] Flatpak package
- [ ] Dark mode stylesheet
- [ ] Internationalization (i18n)

## Contributing

See `CONTRIBUTING.md`.

## License

MIT — see `LICENSE`.
