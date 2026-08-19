import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BinaryManager {
  static String? _ytDlpPath;
  static String? _ffmpegPath;

  static Future<String> get ytDlpPath async {
    if (_ytDlpPath != null) return _ytDlpPath!;
    _ytDlpPath = await _resolveBinary('yt-dlp');
    return _ytDlpPath!;
  }

  static String? get ffmpegPath => _ffmpegPath ??= _resolveSystemBinary('ffmpeg');

  static Future<String> _resolveBinary(String name) async {
    final systemPath = _resolveSystemBinary(name);
    if (systemPath != null) return systemPath;

    // Fall back to checking apt/pip managed locations
    final aptPath = _checkAptPath(name);
    if (aptPath != null) return aptPath;

    // Last resort: ask user to install
    throw Exception(
        '$name not found on PATH. Run: pip3 install --user -U yt-dlp '
        'and: sudo apt install ffmpeg');
  }

  static String? _resolveSystemBinary(String name) {
    try {
      final result = Process.runSync('which', [name]);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return null;
  }

  static String? _checkAptPath(String name) {
    final candidates = [
      '/usr/bin/$name',
      '/usr/local/bin/$name',
      '${Platform.environment["HOME"]}/.local/bin/$name',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        return path;
      }
    }
    return null;
  }

  static Future<void> initialize() async {
    // Verify both binaries are available on the system
    _ytDlpPath = await _resolveBinary('yt-dlp');
    _ffmpegPath = _resolveSystemBinary('ffmpeg') ?? _checkAptPath('ffmpeg');

    if (_ffmpegPath == null) {
      throw Exception('ffmpeg not found on PATH. Run: sudo apt install ffmpeg');
    }
  }
}
