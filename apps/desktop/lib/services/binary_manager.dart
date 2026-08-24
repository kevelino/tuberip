import 'dart:io';

import 'package:path/path.dart' as p;

import 'yt_dlp_paths.dart';

/// Locates yt-dlp and ffmpeg on the system (or custom / bundled paths).
class BinaryManager {
  BinaryManager({
    this.customYtDlpPath = '',
    this.customFfmpegPath = '',
    String? managedYtDlpPath,
    List<String>? sidecarDirs,
  }) : _managedYtDlpPathOverride = managedYtDlpPath,
       _sidecarDirsOverride = sidecarDirs;

  String customYtDlpPath;
  String customFfmpegPath;

  String? ytDlpPath;
  String? ffmpegPath;

  /// True when [ytDlpPath] is the writable user-owned copy (auto-update target).
  bool ytDlpIsManaged = false;

  final String? _managedYtDlpPathOverride;
  final List<String>? _sidecarDirsOverride;

  String get managedYtDlpPath =>
      _managedYtDlpPathOverride ?? YtDlpPaths.managedBinaryPath();

  Future<DependencyCheckResult> check() async {
    ytDlpPath = await _resolveYtDlp();
    ffmpegPath = await _resolveFromSearch('ffmpeg', customFfmpegPath);

    final missing = <String>[];
    if (ytDlpPath == null) missing.add('yt-dlp');
    if (ffmpegPath == null) missing.add('ffmpeg');

    return DependencyCheckResult(
      ok: missing.isEmpty,
      missing: missing,
      ytDlpPath: ytDlpPath,
      ffmpegPath: ffmpegPath,
      ytDlpIsManaged: ytDlpIsManaged,
    );
  }

  Future<String?> _resolveYtDlp() async {
    ytDlpIsManaged = false;
    final binaryName = YtDlpPaths.fileName();

    if (customYtDlpPath.isNotEmpty) {
      final file = File(customYtDlpPath);
      if (await file.exists()) {
        return customYtDlpPath;
      }
    }

    final managed = File(managedYtDlpPath);
    if (await managed.exists()) {
      ytDlpIsManaged = true;
      return managed.path;
    }

    final sidecar = await _findSidecar(binaryName);
    if (sidecar != null) {
      try {
        await seedSidecarToManaged(sidecar, managed.path);
        if (await File(managed.path).exists()) {
          ytDlpIsManaged = true;
          return managed.path;
        }
      } catch (_) {
        return sidecar;
      }
      return sidecar;
    }

    return _resolveFromPath(binaryName);
  }

  Future<String?> _findSidecar(String name) async {
    for (final dir in _sidecarDirs()) {
      final candidate = File(p.join(dir, name));
      if (await candidate.exists()) {
        return candidate.path;
      }
    }
    return null;
  }

  /// Directories to search for AppImage / sidecar binaries.
  List<String> _sidecarDirs() {
    if (_sidecarDirsOverride != null) return _sidecarDirsOverride;
    final dirs = <String>{};
    final exe = Platform.resolvedExecutable;
    final exeDir = p.dirname(exe);
    dirs.add(exeDir);
    // Flutter bundle: …/usr/bin/TubeRip/desktop → also check …/usr/bin
    dirs.add(p.dirname(exeDir));
    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty) {
      dirs.add(p.join(appDir, 'usr', 'bin'));
    }
    return dirs.toList();
  }

  Future<String?> _resolveFromSearch(String name, String custom) async {
    if (custom.isNotEmpty) {
      final file = File(custom);
      if (await file.exists()) return custom;
    }

    final sidecar = await _findSidecar(name);
    if (sidecar != null) return sidecar;

    return _resolveFromPath(name);
  }

  Future<String?> _resolveFromPath(String name) async {
    if (!Platform.isWindows) {
      final which = await Process.run('which', [name]);
      if (which.exitCode == 0) {
        final path = which.stdout.toString().trim().split('\n').first;
        if (path.isNotEmpty) return path;
      }
    }

    try {
      final probe = await Process.run(name, ['--version']);
      if (probe.exitCode == 0 || probe.stdout.toString().isNotEmpty) {
        return name;
      }
    } catch (_) {}

    return null;
  }

  /// Short install hints for common Linux distros.
  static String installHint(List<String> missing) {
    final parts = <String>[];
    if (missing.contains('ffmpeg')) {
      parts.add('ffmpeg: sudo dnf install ffmpeg  # or apt install ffmpeg');
    }
    if (missing.contains('yt-dlp')) {
      parts.add('yt-dlp: pipx install yt-dlp  # or sudo dnf install yt-dlp');
    }
    return parts.join('\n');
  }
}

class DependencyCheckResult {
  const DependencyCheckResult({
    required this.ok,
    required this.missing,
    this.ytDlpPath,
    this.ffmpegPath,
    this.ytDlpIsManaged = false,
  });

  final bool ok;
  final List<String> missing;
  final String? ytDlpPath;
  final String? ffmpegPath;
  final bool ytDlpIsManaged;
}
