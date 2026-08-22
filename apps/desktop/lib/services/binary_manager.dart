import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates yt-dlp and ffmpeg on the system (or custom / bundled paths).
class BinaryManager {
  BinaryManager({
    this.customYtDlpPath = '',
    this.customFfmpegPath = '',
  });

  String customYtDlpPath;
  String customFfmpegPath;

  String? ytDlpPath;
  String? ffmpegPath;

  Future<DependencyCheckResult> check() async {
    ytDlpPath = await _resolve('yt-dlp', customYtDlpPath);
    ffmpegPath = await _resolve('ffmpeg', customFfmpegPath);

    final missing = <String>[];
    if (ytDlpPath == null) missing.add('yt-dlp');
    if (ffmpegPath == null) missing.add('ffmpeg');

    return DependencyCheckResult(
      ok: missing.isEmpty,
      missing: missing,
      ytDlpPath: ytDlpPath,
      ffmpegPath: ffmpegPath,
    );
  }

  /// Directories to search for AppImage / sidecar binaries.
  List<String> _sidecarDirs() {
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

  Future<String?> _resolve(String name, String custom) async {
    if (custom.isNotEmpty) {
      final file = File(custom);
      if (await file.exists()) return custom;
    }

    for (final dir in _sidecarDirs()) {
      final candidate = File(p.join(dir, name));
      if (await candidate.exists()) {
        return candidate.path;
      }
    }

    final which = await Process.run('which', [name]);
    if (which.exitCode == 0) {
      final path = which.stdout.toString().trim().split('\n').first;
      if (path.isNotEmpty) return path;
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
  });

  final bool ok;
  final List<String> missing;
  final String? ytDlpPath;
  final String? ffmpegPath;
}
