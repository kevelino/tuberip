#!/usr/bin/env bash
set -euo pipefail

# Install system dependencies for TubeRip
# - yt-dlp: installed via pip (same approach as Flatpak manifest)
# - ffmpeg: installed via system package manager

echo "=== TubeRip Dependency Installer ==="
echo ""

# Check for yt-dlp
if command -v yt-dlp &> /dev/null; then
    echo "[OK] yt-dlp already installed: $(which yt-dlp)"
else
    echo "[..] Installing yt-dlp via pip3..."
    pip3 install --user --break-system-packages -U yt-dlp 2>/dev/null || \
    pip3 install --user -U yt-dlp
    echo "[OK] yt-dlp installed to ~/.local/bin/"
    echo "     Add ~/.local/bin to your PATH if not already there."
fi

# Check for ffmpeg
if command -v ffmpeg &> /dev/null; then
    echo "[OK] ffmpeg already installed: $(which ffmpeg)"
else
    echo "[..] Installing ffmpeg via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y ffmpeg
    echo "[OK] ffmpeg installed"
fi

# Verify
echo ""
echo "=== Verification ==="
yt-dlp --version 2>/dev/null && echo "[OK] yt-dlp works" || echo "[FAIL] yt-dlp"
ffmpeg -version 2>/dev/null | head -1 && echo "[OK] ffmpeg works" || echo "[FAIL] ffmpeg"

echo ""
echo "Dependencies installed! You can now build and run TubeRip."
