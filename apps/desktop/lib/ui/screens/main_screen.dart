import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../backend/models.dart';
import '../../services/binary_manager.dart';
import '../../services/download_manager.dart';
import '../../services/settings_service.dart';
import '../../services/yt_dlp_updater.dart';
import '../dialogs/help_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/download_queue_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/format_selector.dart';
import '../widgets/header_bar.dart';
import '../widgets/url_input.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.downloadManager,
    required this.settings,
    required this.themeMode,
    required this.onThemeChanged,
    this.ytDlpUpdater,
  });

  final DownloadManager downloadManager;
  final SettingsService settings;
  final String themeMode;
  final ValueChanged<String> onThemeChanged;
  final YtDlpUpdater? ytDlpUpdater;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _urlController = TextEditingController();
  bool _checkingDeps = true;
  String? _depWarning;

  DownloadManager get dm => widget.downloadManager;

  @override
  void initState() {
    super.initState();
    dm.addListener(_onDm);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final result = await dm.checkDependencies();
    if (!mounted) return;
    setState(() {
      _checkingDeps = false;
      if (!result.ok) {
        _depWarning =
            'Missing: ${result.missing.join(', ')}\n${BinaryManager.installHint(result.missing)}';
      }
    });
    unawaited(_autoUpdateYtDlp());
  }

  Future<void> _autoUpdateYtDlp() async {
    final updater = widget.ytDlpUpdater;
    if (updater == null) return;
    final result = await updater.checkAndUpdate();
    if (!mounted) return;
    if (result.kind == YtDlpUpdateKind.updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  void _onDm() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    dm.removeListener(_onDm);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final deps = await dm.checkDependencies();
    if (!deps.ok && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dependencies missing'),
          content: Text(
            'Missing: ${deps.missing.join(', ')}\n\n'
            '${BinaryManager.installHint(deps.missing)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await dm.enqueue(url);
    _urlController.clear();
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => SettingsDialog(
        config: dm.config,
        themeMode: widget.themeMode,
        settings: widget.settings,
        ytDlpUpdater: widget.ytDlpUpdater,
        onSaved: (config, theme) {
          dm.config = config;
          widget.onThemeChanged(theme);
          setState(() {});
        },
      ),
    );
  }

  Future<void> _openHelp() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const HelpDialog(),
    );
  }

  Future<void> _openFolder(String path) async {
    final uri = Uri.directory(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = dm.config;
    final isAudio = config.mode == DownloadMode.audio;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _openSettings,
        const SingleActivator(LogicalKeyboardKey.slash, control: true):
            _openHelp,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeaderBar(onSettings: _openSettings, onHelp: _openHelp),
              if (_depWarning != null)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade900.withValues(alpha: 0.35),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _depWarning!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(() => _checkingDeps = true);
                          await _boot();
                        },
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _depWarning = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UrlInput(
                        controller: _urlController,
                        onSubmit: _startDownload,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FormatSelector(
                              mode: config.mode,
                              onChanged: (m) async {
                                dm.config = config.copyWith(mode: m);
                                await widget.settings.saveConfig(dm.config);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QualitySelector(
                              mode: config.mode,
                              quality: config.quality,
                              audioFormat: config.audioFormat,
                              onQualityChanged: (q) async {
                                dm.config = config.copyWith(quality: q);
                                await widget.settings.saveConfig(dm.config);
                                setState(() {});
                              },
                              onAudioFormatChanged: (f) async {
                                dm.config = config.copyWith(audioFormat: f);
                                await widget.settings.saveConfig(dm.config);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _checkingDeps ? null : _startDownload,
                          icon: const Icon(Icons.download),
                          label: Text(
                            isAudio ? 'Download Audio' : 'Download Video',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutputSelector(
                        path: config.outputDir,
                        onChanged: (p) async {
                          dm.config = config.copyWith(outputDir: p);
                          await widget.settings.saveConfig(dm.config);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Download Queue',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          if (dm.queue.any(
                            (e) =>
                                e.status.name == 'completed' ||
                                e.status.name == 'cancelled',
                          ))
                            TextButton(
                              onPressed: dm.clearCompleted,
                              child: const Text('Clear finished'),
                            ),
                        ],
                      ),
                      Text(
                        'Recent Downloads',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: dm.queue.isEmpty
                            ? const EmptyState()
                            : ListView.builder(
                                itemCount: dm.queue.length,
                                itemBuilder: (context, index) {
                                  final item = dm.queue[index];
                                  return DownloadQueueItem(
                                    index: index,
                                    item: item,
                                    onPause: () => dm.pause(item.id),
                                    onResume: () => dm.resume(item.id),
                                    onCancel: () => dm.cancel(item.id),
                                    onOpenFolder: () =>
                                        _openFolder(item.config.outputDir),
                                    onRemove: () => dm.remove(item.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
