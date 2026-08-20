import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/downloader.dart';
import '../../backend/models.dart';
import '../../core/constants.dart';
import '../../core/theme_tokens.dart';
import '../../services/binary_manager.dart';
import '../../services/download_manager.dart';
import '../../services/settings_service.dart';
import '../dialogs/help_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/download_queue_item.dart';
import '../widgets/header_bar.dart';
import '../widgets/format_selector.dart';

import 'package:tuberip/ui/widgets/output_selector.dart';

import 'package:tuberip/ui/widgets/quality_selector.dart';

import 'package:tuberip/ui/widgets/url_input.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late TextEditingController _urlController;
  late SettingsService _settingsService;

  DownloadManager? _downloadManager;

  Mode _mode = Mode.video;
  String _quality = 'best';
  String _audioFormat = 'mp3';
  String _outputDir = '';
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, dynamic> _settingsMap = {};

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _initServices();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _downloadManager?.removeListener(_onDownloadManagerChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _onDownloadManagerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initServices() async {
    try {
      _settingsService = await SettingsService.create();
      _settingsMap.addAll({
        'audioQuality': _settingsService.audioQuality,
        'subtitleLang': _settingsService.subtitleLang,
        'downloadSubtitles': _settingsService.downloadSubtitles,
        'embedThumbnail': _settingsService.embedThumbnail,
        'embedMetadata': _settingsService.embedMetadata,
        'rateLimit': _settingsService.rateLimit,
      });
      _outputDir = _settingsService.outputDir;

      await BinaryManager.initialize();
      Downloader.ytDlpPath = await BinaryManager.ytDlpPath;
      Downloader.ffmpegPath = BinaryManager.ffmpegPath!;

      _downloadManager = DownloadManager(_settingsService);
      _downloadManager!.addListener(_onDownloadManagerChanged);
      await _downloadManager!.initialize();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startDownload() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final config = _settingsService.buildConfig(
      mode: _mode,
      quality: _quality,
      audioFormat: _audioFormat,
      outputDir: _outputDir,
    );

    _downloadManager!.startDownload(url: url, config: config);
    _urlController.clear();
    setState(() {});
  }

  Future<void> _revealFile(DownloadItem item) async {
    final dir = item.config?.outputDir ?? _outputDir;
    if (dir.isEmpty) return;
    final cmd = Platform.isMacOS
        ? 'open'
        : Platform.isWindows
        ? 'explorer'
        : 'xdg-open';
    try {
      await Process.run(cmd, [dir]);
    } catch (_) {
      // Best-effort: ignore failures to open the file manager.
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => SettingsDialog(
        settings: Map<String, dynamic>.of(_settingsMap),
        onApply: (updated) {
          _settingsMap.addAll(updated);
          _settingsService.saveMap(updated);
        },
      ),
    );
  }

  void _openHelp() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const HelpDialog(),
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _startDownload();
        return true;
      }
      if (HardwareKeyboard.instance.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _openSettings();
          return true;
        }
        if (event.logicalKey == LogicalKeyboardKey.slash) {
          _openHelp();
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          HeaderBar(onSettings: _openSettings, onHelp: _openHelp),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.cyan,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorState()
          else
            _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final tokens = TubeRipTheme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.errorText),
            const SizedBox(height: 12),
            Text(
              'Initialization failed:\n$_errorMessage',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final tokens = TubeRipTheme.of(context);
    return Expanded(
      child: Row(
        children: [
          Container(
            width: AppSizes.sidebarWidth,
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border(right: BorderSide(color: tokens.border, width: 1)),
            ),
            child: _buildSidebar(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 600;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(tokens.spaceXl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UrlInput(
                              controller: _urlController,
                              onSubmit: _startDownload,
                            ),
                            SizedBox(height: tokens.spaceLg),
                            _buildOptionsRow(narrow),
                            SizedBox(height: tokens.spaceLg),
                            _buildDownloadButton(),
                            SizedBox(height: tokens.spaceMd),
                            _buildSaveToRow(),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: tokens.border,
                        indent: tokens.spaceXl,
                        endIndent: tokens.spaceXl,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          tokens.spaceXl,
                          tokens.spaceLg,
                          tokens.spaceXl,
                          tokens.spaceSm,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download Queue',
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Recent Downloads',
                                style: TextStyle(
                                  color: tokens.textMuted,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildDownloadList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow(bool narrow) {
    final tokens = TubeRipTheme.of(context);
    final format = FormatSelector(
      selectedMode: _mode,
      onModeChanged: (m) => setState(() => _mode = m),
    );
    final quality = QualitySelector(
      selectedQuality: _quality,
      audioFormat: _audioFormat,
      isAudio: _mode == Mode.audio,
      onQualityChanged: (v) => setState(() => _quality = v ?? 'best'),
      onAudioFormatChanged: (v) => setState(() => _audioFormat = v ?? 'mp3'),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          format,
          SizedBox(height: tokens.spaceSm),
          quality,
          SizedBox(height: tokens.spaceSm),
          Align(alignment: Alignment.centerRight, child: _gearButton()),
        ],
      );
    }

    return Row(
      children: [
        format,
        SizedBox(width: tokens.spaceSm),
        quality,
        const Spacer(),
        _gearButton(),
      ],
    );
  }

  Widget _gearButton() {
    final tokens = TubeRipTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openSettings,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: Icon(
            Icons.tune_outlined,
            size: 18,
            color: tokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    final tokens = TubeRipTheme.of(context);
    final canDownload = _urlController.text.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: MouseRegion(
        cursor: canDownload
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: canDownload ? _startDownload : null,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: canDownload
                  ? LinearGradient(colors: [tokens.primary, tokens.primaryAlt])
                  : null,
              color: canDownload ? null : tokens.border,
              borderRadius: BorderRadius.circular(tokens.radiusXl),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _mode == Mode.video
                      ? Icons.videocam_outlined
                      : Icons.audio_file_outlined,
                  size: 16,
                  color: canDownload ? tokens.background : tokens.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  canDownload
                      ? (_mode == Mode.video
                            ? AppStrings.downloadVideo
                            : AppStrings.downloadAudio)
                      : 'Enter a URL to download',
                  style: TextStyle(
                    color: canDownload ? tokens.background : tokens.textMuted,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveToRow() {
    final tokens = TubeRipTheme.of(context);
    return Row(
      children: [
        Text(
          AppStrings.saveToLabel,
          style: TextStyle(
            color: tokens.textMuted,
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutputSelector(
            outputDir: _outputDir,
            compact: true,
            onOutputDirChanged: (dir) {
              setState(() => _outputDir = dir);
              _settingsService.setOutputDir(dir);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadList() {
    final tokens = TubeRipTheme.of(context);
    if (_downloadManager!.downloads.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        tokens.spaceXl,
        tokens.spaceSm,
        tokens.spaceXl,
        tokens.spaceXl,
      ),
      itemCount: _downloadManager!.downloads.length,
      itemBuilder: (context, index) {
        final item = _downloadManager!.downloads[index];
        return DownloadQueueItem(
          item: item,
          onPause: () => _downloadManager!.pauseDownload(item),
          onResume: () => _downloadManager!.resumeDownload(item),
          onCancel: () => _downloadManager!.cancelDownload(item),
          onRetry: () => _downloadManager!.startDownload(
            url: item.url,
            config:
                item.config ??
                _settingsService.buildConfig(
                  mode: _mode,
                  quality: _quality,
                  audioFormat: _audioFormat,
                  outputDir: _outputDir,
                ),
          ),
          onRemove: () => _downloadManager!.removeDownload(item),
          onReveal: () => _revealFile(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final tokens = TubeRipTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined, size: 56, color: tokens.textMuted),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a YouTube URL and click download to get started.',
            style: TextStyle(
              color: tokens.textMuted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final tokens = TubeRipTheme.of(context);
    return Column(
      children: [
        Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, size: 32, color: AppColors.cyan),
              const SizedBox(height: 8),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildNavItem(Icons.download_outlined, 'Downloads', true),
              const SizedBox(height: 8),
              _buildNavItem(Icons.info_outline, 'About', false),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          child: Text(
            'v0.1.0',
            style: TextStyle(
              color: tokens.textMuted,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool selected, {
    VoidCallback? onTap,
  }) {
    final tokens = TubeRipTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? tokens.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? tokens.background : tokens.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: selected ? tokens.background : tokens.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
