# Windows port notes (post-MVP)

TubeRip’s Flutter UI and yt-dlp command builder are largely cross-platform.
Enabling Windows later requires:

1. `flutter create --platforms=windows .` if the `windows/` runner is missing.
2. Ship or document install of `yt-dlp.exe` and `ffmpeg.exe`.
3. Wire `BinaryManager` to look under `%LOCALAPPDATA%/TubeRip/bin` as well as PATH.
4. **Pause**: `ProcessSignal.sigstop` is unavailable — keep pause buttons hidden
   (`Platform.isLinux || Platform.isMacOS` already gates the UI) or implement cancel+retry.
5. Prefer `chrome` / `edge` for `--cookies-from-browser`.

No Windows runner is required for the Linux MVP.
