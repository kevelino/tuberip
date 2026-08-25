# TubeRip packaging

## Primary channel: AppImage (GitHub Releases)

```bash
cd apps/desktop
./scripts/build-appimage.sh
# → dist/TubeRip-<version>-x86_64.AppImage
# → dist/BUNDLED_YTDLP_VERSION
```

CI publishes the AppImage on tags `v*` (see `.github/workflows/release.yml`), with `GITHUB_TOKEN` so the yt-dlp Releases API call is authenticated.

The script always resolves and downloads the current latest yt-dlp asset at build time (no pinned version, no reused helpers cache). The exact version is written to `usr/share/tuberip/BUNDLED_YTDLP_VERSION` inside the AppDir and to `dist/BUNDLED_YTDLP_VERSION`.

Layout produced by the script:

```
TubeRip.AppDir/
  AppRun
  tuberip.desktop
  tuberip.svg
  usr/bin/TubeRip/     # Flutter release bundle (binary renamed tuberip)
  usr/bin/yt-dlp
  usr/bin/ffmpeg
  usr/share/tuberip/BUNDLED_YTDLP_VERSION
  usr/share/...
```

## Flatpak (secondary, later)

- Runtime permissions for cookies + downloads remain the main friction.
- Starter ideas: [`flatpak-manifest.json`](flatpak-manifest.json)

## Windows (Inno Setup)

```powershell
cd apps/desktop
.\scripts\build-windows.ps1
# → dist/TubeRip-Setup-x64.exe
# → dist/BUNDLED_YTDLP_VERSION
```

CI publishes the Inno Setup installer on tags `v*` (see `.github/workflows/release.yml`). See [WINDOWS.md](WINDOWS.md).

## Icon conversion

```bash
rsvg-convert -w 256 -h 256 assets/icons/tuberip.svg -o assets/icons/tuberip-256.png
```
