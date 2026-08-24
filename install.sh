#!/bin/sh
# TubeRip — install AppImage + desktop integration (no sudo).
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/kevelino/tuberip/main/install.sh | sh
#   ./install.sh   # if a TubeRip*.AppImage is already in the current directory
set -eu

REPO="kevelino/tuberip"
APP_NAME="TubeRip"
INSTALL_DIR="${HOME}/.local/share/tuberip"
APPIMAGE_DEST="${INSTALL_DIR}/TubeRip.AppImage"
ICON_DEST="${HOME}/.local/share/icons/tuberip.svg"
DESKTOP_DEST="${HOME}/.local/share/applications/tuberip.desktop"
ICON_RAW_URL="https://raw.githubusercontent.com/${REPO}/main/apps/desktop/assets/icons/tuberip-3.svg"
RELEASES_API="https://api.github.com/repos/${REPO}/releases/latest"
USER_AGENT="TubeRip-install"

TMP_JSON=""
TMP_APP=""
TMP_ICON=""

cleanup() {
  rm -f "$TMP_JSON" "$TMP_APP" "$TMP_ICON" 2>/dev/null || true
}
trap cleanup EXIT

die() {
  step="$1"
  shift
  printf 'Error (%s): %s\n' "$step" "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

file_size() {
  if size=$(stat -c%s "$1" 2>/dev/null); then
    printf '%s' "$size"
  elif size=$(stat -f%z "$1" 2>/dev/null); then
    printf '%s' "$size"
  else
    wc -c <"$1" | tr -d ' \t\n'
  fi
}

require_downloader() {
  if have_cmd curl || have_cmd wget; then
    return 0
  fi
  die "download" "neither curl nor wget is installed"
}

download() {
  url="$1"
  dest="$2"
  if have_cmd curl; then
    curl -fsSL -A "$USER_AGENT" -o "$dest" "$url"
  elif have_cmd wget; then
    wget -q -U "$USER_AGENT" -O "$dest" "$url"
  else
    return 2
  fi
}

# Prefer newest non-empty TubeRip*.AppImage in a directory.
find_local_appimage() {
  dir="$1"
  [ -d "$dir" ] || return 1
  found=""
  for candidate in "$dir"/TubeRip*.AppImage; do
    [ -f "$candidate" ] || continue
    size=$(file_size "$candidate")
    case "$size" in
      ''|*[!0-9]*) continue ;;
    esac
    [ "$size" -gt 0 ] || continue
    found="$candidate"
  done
  [ -n "$found" ] || return 1
  printf '%s\n' "$found"
}

# Only when $0 is a real path (not curl|sh with $0 as sh/-).
script_dir() {
  case "$0" in
    -|sh|*/sh|bash|*/bash) return 1 ;;
  esac
  case "$0" in
    /*)
      dirname "$0"
      ;;
    */*)
      (cd "$(dirname "$0")" && pwd)
      ;;
    *)
      return 1
      ;;
  esac
}

# Read release JSON from stdin; print preferred browser_download_url.
pick_asset_url() {
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64) prefer="x86_64" ;;
    aarch64|arm64) prefer="aarch64" ;;
    *) prefer="" ;;
  esac

  urls=$(
    tr ',' '\n' | sed -n 's/.*"browser_download_url"[ ]*:[ ]*"\([^"]*\.AppImage\)".*/\1/p'
  ) || true

  [ -n "$urls" ] || return 1

  if [ -n "$prefer" ]; then
    match=$(printf '%s\n' "$urls" | grep -F "$prefer" | head -n 1) || true
    if [ -n "$match" ]; then
      printf '%s\n' "$match"
      return 0
    fi
  fi

  printf '%s\n' "$urls" | head -n 1
}

fetch_latest_appimage() {
  require_downloader
  info "Fetching latest release metadata from GitHub…"

  TMP_JSON=$(mktemp) || die "download" "cannot create temp file"
  if ! download "$RELEASES_API" "$TMP_JSON"; then
    die "download" "failed to query GitHub releases API"
  fi

  url=$(pick_asset_url <"$TMP_JSON") || true
  [ -n "${url:-}" ] || die "download" "no .AppImage asset found in the latest release"

  info "Downloading AppImage…"
  TMP_APP=$(mktemp) || die "download" "cannot create temp file"
  if ! download "$url" "$TMP_APP"; then
    die "download" "failed to download AppImage from $url"
  fi

  size=$(file_size "$TMP_APP")
  case "$size" in
    ''|*[!0-9]*) die "download" "cannot determine downloaded AppImage size" ;;
  esac
  [ "$size" -gt 0 ] || die "download" "downloaded AppImage is empty"

  printf '%s\n' "$TMP_APP"
}

install_appimage() {
  src="$1"
  info "Installing AppImage to ${APPIMAGE_DEST}…"
  mkdir -p "$INSTALL_DIR" || die "install" "cannot create $INSTALL_DIR"
  cp -f "$src" "$APPIMAGE_DEST" || die "install" "failed to copy AppImage to $APPIMAGE_DEST"
  chmod +x "$APPIMAGE_DEST" || die "install" "failed to chmod +x $APPIMAGE_DEST"
  size=$(file_size "$APPIMAGE_DEST")
  case "$size" in
    ''|*[!0-9]*) die "install" "cannot determine installed AppImage size" ;;
  esac
  [ "$size" -gt 0 ] || die "install" "installed AppImage is empty"
  info "AppImage installed (${size} bytes)"
}

install_icon() {
  info "Installing icon…"
  mkdir -p "$(dirname "$ICON_DEST")" || die "icon" "cannot create icon directory"

  src=""
  for candidate in \
    "apps/desktop/assets/icons/tuberip-3.svg" \
    "apps/desktop/assets/tuberip-3.svg"
  do
    if [ -f "$candidate" ]; then
      src="$candidate"
      break
    fi
  done

  if [ -z "$src" ]; then
    sd=$(script_dir) || sd=""
    if [ -n "$sd" ]; then
      for candidate in \
        "$sd/apps/desktop/assets/icons/tuberip-3.svg" \
        "$sd/apps/desktop/assets/tuberip-3.svg"
      do
        if [ -f "$candidate" ]; then
          src="$candidate"
          break
        fi
      done
    fi
  fi

  if [ -n "$src" ]; then
    cp -f "$src" "$ICON_DEST" || die "icon" "failed to copy icon from $src"
  else
    require_downloader
    info "Fetching icon from GitHub…"
    TMP_ICON=$(mktemp) || die "icon" "cannot create temp file"
    if ! download "$ICON_RAW_URL" "$TMP_ICON"; then
      die "icon" "failed to download icon from $ICON_RAW_URL"
    fi
    size=$(file_size "$TMP_ICON")
    case "$size" in
      ''|*[!0-9]*) die "icon" "cannot determine downloaded icon size" ;;
    esac
    [ "$size" -gt 0 ] || die "icon" "downloaded icon is empty"
    cp -f "$TMP_ICON" "$ICON_DEST" || die "icon" "failed to install icon"
  fi
  info "Icon installed at ${ICON_DEST}"
}

install_desktop_entry() {
  info "Writing desktop entry…"
  mkdir -p "$(dirname "$DESKTOP_DEST")" || die "desktop" "cannot create applications directory"

  # Expand $HOME at write time — .desktop Exec does not expand ~ or $HOME.
  cat >"$DESKTOP_DEST" <<EOF
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Comment=Download YouTube videos and audio
Exec=${HOME}/.local/share/tuberip/TubeRip.AppImage %U
Icon=tuberip
Categories=AudioVideo;Network;
Terminal=false
StartupWMClass=com.kevelino.desktop
EOF

  chmod +x "$DESKTOP_DEST" || die "desktop" "failed to chmod +x $DESKTOP_DEST"
  info "Desktop entry written to ${DESKTOP_DEST}"
}

refresh_caches() {
  info "Refreshing desktop caches…"
  if have_cmd update-desktop-database; then
    update-desktop-database "${HOME}/.local/share/applications/" >/dev/null 2>&1 \
      || info "update-desktop-database reported a warning (continuing)"
    info "Updated desktop database"
  else
    info "Skipping update-desktop-database (not installed)"
  fi

  if have_cmd gtk-update-icon-cache; then
    gtk-update-icon-cache "${HOME}/.local/share/icons/" >/dev/null 2>&1 \
      || info "gtk-update-icon-cache reported a warning (continuing)"
    info "Updated icon cache"
  else
    info "Skipping gtk-update-icon-cache (not installed)"
  fi
}

main() {
  info "TubeRip installer (user install, no sudo)"

  if [ -z "${HOME:-}" ]; then
    die "setup" "HOME is not set"
  fi

  appimage=""
  if appimage=$(find_local_appimage "$(pwd)"); then
    info "Using local AppImage: $appimage"
  else
    sd=$(script_dir) || sd=""
    if [ -n "$sd" ] && appimage=$(find_local_appimage "$sd"); then
      info "Using local AppImage: $appimage"
    else
      appimage=$(fetch_latest_appimage)
    fi
  fi

  install_appimage "$appimage"
  install_icon
  install_desktop_entry
  refresh_caches

  printf '\n'
  info "TubeRip is installed."
  printf '    Launch it from your application menu, or run:\n'
  printf '      %s\n' "$APPIMAGE_DEST"
  printf '    If it does not appear immediately, log out and back in\n'
  printf '    (or restart your desktop session).\n'
}

main "$@"
