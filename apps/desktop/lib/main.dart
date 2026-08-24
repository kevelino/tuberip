import 'package:flutter/material.dart';

import 'app.dart';
import 'services/binary_manager.dart';
import 'services/download_manager.dart';
import 'services/settings_service.dart';
import 'services/yt_dlp_updater.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsService();
  await settings.init();
  final config = await settings.loadConfig();

  final binaryManager = BinaryManager(
    customYtDlpPath: config.ytDlpPath,
    customFfmpegPath: config.ffmpegPath,
  );
  final downloadManager = DownloadManager(binaryManager: binaryManager)
    ..config = config;
  final ytDlpUpdater = YtDlpUpdater(
    binaryManager: binaryManager,
    downloadManager: downloadManager,
    settings: settings,
  );

  runApp(
    TubeRipApp(
      settings: settings,
      downloadManager: downloadManager,
      ytDlpUpdater: ytDlpUpdater,
    ),
  );
}
