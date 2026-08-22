# TubeRip packaging

## Primary channel: AppImage (GitHub Releases)

```bash
cd apps/desktop
./scripts/build-appimage.sh
# → dist/TubeRip-<version>-x86_64.AppImage
```

CI publishes the AppImage on tags `v*` (see `.github/workflows/release.yml`).

Layout produced by the script:

```
TubeRip.AppDir/
  AppRun
  tuberip.desktop
  tuberip.svg
  usr/bin/TubeRip/     # Flutter release bundle (binary renamed tuberip)
  usr/bin/yt-dlp
  usr/bin/ffmpeg
  usr/share/...
```

## Flatpak (secondary, later)

- Runtime permissions for cookies + downloads remain the main friction.
- Starter ideas: [`flatpak-manifest.json`](flatpak-manifest.json)

## Windows (later)

See [WINDOWS.md](WINDOWS.md).

## Icon conversion

```bash
rsvg-convert -w 256 -h 256 assets/icons/tuberip.svg -o assets/icons/tuberip-256.png
```
