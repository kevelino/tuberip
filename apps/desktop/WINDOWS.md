# Windows Distribution & Build

TubeRip supports Windows x64 packaged via Inno Setup.

## Building the Windows Installer

From PowerShell (on Windows):

```powershell
cd apps/desktop
.\scripts\build-windows.ps1
# Output: dist/TubeRip-Setup-x64.exe
#         dist/BUNDLED_YTDLP_VERSION
```

### Build Requirements
- Flutter SDK (with Windows desktop enabled)
- Visual Studio with C++ desktop workload
- Inno Setup 6 (`ISCC.exe` in PATH or standard Program Files location)
- Internet connection (to fetch latest `yt-dlp.exe` and `ffmpeg.exe` at build time)

### Packaging Details
- Built with `PrivilegesRequired=lowest` for per-user installation without requiring administrator rights.
- Bundles `TubeRip.exe`, all required Flutter runtime DLLs, `yt-dlp.exe`, and `ffmpeg.exe`.
- BinaryManager resolves bundled binaries next to the executable and supports auto-updates to `%LOCALAPPDATA%\TubeRip\bin`.

