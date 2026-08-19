#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== TubeRip Desktop Build Script ==="
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter SDK not found in PATH."
    echo "Install from https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Step 1: Install dependencies (if needed)
echo "[1/4] Checking system dependencies..."
if command -v yt-dlp &> /dev/null; then
    echo "  yt-dlp: $(yt-dlp --version)"
else
    echo "  yt-dlp: NOT FOUND — run scripts/install-deps.sh"
    exit 1
fi

if command -v ffmpeg &> /dev/null; then
    echo "  ffmpeg: $(ffmpeg -version | head -1)"
else
    echo "  ffmpeg: NOT FOUND — run scripts/install-deps.sh"
    exit 1
fi

# Step 2: Install Dart dependencies
echo ""
echo "[2/4] Fetching Dart dependencies..."
flutter pub get

# Step 3: Build or run
echo ""
if [ "${1:-}" == "run" ]; then
    echo "[3/4] Running in debug mode..."
    flutter run -d linux
    echo "[4/4] Done!"
elif [ "${1:-}" == "release" ]; then
    echo "[3/4] Building release..."
    flutter build linux --release
    echo "[4/4] Done!"
    echo "Run: build/linux/x64/release/bundle/tuberip"
else
    echo "[3/4] Building (release)..."
    flutter build linux --release
    echo "[4/4] Done!"
    echo "Run: build/linux/x64/release/bundle/tuberip"
    echo "Or: flutter run -d linux  (for development)"
fi
