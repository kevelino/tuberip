import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backend/models.dart';
import '../../core/constants.dart';
import '../../services/binary_manager.dart';
import '../../services/download_manager.dart';
import '../../services/settings_service.dart';
import 'dialogs/help_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'widgets/download_list_item.dart';
import 'widgets/mode_selector.dart';
import 'widgets/output_selector.dart';
import 'widgets/quality_selector.dart';
import 'widgets/title_bar.dart';
import 'widgets/url_input.dart';

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
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _downloadManager?.removeListener(_onDownloadManagerChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _onDownloadManagerChanged() {
    if (mounted) {
      setState(() {});
    }
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

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _startDownload();
      } else if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _openSettings();
      } else if (event.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.slash) {
        _openHelp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
        body: Column(
          children: [
            const TitleBar(),
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
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              'Initialization failed:\n$_errorMessage',
              style: TextStyle(
                color: AppColors.textSecondary,
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
    return Expanded(
      child: Row(
        children: [
          Container(
            width: AppSizes.sidebarWidth,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: _buildSidebar(),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: UrlInput(
                              controller: _urlController,
                              onSubmit: _startDownload,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildDownloadButton(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ModeSelector(
                        selectedMode: _mode,
                        onModeChanged: (m) => setState(() => _mode = m),
                      ),
                      const SizedBox(height: 16),
                      QualitySelector(
                        selectedQuality: _quality,
                        audioFormat: _audioFormat,
                        isAudio: _mode == Mode.audio,
                        onQualityChanged: (v) =>
                            setState(() => _quality = v ?? 'best'),
                        onAudioFormatChanged: (v) =>
                            setState(() => _audioFormat = v ?? 'mp3'),
                      ),
                      const SizedBox(height: 16),
                      OutputSelector(
                        outputDir: _outputDir,
                        onOutputDirChanged: (dir) {
                          setState(() => _outputDir = dir);
                          _settingsService.setOutputDir(dir);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildDownloadList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    final bool canDownload = _urlController.text.trim().isNotEmpty;
    return MouseRegion(
      cursor: canDownload
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: canDownload ? _startDownload : null,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: canDownload ? AppColors.cyan : AppColors.border,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          ),
          child: Row(
            children: [
              Icon(
                _mode == Mode.video
                    ? Icons.videocam_outlined
                    : Icons.audio_file_outlined,
                size: 14,
                color: canDownload
                    ? AppColors.background
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _mode == Mode.video
                    ? AppStrings.downloadVideo
                    : AppStrings.downloadAudio,
                style: TextStyle(
                  color: canDownload
                      ? AppColors.background
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadList() {
    if (_downloadManager!.downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No downloads yet',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a YouTube URL and click download to get started.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ListView.builder(
        itemCount: _downloadManager!.downloads.length,
        itemBuilder: (context, index) {
          final item = _downloadManager!.downloads[index];
          return DownloadListItem(
            item: item,
            onPause: () => _downloadManager!.pauseDownload(item),
            onResume: () => _downloadManager!.resumeDownload(item),
            onCancel: () => _downloadManager!.cancelDownload(item),
            onRetry: () => _downloadManager!.startDownload(
              url: item.url,
              config: item.config ??
                  _settingsService.buildConfig(
                    mode: _mode,
                    quality: _quality,
                    audioFormat: _audioFormat,
                    outputDir: _outputDir,
                  ),
            ),
            onRemove: () => _downloadManager!.removeDownload(item),
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        Container(
          height: 120,
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.circle,
                size: 32,
                color: AppColors.cyan,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
              _buildNavItem(Icons.settings_outlined, 'Settings', false,
                  onTap: _openSettings),
              const SizedBox(height: 8),
              _buildNavItem(Icons.help_outline, 'Help', false,
                  onTap: _openHelp),
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
              color: AppColors.textMuted,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.background
                      : AppColors.textSecondary,
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
