import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/utils.dart';
import 'models.dart';

class DependencyError extends Error {
  final String message;
  DependencyError(this.message);

  @override
  String toString() => message;
}

class Downloader {
  final DownloadConfig config;
  Process? _process;
  bool _isPaused = false;

  Downloader(this.config);

  static Future<void> checkDependencies(String ytDlpPath, String ffmpegPath) async {
    final errors = <String>[];

    final ytDlpResult = await Process.run(ytDlpPath, ['--version']);
    if (ytDlpResult.exitCode != 0) {
      errors.add('yt-dlp');
    }

    final ffmpegResult = await Process.run(ffmpegPath, ['-version']);
    if (ffmpegResult.exitCode != 0) {
      errors.add('ffmpeg');
    }

    if (errors.isNotEmpty) {
      throw DependencyError(
          'Missing dependencies: ${errors.join(', ')}. Install them and retry.');
    }
  }

  static String buildUrl(String videoId) {
    if (videoId.startsWith('http')) return videoId;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  String buildFormat() {
    if (config.mode == Mode.audio) {
      return 'bestaudio/best';
    }
    final quality = config.quality;
    if (quality == 'best') {
      return 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best';
    }
    return 'bestvideo[height<=$quality][ext=mp4]+bestaudio[ext=m4a]/best[height<=$quality]';
  }

  List<String> buildCommand(String url) {
    final outputTemplate = '${config.outputDir}/%(title)s [%(id)s].%(ext)s';
    final cmd = <String>[
      ytDlpPath,
      '-o',
      outputTemplate,
      '--retries',
      '10',
      '--fragment-retries',
      '10',
      '--socket-timeout',
      '30',
      '--no-abort-on-error',
      '--progress',
    ];

    if (config.mode == Mode.audio) {
      cmd.addAll([
        '-x',
        '--audio-format',
        config.audioFormat,
        '--audio-quality',
        config.audioQuality,
      ]);
    } else {
      cmd.addAll([
        '-f',
        buildFormat(),
        '--merge-output-format',
        'mp4',
      ]);
    }

    if (config.downloadSubtitles) {
      cmd.addAll([
        '--write-sub',
        '--write-auto-sub',
        '--sub-lang',
        config.subtitleLang,
        '--convert-subs',
        'srt',
      ]);
    }

    if (config.embedThumbnail) {
      cmd.add('--embed-thumbnail');
    }

    if (config.embedMetadata) {
      cmd.add('--embed-metadata');
    }

    if (config.rateLimit.isNotEmpty) {
      cmd.addAll(['--limit-rate', config.rateLimit]);
    }

    cmd.add(url);
    return cmd;
  }

  // yt-dlp and ffmpeg paths (set by BinaryManager)
  static late String ytDlpPath;
  static late String ffmpegPath;

  Future<Map<String, dynamic>> fetchMetadata(String url) async {
    final fullUrl = buildUrl(url);
    try {
      final result = await Process.run(
        ytDlpPath,
        ['--dump-json', '--no-warnings', fullUrl],
      );
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        final lines = result.stdout.toString().trim().split('\n');
        if (lines.isNotEmpty) {
          return Map<String, dynamic>.from(
            (const JsonDecoder()).convert(lines.first) as Map,
          );
        }
      }
    } catch (_) {
      // Return empty map on any error
    }
    return {};
  }

  Future<void> download(
    DownloadItem item, {
    void Function(double)? onProgress,
    void Function(String)? onStatus,
    void Function(String)? onSpeed,
  }) async {
    if (item.status == 'cancelled') {
      onStatus?.call('cancelled');
      return;
    }

    final url = buildUrl(item.url);
    item.url = url;
    item.config = config;
    item.status = 'downloading';
    item.progress = 0.0;
    item.error = null;

    onStatus?.call('downloading');

    final cmd = buildCommand(url);

    try {
      _process = await Process.start(
        cmd.first,
        cmd.sublist(1),
        runInShell: false,
      );

      // Listen to stdout for progress updates
      _process!.stdout
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen((line) {
        if (item.status == 'cancelled') {
          return;
        }

        line = line.strip();

        if (line.contains('[download]') && line.contains('%')) {
          final percentStr = AppUtils.parsePercent(line);
          if (percentStr.isNotEmpty) {
            final pct = double.tryParse(percentStr);
            if (pct != null) {
              item.progress = pct;
              onProgress?.call(pct);
            }
          }

          final speedStr = AppUtils.parseSpeed(line);
          if (speedStr.isNotEmpty && onSpeed != null) {
            onSpeed(speedStr);
          }
        }
      });

      // Continuously drain stderr and retain the latest meaningful output
      String? latestStderr;
      _process!.stderr
          .transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen((line) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          latestStderr = trimmed;
        }
      });

      // Wait for process to complete
      final exitCode = await _process!.exitCode;
      _process = null;

      // Small delay to ensure stdout listener has flushed
      await Future.delayed(const Duration(milliseconds: 100));

      if (item.status == 'cancelled') {
        onStatus?.call('cancelled');
        return;
      }

      if (exitCode == 0) {
        item.status = 'done';
        item.progress = 100.0;
        onProgress?.call(100.0);
        onStatus?.call('done');
      } else {
        item.status = 'error';
        item.error = 'yt-dlp exited with code $exitCode'
            '${latestStderr != null ? ": $latestStderr" : ""}';
        onStatus?.call('error');
      }
    } on ProcessException catch (e) {
      item.status = 'error';
      item.error = 'Command not found: ${e.message}';
      onStatus?.call('error');
    } catch (e) {
      item.status = 'error';
      item.error = e.toString();
      onStatus?.call('error');
    } finally {
      _process = null;
    }
  }

  void pause() {
    if (_process != null && !_isPaused) {
      try {
        // SIGSTOP on Linux
        _process!.kill(ProcessSignal.sigstop);
        _isPaused = true;
      } catch (_) {}
    }
  }

  void resume() {
    if (_process != null && _isPaused) {
      try {
        _process!.kill(ProcessSignal.sigcont);
        _isPaused = false;
      } catch (_) {}
    }
  }

  void cancel() {
    if (_process != null) {
      if (_isPaused) {
        try {
          _process!.kill(ProcessSignal.sigcont);
        } catch (_) {}
      }
      _process!.kill();
      _isPaused = false;
    }
  }
}

extension on String {
  String strip() => trim();
}
