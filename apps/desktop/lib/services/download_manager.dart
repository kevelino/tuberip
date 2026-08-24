import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../backend/models.dart';
import '../backend/progress_parser.dart';
import '../backend/yt_dlp_command.dart';
import '../core/download_status.dart';
import 'binary_manager.dart';

/// Sequential download queue backed by a yt-dlp [Process].
class DownloadManager extends ChangeNotifier {
  DownloadManager({
    required this.binaryManager,
    YtDlpCommandBuilder? commandBuilder,
    ProgressParser? progressParser,
  })  : _commands = commandBuilder ?? const YtDlpCommandBuilder(),
        _parser = progressParser ?? const ProgressParser();

  final BinaryManager binaryManager;
  final YtDlpCommandBuilder _commands;
  final ProgressParser _parser;

  DownloadConfig config = DownloadConfig();
  final List<DownloadItem> queue = [];

  Process? _activeProcess;
  String? _activeItemId;
  bool _paused = false;
  bool _processing = false;
  DependencyCheckResult? lastDependencyCheck;

  bool get hasActiveDownload =>
      _processing || _activeProcess != null || _activeItemId != null;

  DownloadItem? get activeItem {
    if (_activeItemId == null) return null;
    try {
      return queue.firstWhere((e) => e.id == _activeItemId);
    } catch (_) {
      return null;
    }
  }

  Future<DependencyCheckResult> checkDependencies() async {
    binaryManager.customYtDlpPath = config.ytDlpPath;
    binaryManager.customFfmpegPath = config.ffmpegPath;
    lastDependencyCheck = await binaryManager.check();
    notifyListeners();
    return lastDependencyCheck!;
  }

  Future<void> enqueue(String rawUrl) async {
    final url = YtDlpCommandBuilder.buildUrl(rawUrl);
    final item = DownloadItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      title: url,
      status: DownloadStatus.queued,
      config: config.copyWith(),
    );
    queue.insert(0, item);
    notifyListeners();

    // Fire-and-forget metadata enrich
    unawaited(_enrichMetadata(item));

    await _pumpQueue();
  }

  Future<void> _enrichMetadata(DownloadItem item) async {
    final yt = binaryManager.ytDlpPath ?? 'yt-dlp';
    final args = _commands.buildMetadataCommand(
      url: item.url,
      ytDlpExecutable: yt,
      cookieBrowser: item.config.cookieBrowser,
      cookiesFile: item.config.cookiesFile,
    );
    try {
      final result = await Process.run(
        args.first,
        args.sublist(1),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 45));
      if (result.exitCode != 0) return;
      final line = result.stdout.toString().trim().split('\n').first;
      if (line.isEmpty) return;
      final json = jsonDecode(line) as Map<String, dynamic>;
      item.title = (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : item.title;
      item.thumbnailUrl = json['thumbnail'] as String?;
      final dur = json['duration'];
      if (dur is num) {
        final secs = dur.round();
        final m = secs ~/ 60;
        final s = secs % 60;
        item.duration = '$m:${s.toString().padLeft(2, '0')}';
      }
      notifyListeners();
    } catch (_) {
      // Metadata is best-effort.
    }
  }

  Future<void> _pumpQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      while (true) {
        DownloadItem? next;
        for (final item in queue) {
          if (item.status == DownloadStatus.queued) {
            next = item;
            break;
          }
        }
        if (next == null) break;
        await _runDownload(next);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _runDownload(DownloadItem item) async {
    final deps = await checkDependencies();
    if (!deps.ok) {
      item.status = DownloadStatus.error;
      item.error =
          'Missing dependencies: ${deps.missing.join(', ')}\n${BinaryManager.installHint(deps.missing)}';
      notifyListeners();
      return;
    }

    if (item.status == DownloadStatus.cancelled) return;

    final yt = deps.ytDlpPath!;
    // Prefer resolved ffmpeg path for --ffmpeg-location
    if (item.config.ffmpegPath.isEmpty && deps.ffmpegPath != null) {
      item.config.ffmpegPath = deps.ffmpegPath!;
    }

    item.status = DownloadStatus.downloading;
    item.progress = 0;
    item.error = null;
    item.speed = null;
    item.eta = null;
    _activeItemId = item.id;
    _paused = false;
    notifyListeners();

    final args = _commands.buildCommand(
      url: item.url,
      config: item.config,
      ytDlpExecutable: yt,
    );

    final errorLines = <String>[];

    try {
      Directory(item.config.outputDir).createSync(recursive: true);

      _activeProcess = await Process.start(
        args.first,
        args.sublist(1),
        runInShell: false,
      );

      final stdoutDone = _activeProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (_parser.isErrorLine(line)) {
          errorLines.add(line);
        }
        final percent = _parser.parsePercent(line);
        if (percent != null) {
          item.progress = percent.clamp(0, 100);
          final info = _parser.parseSpeedInfo(line);
          if (info.speed != null) item.speed = info.speed;
          if (info.eta != null) item.eta = info.eta;
          notifyListeners();
        }
      }).asFuture<void>();

      final stderrDone = _activeProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (_parser.isErrorLine(line) || line.trim().isNotEmpty) {
          if (_parser.isErrorLine(line)) errorLines.add(line);
        }
      }).asFuture<void>();

      final code = await _activeProcess!.exitCode;
      await stdoutDone;
      await stderrDone;

      if (item.status == DownloadStatus.cancelled) {
        notifyListeners();
        return;
      }

      if (code == 0) {
        item.status = DownloadStatus.completed;
        item.progress = 100;
        item.speed = null;
        item.eta = null;
      } else {
        item.status = DownloadStatus.error;
        item.error = _parser.formatDownloadError(
          errorLines: errorLines,
          exitCode: code,
        );
      }
    } on ProcessException catch (e) {
      item.status = DownloadStatus.error;
      item.error = 'Failed to start yt-dlp: $e';
    } catch (e) {
      if (item.status != DownloadStatus.cancelled) {
        item.status = DownloadStatus.error;
        item.error = e.toString();
      }
    } finally {
      _activeProcess = null;
      _activeItemId = null;
      _paused = false;
      notifyListeners();
    }
  }

  Future<void> pause(String itemId) async {
    if (!Platform.isLinux && !Platform.isMacOS) return;
    final item = _find(itemId);
    if (item == null || item.status != DownloadStatus.downloading) return;
    final proc = _activeProcess;
    if (proc == null || _paused) return;
    try {
      Process.killPid(proc.pid, ProcessSignal.sigstop);
      _paused = true;
      item.status = DownloadStatus.paused;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> resume(String itemId) async {
    if (!Platform.isLinux && !Platform.isMacOS) return;
    final item = _find(itemId);
    if (item == null || item.status != DownloadStatus.paused) return;
    final proc = _activeProcess;
    if (proc == null || !_paused) return;
    try {
      Process.killPid(proc.pid, ProcessSignal.sigcont);
      _paused = false;
      item.status = DownloadStatus.downloading;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cancel(String itemId) async {
    final item = _find(itemId);
    if (item == null) return;

    if (item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.pending) {
      item.status = DownloadStatus.cancelled;
      notifyListeners();
      return;
    }

    item.status = DownloadStatus.cancelled;
    final proc = _activeProcess;
    if (proc != null && _activeItemId == itemId) {
      if (_paused) {
        try {
          Process.killPid(proc.pid, ProcessSignal.sigcont);
        } catch (_) {}
      }
      proc.kill(ProcessSignal.sigterm);
      try {
        await proc.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        proc.kill(ProcessSignal.sigkill);
      }
    }
    notifyListeners();
  }

  void remove(String itemId) {
    queue.removeWhere((e) => e.id == itemId);
    notifyListeners();
  }

  void clearCompleted() {
    queue.removeWhere(
      (e) =>
          e.status == DownloadStatus.completed ||
          e.status == DownloadStatus.cancelled,
    );
    notifyListeners();
  }

  DownloadItem? _find(String id) {
    try {
      return queue.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
