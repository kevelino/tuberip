# TubeRip Distribution Strategy

## Current state

- **App**: Flutter Linux desktop in [`apps/desktop/`](apps/desktop/)
- **Primary channel**: AppImage published to GitHub Releases on tags `v*`
- **CI**: [`.github/workflows/release.yml`](.github/workflows/release.yml) builds and uploads the AppImage
- **Build script**: [`apps/desktop/scripts/build-appimage.sh`](apps/desktop/scripts/build-appimage.sh) (bundles yt-dlp + ffmpeg)

## Channels — ranked

### 1. AppImage via GitHub Releases — Primary

- Single file, works across Fedora / Ubuntu / Arch without a store
- No strict sandbox → browser cookies and download folders work naturally
- yt-dlp and ffmpeg can be bundled inside the AppImage
- Already automated on `v*` tags

```bash
cd apps/desktop
./scripts/build-appimage.sh
# → dist/TubeRip-<version>-x86_64.AppImage
```

### 2. Flatpak / Flathub — Future

- Better discovery (GNOME Software / KDE Discover)
- Needs careful permissions for cookies and filesystem access
- Draft notes: [`apps/desktop/flatpak-manifest.json`](apps/desktop/flatpak-manifest.json), [`apps/desktop/PACKAGING.md`](apps/desktop/PACKAGING.md)

### 3. Not planned for now

- Snap
- Standalone DEB/RPM as the only channel (high maintenance)
- PyInstaller / Python packaging (removed with the PySide6 app)

## Roadmap

1. Keep AppImage + Releases as the supported download path
2. Document install on the marketing site and READMEs
3. Later: Flatpak module with bundled yt-dlp/ffmpeg and cookie permissions
4. Later: Windows package (see [`apps/desktop/WINDOWS.md`](apps/desktop/WINDOWS.md))
