#!/usr/bin/env bash
# Build a TubeRip AppImage (Flutter Linux + bundled yt-dlp + ffmpeg).
# yt-dlp is always resolved from the GitHub Releases API at build time (never cached).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/dist}"
APP_NAME="TubeRip"
ARCH="$(uname -m)"
VERSION="${VERSION:-$(grep '^version:' "$ROOT/pubspec.yaml" | head -1 | awk '{print $2}' | cut -d+ -f1)}"
APPDIR="$OUT_DIR/${APP_NAME}.AppDir"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
YT_DLP_API="https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"

case "$ARCH" in
  x86_64|amd64)
    YT_DLP_ASSET="yt-dlp_linux"
    FFMPEG_DEFAULT="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
    ;;
  aarch64|arm64)
    YT_DLP_ASSET="yt-dlp_linux_aarch64"
    FFMPEG_DEFAULT="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz"
    BUNDLE="$ROOT/build/linux/arm64/release/bundle"
    ;;
  *)
    echo "ERROR: unsupported arch $ARCH" >&2
    exit 1
    ;;
esac
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

# ── yt-dlp: always fetch latest at build time (never reuse helpers cache) ──
fetch_latest_ytdlp() {
  local dest="$1"
  local asset_name="$2"
  local api_json tag url tmp dest_size bin_version

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required to resolve the latest yt-dlp release" >&2
    exit 1
  fi

  echo "==> Resolving latest yt-dlp ($asset_name) via GitHub API"
  local curl_args=(-fsSL -H "Accept: application/vnd.github+json")
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  if ! api_json="$(curl "${curl_args[@]}" "$YT_DLP_API")"; then
    echo "ERROR: failed to query yt-dlp releases API ($YT_DLP_API)" >&2
    exit 1
  fi

  # Optional YT_DLP_URL override still resolves version from the API tag when possible.
  if [[ -n "${YT_DLP_URL:-}" ]]; then
    url="$YT_DLP_URL"
    tag="$(printf '%s' "$api_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print((data.get("tag_name") or "").lstrip("v"))
')"
    echo "  using YT_DLP_URL override"
  else
    # tag\turl — fail loudly if asset missing
    local resolved
    if ! resolved="$(printf '%s' "$api_json" | python3 -c '
import json, sys
data = json.load(sys.stdin)
tag = (data.get("tag_name") or "").lstrip("v")
asset = "'"$asset_name"'"
url = ""
for a in data.get("assets") or []:
    if a.get("name") == asset:
        url = a.get("browser_download_url") or ""
        break
if not tag:
    sys.stderr.write("ERROR: yt-dlp release has empty tag_name\n")
    sys.exit(1)
if not url:
    sys.stderr.write(f"ERROR: yt-dlp release has no asset named {asset!r}\n")
    sys.exit(1)
print(f"{tag}\t{url}")
')"; then
      exit 1
    fi
    tag="${resolved%%$'\t'*}"
    url="${resolved#*$'\t'}"
  fi

  if [[ -z "$url" ]]; then
    echo "ERROR: empty yt-dlp download URL" >&2
    exit 1
  fi
  if [[ -z "$tag" ]]; then
    echo "ERROR: could not determine yt-dlp version tag" >&2
    exit 1
  fi

  tmp="$(mktemp "$HELPERS/yt-dlp.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN

  echo "  download yt-dlp $tag"
  if ! curl -fsSL -o "$tmp" "$url"; then
    echo "ERROR: failed to download yt-dlp from $url" >&2
    exit 1
  fi

  dest_size="$(wc -c < "$tmp" | tr -d ' ')"
  if [[ -z "$dest_size" || "$dest_size" -eq 0 ]]; then
    echo "ERROR: downloaded yt-dlp is empty" >&2
    exit 1
  fi

  chmod +x "$tmp"
  if ! bin_version="$("$tmp" --version 2>/dev/null | head -1 | tr -d '[:space:]' | sed 's/^v//')"; then
    echo "ERROR: downloaded yt-dlp failed to run (--version)" >&2
    exit 1
  fi
  if [[ -z "$bin_version" ]]; then
    echo "ERROR: yt-dlp --version returned empty output" >&2
    exit 1
  fi
  if [[ "$bin_version" != "$tag" ]]; then
    echo "WARNING: API tag ($tag) != binary --version ($bin_version); using binary version" >&2
    tag="$bin_version"
  fi

  rm -f "$dest"
  mv "$tmp" "$dest"
  trap - RETURN
  chmod +x "$dest"

  BUNDLED_YTDLP_VERSION="$tag"
  echo "  Bundled yt-dlp: $BUNDLED_YTDLP_VERSION (${dest_size} bytes)"
}

fetch_latest_ytdlp "$HELPERS/yt-dlp" "$YT_DLP_ASSET"
cp "$HELPERS/yt-dlp" "$APPDIR/usr/bin/yt-dlp"
chmod +x "$APPDIR/usr/bin/yt-dlp"

mkdir -p "$APPDIR/usr/share/tuberip"
printf '%s\n' "$BUNDLED_YTDLP_VERSION" > "$APPDIR/usr/share/tuberip/BUNDLED_YTDLP_VERSION"
printf '%s\n' "$BUNDLED_YTDLP_VERSION" > "$OUT_DIR/BUNDLED_YTDLP_VERSION"

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
export PATH="$HERE/usr/bin:/usr/local/bin:/usr/bin:$PATH"
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
echo "Bundled yt-dlp: $BUNDLED_YTDLP_VERSION"
echo "Run with: $OUT_FILE"
