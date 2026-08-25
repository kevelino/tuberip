import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/constants.dart';
import 'binary_manager.dart';
import 'download_manager.dart';
import 'settings_service.dart';
import 'yt_dlp_paths.dart';

enum YtDlpUpdateKind { skipped, upToDate, updated, failed }

class YtDlpUpdateResult {
  const YtDlpUpdateResult({
    required this.kind,
    required this.message,
    this.version,
  });

  factory YtDlpUpdateResult.skipped(String message) => YtDlpUpdateResult(
        kind: YtDlpUpdateKind.skipped,
        message: message,
      );

  factory YtDlpUpdateResult.upToDate(String version) => YtDlpUpdateResult(
        kind: YtDlpUpdateKind.upToDate,
        message: 'yt-dlp is up to date ($version)',
        version: version,
      );

  factory YtDlpUpdateResult.updated(String version) => YtDlpUpdateResult(
        kind: YtDlpUpdateKind.updated,
        message: 'Updated yt-dlp to $version',
        version: version,
      );

  factory YtDlpUpdateResult.failed(String message) => YtDlpUpdateResult(
        kind: YtDlpUpdateKind.failed,
        message: message,
      );

  final YtDlpUpdateKind kind;
  final String message;
  final String? version;
}

class GitHubAsset {
  const GitHubAsset({
    required this.name,
    required this.browserDownloadUrl,
    this.size,
  });

  final String name;
  final String browserDownloadUrl;
  final int? size;
}

class GitHubReleaseInfo {
  const GitHubReleaseInfo({
    required this.tagName,
    required this.assets,
  });

  final String tagName;
  final List<GitHubAsset> assets;

  GitHubAsset? assetNamed(String name) {
    for (final asset in assets) {
      if (asset.name == name) return asset;
    }
    return null;
  }
}

GitHubReleaseInfo parseGithubReleaseJson(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final tag = (json['tag_name'] as String?) ?? '';
  final rawAssets = json['assets'] as List<dynamic>? ?? const [];
  final assets = <GitHubAsset>[];
  for (final item in rawAssets) {
    if (item is! Map<String, dynamic>) continue;
    final name = item['name'] as String? ?? '';
    final url = item['browser_download_url'] as String? ?? '';
    if (name.isEmpty || url.isEmpty) continue;
    final size = item['size'];
    assets.add(
      GitHubAsset(
        name: name,
        browserDownloadUrl: url,
        size: size is int ? size : int.tryParse('$size'),
      ),
    );
  }
  return GitHubReleaseInfo(tagName: tag, assets: assets);
}

/// Checks GitHub for a newer yt-dlp and atomically replaces the managed binary.
class YtDlpUpdater {
  YtDlpUpdater({
    required this.binaryManager,
    required this.downloadManager,
    required this.settings,
    this.minCheckInterval = const Duration(hours: 12),
  });

  static const _latestReleaseUrl =
      'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';

  final BinaryManager binaryManager;
  final DownloadManager downloadManager;
  final SettingsService settings;
  final Duration minCheckInterval;

  bool _autoCheckedThisSession = false;
  bool _swapInFlight = false;

  Future<String?> readLocalVersion() async {
    final path = binaryManager.ytDlpPath;
    if (path == null || path.isEmpty) return null;
    try {
      final result = await Process.run(
        path,
        ['--version'],
        environment: Platform.isWindows
            ? {
                ...Platform.environment,
                'PYTHONIOENCODING': 'utf-8',
                'PYTHONUTF8': '1',
              }
            : null,
      );
      final text = '${result.stdout}\n${result.stderr}';
      final version = YtDlpVersion.normalize(text);
      return version.isEmpty ? null : version;
    } catch (_) {
      return null;
    }
  }

  Future<YtDlpUpdateResult> checkAndUpdate({bool force = false}) async {
    try {
      if (!force && _autoCheckedThisSession) {
        _log('skipped: already checked this session');
        return YtDlpUpdateResult.skipped('Already checked this session');
      }

      await downloadManager.checkDependencies();

      if (!binaryManager.ytDlpIsManaged || binaryManager.ytDlpPath == null) {
        final usingCustom = binaryManager.customYtDlpPath.isNotEmpty;
        final message = usingCustom
            ? 'Custom yt-dlp path — auto-update off'
            : 'Using system yt-dlp — auto-update off';
        _log('skipped: $message');
        return YtDlpUpdateResult.skipped(message);
      }

      if (!force) {
        final last = await settings.loadYtDlpLastCheck();
        if (last != null &&
            DateTime.now().difference(last) < minCheckInterval) {
          _autoCheckedThisSession = true;
          _log('skipped: last check at ${last.toIso8601String()}');
          return YtDlpUpdateResult.skipped('Checked recently');
        }
      }

      if (!force) {
        _autoCheckedThisSession = true;
      }

      final release = await _fetchLatestRelease();
      await settings.saveYtDlpLastCheck(DateTime.now());

      final local = await readLocalVersion() ?? '';
      final remote = YtDlpVersion.normalize(release.tagName);
      if (remote.isEmpty) {
        _log('failed: empty remote tag');
        return YtDlpUpdateResult.failed(
          'Could not read latest yt-dlp version; keeping existing binary',
        );
      }

      if (local.isNotEmpty && !YtDlpVersion.isNewer(remote, local)) {
        _log('up to date: $local');
        await settings.saveYtDlpInstalledVersion(local);
        return YtDlpUpdateResult.upToDate(local);
      }

      if (downloadManager.hasActiveDownload) {
        _log('waiting for downloads to finish before swapping binary');
        try {
          await _waitUntilIdle();
        } on TimeoutException {
          _log('failed: timed out waiting for idle queue');
          return YtDlpUpdateResult.failed(
            'A download is still running; keeping existing yt-dlp',
          );
        }
      }

      return await _downloadAndSwap(release, remote);
    } catch (e, st) {
      _log('failed: $e', e, st);
      return YtDlpUpdateResult.failed(
        'Could not update yt-dlp; keeping existing binary',
      );
    }
  }

  Future<void> _waitUntilIdle() async {
    if (!downloadManager.hasActiveDownload) return;
    final done = Completer<void>();
    void listener() {
      if (!downloadManager.hasActiveDownload && !done.isCompleted) {
        done.complete();
      }
    }

    downloadManager.addListener(listener);
    try {
      await done.future.timeout(const Duration(hours: 2));
    } finally {
      downloadManager.removeListener(listener);
    }
  }

  Future<GitHubReleaseInfo> _fetchLatestRelease() async {
    final body = await _httpGetString(Uri.parse(_latestReleaseUrl));
    return parseGithubReleaseJson(body);
  }

  Future<YtDlpUpdateResult> _downloadAndSwap(
    GitHubReleaseInfo release,
    String remoteVersion,
  ) async {
    if (_swapInFlight) {
      return YtDlpUpdateResult.skipped('An update is already in progress');
    }
    _swapInFlight = true;
    try {
      final assetName = YtDlpPaths.releaseAssetName();
      final asset = release.assetNamed(assetName);
      if (asset == null) {
        _log('failed: no asset named $assetName');
        return YtDlpUpdateResult.failed(
          'Could not find a yt-dlp build for this platform; keeping existing binary',
        );
      }

      final bytes = await _httpGetBytes(
        Uri.parse(asset.browserDownloadUrl),
        expectedLength: asset.size,
      );

      final sumsAsset = release.assetNamed('SHA2-256SUMS');
      if (sumsAsset != null) {
        try {
          final sums = await _httpGetString(Uri.parse(sumsAsset.browserDownloadUrl));
          final expected = sha256ForAsset(sums, assetName);
          if (expected != null) {
            final actual = sha256.convert(bytes).toString();
            if (actual != expected) {
              _log('failed: checksum mismatch for $assetName');
              return YtDlpUpdateResult.failed(
                'yt-dlp download failed verification; keeping existing binary',
              );
            }
          }
        } catch (e) {
          _log('checksum fetch failed, using size check only: $e');
        }
      }

      final target = File(binaryManager.managedYtDlpPath);
      await atomicReplaceBinary(target, bytes);
      binaryManager.ytDlpPath = target.path;
      binaryManager.ytDlpIsManaged = true;
      await settings.saveYtDlpInstalledVersion(remoteVersion);
      _log('success: installed $remoteVersion');
      return YtDlpUpdateResult.updated(remoteVersion);
    } finally {
      _swapInFlight = false;
    }
  }

  Future<String> _httpGetString(Uri uri) async {
    final bytes = await _httpGetBytes(uri);
    return utf8.decode(bytes);
  }

  Future<Uint8List> _httpGetBytes(Uri uri, {int? expectedLength}) async {
    final client = HttpClient();
    try {
      client.userAgent = 'TubeRip/${AppConstants.appVersion}';
      client.connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'TubeRip/${AppConstants.appVersion}',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(const Duration(seconds: 90));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = Uint8List.fromList(builder.takeBytes());
      if (bytes.isEmpty) {
        throw StateError('Empty download from $uri');
      }
      if (response.contentLength > 0 && bytes.length != response.contentLength) {
        throw StateError('Incomplete download from $uri');
      }
      if (expectedLength != null &&
          expectedLength > 0 &&
          bytes.length != expectedLength) {
        throw StateError('Size mismatch downloading $uri');
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'YtDlpUpdater',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
