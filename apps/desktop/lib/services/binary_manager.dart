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
  String? nodePath;

  /// True when [ytDlpPath] is the writable user-owned copy (auto-update target).
  bool ytDlpIsManaged = false;

  final String? _managedYtDlpPathOverride;
  final List<String>? _sidecarDirsOverride;

  String get managedYtDlpPath =>
      _managedYtDlpPathOverride ?? YtDlpPaths.managedBinaryPath();

  Future<DependencyCheckResult> check() async {
    ytDlpPath = await _resolveYtDlp();
    ffmpegPath = await _resolveFromSearch('ffmpeg', customFfmpegPath);
    nodePath = await _resolveNode();

    final missing = <String>[];
    if (ytDlpPath == null) missing.add('yt-dlp');
    if (ffmpegPath == null) missing.add('ffmpeg');

    return DependencyCheckResult(
      ok: missing.isEmpty,
      missing: missing,
      ytDlpPath: ytDlpPath,
      ffmpegPath: ffmpegPath,
      nodePath: nodePath,
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
    dirs.add(p.join(exeDir, 'data'));
    dirs.add(p.join(exeDir, 'bin'));
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

    final exeName =
        Platform.isWindows && !name.toLowerCase().endsWith('.exe')
            ? '$name.exe'
            : name;

    final sidecar = await _findSidecar(exeName) ?? await _findSidecar(name);
    if (sidecar != null) return sidecar;

    return _resolveFromPath(exeName);
  }

  /// Node.js is required by yt-dlp's EJS/n-challenge solver (--remote-components).
  Future<String?> _resolveNode() async {
    final nodeName = Platform.isWindows ? 'node.exe' : 'node';
    final fromPath =
        await _resolveFromPath(nodeName) ?? await _resolveFromPath('node');
    if (fromPath != null && fromPath != nodeName && fromPath != 'node') {
      return fromPath;
    }

    if (Platform.isWindows) {
      final programFiles =
          Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
      final programFilesX86 =
          Platform.environment['ProgramFiles(x86)'] ??
          r'C:\Program Files (x86)';
      final candidates = [
        p.join(programFiles, 'nodejs', 'node.exe'),
        p.join(programFilesX86, 'nodejs', 'node.exe'),
      ];
      for (final candidate in candidates) {
        if (await File(candidate).exists()) {
          return candidate;
        }
      }
      return fromPath;
    }

    const candidates = [
      '/usr/bin/node',
      '/usr/local/bin/node',
      '/snap/bin/node',
    ];
    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }
    return fromPath;
  }

  Future<String?> _resolveFromPath(String name) async {
    if (Platform.isWindows) {
      try {
        final where = await Process.run('where.exe', [name]);
        if (where.exitCode == 0) {
          final path =
              where.stdout
                  .toString()
                  .trim()
                  .split(RegExp(r'[\r\n]+'))
                  .first
                  .trim();
          if (path.isNotEmpty && await File(path).exists()) return path;
        }
      } catch (_) {}
    } else {
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

  /// Short install hints for common Linux and Windows distros.
  static String installHint(List<String> missing) {
    final parts = <String>[];
    if (Platform.isWindows) {
      if (missing.contains('ffmpeg')) {
        parts.add(
          'ffmpeg: winget install Gyan.FFmpeg  # or choco install ffmpeg',
        );
      }
      if (missing.contains('yt-dlp')) {
        parts.add('yt-dlp: winget install yt-dlp  # or pip install yt-dlp');
      }
      return parts.join('\n');
    }

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
    this.nodePath,
    this.ytDlpIsManaged = false,
  });

  final bool ok;
  final List<String> missing;
  final String? ytDlpPath;
  final String? ffmpegPath;
  final String? nodePath;
  final bool ytDlpIsManaged;
}
