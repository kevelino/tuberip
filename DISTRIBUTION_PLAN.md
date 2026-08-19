# TubeRip Distribution Strategy

## Current State
- **PyInstaller**: Already configured (`scripts/build.sh`, `scripts/build.spec`)
- **CI**: GitHub Actions runs tests/lint only — no build/distribution pipeline
- **Assets**: SVG icon exists at `assets/tuberip.svg`

## Distribution Options — Ranked

### 1. Flatpak via Flathub — Primary
- Works on all Linux distros
- Sandboxed & secure
- Automatic updates via Flathub
- Integrates with software centers (GNOME Software, KDE Discover)
- Zero installation friction for users

### 2. AppImage — Secondary
- Single file — drag & drop to run
- No sandbox — full filesystem access
- Easy to distribute via GitHub Releases
- No built-in auto-updates (acceptable for secondary channel)

### 3. PyInstaller Binary — Build Backend
- Already set up and working
- Used as the input for Flatpak/AppImage builds
- Also available as standalone dev build

### 4. Not Recommended
- **Snap**: Declining adoption, Canonical-controlled
- **DEB/RPM**: Maintenance burden across distros; do later if needed

## Implementation Roadmap

### Phase 1: Flatpak Build & Flathub Submission
1. Create `flatpak-manifest.json` — build steps, source, runtime, permissions
2. Create `tuberip.desktop` — desktop integration
3. Create `tuberip.metainfo.xml` — AppStream metadata
4. Add GitHub Action for Flatpak CI/CD
5. Submit to Flathub

### Phase 2: AppImage Distribution
1. Use `linuxdeploy` with PyInstaller binary
2. Create `AppImageBuilder.yml` config
3. Add GitHub Action to build AppImage on release
4. Upload to GitHub Releases

### Phase 3: GitHub Release Automation
1. Update CI workflow — add build job on tagged releases
2. Auto-publish artifacts (AppImage, PyInstaller binary)
3. Release notes — auto-generated from commits

### Phase 4: Optional Native Packages (later)
1. Create `debian/` directory for DEB packaging
2. Create RPM spec file for Fedora/openSUSE
