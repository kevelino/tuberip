import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'services/binary_manager.dart';
import 'services/download_manager.dart';
import 'services/settings_service.dart';
import 'services/yt_dlp_updater.dart';
import 'ui/screens/main_screen.dart';

class TubeRipApp extends StatefulWidget {
  const TubeRipApp({
    super.key,
    required this.settings,
    required this.downloadManager,
    this.ytDlpUpdater,
  });

  final SettingsService settings;
  final DownloadManager downloadManager;
  final YtDlpUpdater? ytDlpUpdater;

  @override
  State<TubeRipApp> createState() => _TubeRipAppState();
}

class _TubeRipAppState extends State<TubeRipApp> {
  String _themePreference = 'dark';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await widget.settings.loadThemeMode();
    if (mounted) setState(() => _themePreference = mode);
  }

  ThemeMode get _themeMode => switch (_themePreference) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: buildTubeRipTheme(brightness: Brightness.light),
      darkTheme: buildTubeRipTheme(brightness: Brightness.dark),
      home: MainScreen(
        downloadManager: widget.downloadManager,
        settings: widget.settings,
        themeMode: _themePreference,
        ytDlpUpdater: widget.ytDlpUpdater,
        onThemeChanged: (mode) {
          setState(() => _themePreference = mode);
        },
      ),
    );
  }
}

/// Convenience factory used by main after settings load.
Future<TubeRipApp> createApp() async {
  final settings = SettingsService();
  await settings.init();
  final config = await settings.loadConfig();
  final binaryManager = BinaryManager(
    customYtDlpPath: config.ytDlpPath,
    customFfmpegPath: config.ffmpegPath,
  );
  final dm = DownloadManager(binaryManager: binaryManager)..config = config;
  final updater = YtDlpUpdater(
    binaryManager: binaryManager,
    downloadManager: dm,
    settings: settings,
  );
  return TubeRipApp(
    settings: settings,
    downloadManager: dm,
    ytDlpUpdater: updater,
  );
}
