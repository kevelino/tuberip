# Build a TubeRip Windows Installer (Flutter Windows + bundled yt-dlp.exe + ffmpeg.exe + Inno Setup).
# yt-dlp is resolved from GitHub Releases API at build time.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Get-Item "$ScriptDir\..").FullName
$OutDir = if ($env:OUT_DIR) { $env:OUT_DIR } else { "$RootDir\dist" }
$HelpersDir = "$OutDir\helpers-win"
$BundleDir = "$RootDir\build\windows\x64\runner\Release"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path $HelpersDir | Out-Null

if ($env:VERSION) {
    $Version = $env:VERSION -replace '^v', ''
} else {
    $pubspec = Get-Content "$RootDir\pubspec.yaml" -Raw
    if ($pubspec -match '(?m)^version:\s*([^\s+]+)') {
        $Version = $matches[1]
    } else {
        $Version = "1.0.0"
    }
}

Write-Host "==> TubeRip Windows builder (v$Version, x64)"

# ── Flutter release build ──────────────────────────────────────────
if ($env:SKIP_FLUTTER_BUILD -ne "1") {
    Write-Host "==> flutter build windows --release"
    Push-Location $RootDir
    try {
        flutter pub get
        flutter build windows --release
    } finally {
        Pop-Location
    }
}

if (-not (Test-Path "$BundleDir\TubeRip.exe")) {
    if (Test-Path "$BundleDir\desktop.exe") {
        Copy-Item "$BundleDir\desktop.exe" "$BundleDir\TubeRip.exe" -Force
    } else {
        Write-Error "Flutter release build not found at $BundleDir\TubeRip.exe"
        exit 1
    }
}

# ── yt-dlp: fetch latest at build time ────────────────────────────
Write-Host "==> Resolving latest yt-dlp (yt-dlp.exe) via GitHub API"
$headers = @{
    "Accept" = "application/vnd.github+json"
    "User-Agent" = "TubeRip-Build"
}
if ($env:GITHUB_TOKEN) {
    $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
}

$apiJson = Invoke-RestMethod -Uri "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest" -Headers $headers
$tag = ($apiJson.tag_name -replace '^v', '').Trim()
$asset = $apiJson.assets | Where-Object { $_.name -eq "yt-dlp.exe" } | Select-Object -First 1

if (-not $asset -or -not $asset.browser_download_url) {
    Write-Error "Could not find yt-dlp.exe asset in latest release"
    exit 1
}

$ytdlpUrl = if ($env:YT_DLP_URL) { $env:YT_DLP_URL } else { $asset.browser_download_url }
$ytdlpDest = "$HelpersDir\yt-dlp.exe"

Write-Host "  Downloading yt-dlp $tag from $ytdlpUrl"
Invoke-WebRequest -Uri $ytdlpUrl -OutFile $ytdlpDest

if (-not (Test-Path $ytdlpDest) -or (Get-Item $ytdlpDest).Length -eq 0) {
    Write-Error "Downloaded yt-dlp.exe is missing or empty"
    exit 1
}

# Try running --version to confirm binary
$binVerOutput = & $ytdlpDest --version 2>$null
if ($binVerOutput) {
    $binVer = ($binVerOutput -split "`r?`n")[0].Trim() -replace '^v', ''
    $BundledYtDlpVersion = if ($binVer) { $binVer } else { $tag }
} else {
    $BundledYtDlpVersion = $tag
}

Write-Host "  Bundled yt-dlp: $BundledYtDlpVersion"
Copy-Item $ytdlpDest "$BundleDir\yt-dlp.exe" -Force
Set-Content -Path "$OutDir\BUNDLED_YTDLP_VERSION" -Value $BundledYtDlpVersion -NoNewline

# ── ffmpeg: fetch static Windows build ─────────────────────────────
$ffmpegDest = "$HelpersDir\ffmpeg.exe"
if (-not (Test-Path $ffmpegDest)) {
    $ffmpegUrl = if ($env:FFMPEG_URL) {
        $env:FFMPEG_URL
    } else {
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    }
    Write-Host "  Downloading ffmpeg from $ffmpegUrl"
    $ffmpegZip = "$HelpersDir\ffmpeg.zip"
    Invoke-WebRequest -Uri $ffmpegUrl -OutFile $ffmpegZip

    Write-Host "  Extracting ffmpeg.exe"
    Expand-Archive -Path $ffmpegZip -DestinationPath "$HelpersDir\ffmpeg_extracted" -Force
    $extractedBin = Get-ChildItem -Path "$HelpersDir\ffmpeg_extracted" -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
    if (-not $extractedBin) {
        Write-Error "ffmpeg.exe not found in archive"
        exit 1
    }
    Copy-Item $extractedBin.FullName $ffmpegDest -Force
    Remove-Item -Recurse -Force "$HelpersDir\ffmpeg_extracted", $ffmpegZip -ErrorAction SilentlyContinue
}

Copy-Item $ffmpegDest "$BundleDir\ffmpeg.exe" -Force

# ── Inno Setup installer packaging ─────────────────────────────────
Write-Host "==> Compiling Inno Setup installer"
$isccPath = (Get-Command "ISCC.exe" -ErrorAction SilentlyContinue)?.Source
if (-not $isccPath) {
    $possiblePaths = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            $isccPath = $p
            break
        }
    }
}

if (-not $isccPath) {
    Write-Host "  ISCC.exe not found in standard paths. Attempting to install via choco..."
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        choco install innosetup -y --no-progress
        $isccPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    }
}

if (-not $isccPath -or -not (Test-Path $isccPath)) {
    Write-Error "Inno Setup Compiler (ISCC.exe) not found!"
    exit 1
}

$issPath = "$RootDir\windows\installer.iss"
Write-Host "  Running $isccPath /DAppVersion=$Version $issPath"
& $isccPath "/DAppVersion=$Version" $issPath

$installerExe = "$OutDir\TubeRip-Setup-x64.exe"
if (-not (Test-Path $installerExe)) {
    Write-Error "Installer was not created at $installerExe"
    exit 1
}

Write-Host ""
Write-Host "Done: $installerExe"
Write-Host "Bundled yt-dlp: $BundledYtDlpVersion"
