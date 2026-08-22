#!/usr/bin/env bash
# Install TubeRip runtime dependencies (yt-dlp + ffmpeg) on Linux.
set -euo pipefail

echo "==> TubeRip dependency installer"

if command -v ffmpeg >/dev/null 2>&1; then
  echo "OK  ffmpeg: $(command -v ffmpeg)"
else
  echo "Missing ffmpeg"
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ffmpeg
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y ffmpeg
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm ffmpeg
  else
    echo "Install ffmpeg manually for your distro, then re-run."
    exit 1
  fi
fi

if command -v yt-dlp >/dev/null 2>&1; then
  echo "OK  yt-dlp: $(yt-dlp --version 2>/dev/null | head -1)"
else
  echo "Missing yt-dlp — installing via pipx or pip"
  if command -v pipx >/dev/null 2>&1; then
    pipx install yt-dlp
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y yt-dlp || python3 -m pip install --user yt-dlp
  else
    python3 -m pip install --user yt-dlp
  fi
fi

echo ""
echo "Done. Verify with:"
echo "  yt-dlp --version && ffmpeg -version | head -1"
