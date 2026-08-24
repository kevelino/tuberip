#!/usr/bin/env bash
# Build a TubeRip AppImage (Flutter Linux + bundled yt-dlp + ffmpeg).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/dist}"
APP_NAME="TubeRip"
ARCH="$(uname -m)"
VERSION="${VERSION:-$(grep '^version:' "$ROOT/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d+ -f1)}"
APPDIR="$OUT_DIR/${APP_NAME}.AppDir"
BUNDLE="$ROOT/build/linux/x64/release/bundle"

case "$ARCH" in
  x86_64|amd64)
    YT_DLP_DEFAULT="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"
    FFMPEG_DEFAULT="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
    ;;
  aarch64|arm64)
    YT_DLP_DEFAULT="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64"
    FFMPEG_DEFAULT="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz"
    BUNDLE="$ROOT/build/linux/arm64/release/bundle"
    ;;
  *)
    echo "ERROR: unsupported arch $ARCH" >&2
    exit 1
    ;;
esac
YT_DLP_URL="${YT_DLP_URL:-$YT_DLP_DEFAULT}"
FFMPEG_URL="${FFMPEG_URL:-$FFMPEG_DEFAULT}"

echo "==> TubeRip AppImage builder (v${VERSION}, ${ARCH})"
mkdir -p "$OUT_DIR"

# ── Flutter release build ──────────────────────────────────────────
if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  echo "==> flutter build linux --release"
  cd "$ROOT"
  flutter pub get
  flutter build linux --release
fi

if [[ ! -x "$BUNDLE/desktop" ]]; then
  echo "ERROR: Flutter bundle not found at $BUNDLE/desktop" >&2
  exit 1
fi

# ── AppDir layout ──────────────────────────────────────────────────
echo "==> Assembling AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin/TubeRip" "$APPDIR/usr/share/icons/hicolor/scalable/apps" "$APPDIR/usr/share/applications"

cp -a "$BUNDLE"/. "$APPDIR/usr/bin/TubeRip/"
mv "$APPDIR/usr/bin/TubeRip/desktop" "$APPDIR/usr/bin/TubeRip/tuberip"

# Bundled helpers next to PATH for BinaryManager / AppRun
HELPERS="$OUT_DIR/helpers"
mkdir -p "$HELPERS"

download() {
  local url="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    echo "  keep cached $(basename "$dest")"
    return
  fi
  echo "  download $(basename "$dest")"
  curl -fsSL -o "$dest" "$url"
}

download "$YT_DLP_URL" "$HELPERS/yt-dlp"
chmod +x "$HELPERS/yt-dlp"
cp "$HELPERS/yt-dlp" "$APPDIR/usr/bin/yt-dlp"

if [[ ! -f "$HELPERS/ffmpeg" ]]; then
  echo "  download ffmpeg static archive"
  curl -fsSL -o "$HELPERS/ffmpeg.tar.xz" "$FFMPEG_URL"
  tar -xJf "$HELPERS/ffmpeg.tar.xz" -C "$HELPERS"
  FFMPEG_BIN="$(find "$HELPERS" -type f -name ffmpeg | head -1)"
  if [[ -z "$FFMPEG_BIN" ]]; then
    echo "ERROR: ffmpeg binary not found in archive" >&2
    exit 1
  fi
  cp "$FFMPEG_BIN" "$HELPERS/ffmpeg"
  chmod +x "$HELPERS/ffmpeg"
fi
cp "$HELPERS/ffmpeg" "$APPDIR/usr/bin/ffmpeg"
chmod +x "$APPDIR/usr/bin/ffmpeg"

# Desktop + icon
cp "$ROOT/assets/icons/tuberip-3.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/tuberip.svg"
cp "$ROOT/assets/icons/tuberip-3.svg" "$APPDIR/tuberip.svg"

cat > "$APPDIR/tuberip.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=TubeRip
GenericName=YouTube Downloader
Comment=Download YouTube video and audio with yt-dlp
Exec=tuberip
Icon=tuberip
Terminal=false
Categories=AudioVideo;Network;
Keywords=youtube;download;yt-dlp;video;audio;
StartupNotify=true
EOF
cp "$APPDIR/tuberip.desktop" "$APPDIR/usr/share/applications/tuberip.desktop"

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
set -e
HERE="$(dirname "$(readlink -f "$0")")"
export APPDIR="${APPDIR:-$HERE}"
export PATH="$HERE/usr/bin:$PATH"
# Prefer bundled helpers for yt-dlp / ffmpeg
export PATH="$HERE/usr/bin:$PATH"
cd "$HERE/usr/bin/TubeRip"
exec "$HERE/usr/bin/TubeRip/tuberip" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# ── appimagetool ───────────────────────────────────────────────────
APPIMAGETOOL="${APPIMAGETOOL:-}"
if [[ -z "$APPIMAGETOOL" ]]; then
  if command -v appimagetool >/dev/null 2>&1; then
    APPIMAGETOOL="$(command -v appimagetool)"
  else
    TOOL="$OUT_DIR/appimagetool-$ARCH.AppImage"
    if [[ ! -x "$TOOL" ]]; then
      echo "==> Downloading appimagetool"
      case "$ARCH" in
        x86_64|amd64)
          curl -fsSL -o "$TOOL" \
            "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
          ;;
        aarch64|arm64)
          curl -fsSL -o "$TOOL" \
            "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-aarch64.AppImage"
          ;;
        *)
          echo "ERROR: unsupported arch $ARCH — install appimagetool manually" >&2
          exit 1
          ;;
      esac
      chmod +x "$TOOL"
    fi
    APPIMAGETOOL="$TOOL"
  fi
fi

OUT_FILE="$OUT_DIR/${APP_NAME}-${VERSION}-${ARCH}.AppImage"
echo "==> Packaging $OUT_FILE"
# Extracted appimagetool may need FUSE; ARCH + VERSION for naming
export ARCH
export VERSION
# Prefer --appimage-extract-and-run when FUSE is unavailable (CI)
if [[ "${APPIMAGE_EXTRACT_AND_RUN:-0}" == "1" ]] || [[ -n "${CI:-}" ]]; then
  export APPIMAGE_EXTRACT_AND_RUN=1
fi

"$APPIMAGETOOL" "$APPDIR" "$OUT_FILE"
chmod +x "$OUT_FILE"

echo ""
echo "Done: $OUT_FILE"
echo "Run with: $OUT_FILE"
