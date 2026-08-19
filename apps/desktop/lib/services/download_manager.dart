import 'package:flutter/foundation.dart';

import '../backend/downloader.dart';
import '../backend/models.dart';
import '../services/binary_manager.dart';
import '../services/settings_service.dart';

class DownloadManager extends ChangeNotifier {
  final SettingsService settingsService;
  final List<DownloadItem> downloads = [];
  final Map<String, Downloader> _activeDownloaders = {};

  bool _isFetchingMetadata = false;

  bool get isFetchingMetadata => _isFetchingMetadata;

  DownloadManager(this.settingsService);

  Future<void> initialize() async {
    await Downloader.checkDependencies(
      await BinaryManager.ytDlpPath,
      BinaryManager.ffmpegPath,
    );
  }

  Future<void> startDownload({
    required String url,
    required DownloadConfig config,
  }) async {
    final item = DownloadItem(url: Downloader.buildUrl(url))
      ..config = config
      ..status = 'downloading'
      ..progress = 0.0;

    downloads.insert(0, item);
    notifyListeners();

    final downloader = Downloader(config);
    _activeDownloaders[item.url] = downloader;

    await _activeDownloaders[item.url]!.download(
      item,
      onProgress: (p) {
        item.progress = p;
        notifyListeners();
      },
      onStatus: (s) {
        item.status = s;
        notifyListeners();
        if (s == 'done' || s == 'error' || s == 'cancelled') {
          _activeDownloaders.remove(item.url);
        }
      },
    );

    notifyListeners();
  }

  void pauseDownload(DownloadItem item) {
    final d = _activeDownloaders[item.url];
    if (d != null) {
      d.pause();
      item.status = 'paused';
      notifyListeners();
    }
  }

  void resumeDownload(DownloadItem item) {
    final d = _activeDownloaders[item.url];
    if (d != null) {
      d.resume();
      item.status = 'downloading';
      notifyListeners();
    }
  }

  void cancelDownload(DownloadItem item) {
    final d = _activeDownloaders[item.url];
    if (d != null) {
      d.cancel();
      _activeDownloaders.remove(item.url);
    }
    item.status = 'cancelled';
    notifyListeners();
  }

  void removeDownload(DownloadItem item) {
    final d = _activeDownloaders[item.url];
    if (d != null) {
      d.cancel();
      _activeDownloaders.remove(item.url);
    }
    downloads.remove(item);
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchMetadata(String url) async {
    final fullUrl = Downloader.buildUrl(url);
    _isFetchingMetadata = true;
    notifyListeners();
    try {
      Downloader.ytDlpPath = await BinaryManager.ytDlpPath;
      Downloader.ffmpegPath = BinaryManager.ffmpegPath;

      final downloader = Downloader(settingsService.buildConfig(
        mode: Mode.video,
        quality: 'best',
        audioFormat: 'mp3',
      ));
      return await downloader.fetchMetadata(fullUrl);
    } finally {
      _isFetchingMetadata = false;
      notifyListeners();
    }
  }
}
