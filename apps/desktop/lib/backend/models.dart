import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/download_status.dart';

enum DownloadMode { video, audio }

class DownloadConfig {
  DownloadConfig({
    this.mode = DownloadMode.video,
    this.quality = '480',
    this.audioFormat = 'mp3',
    this.audioQuality = '0',
    this.subtitleLang = 'fr,en',
    this.downloadSubtitles = false,
    this.embedThumbnail = true,
    this.embedMetadata = true,
    this.cookieBrowser = 'firefox',
    this.cookiesFile = '',
    this.ytDlpPath = '',
    this.ffmpegPath = '',
    String? outputDir,
  }) : outputDir = outputDir ??
            p.join(
              Platform.environment['HOME'] ??
                  Directory.systemTemp.path,
              'Downloads',
              'YouTube',
            );

  DownloadMode mode;
  String quality;
  String audioFormat;
  String audioQuality;
  String subtitleLang;
  bool downloadSubtitles;
  bool embedThumbnail;
  bool embedMetadata;
  String cookieBrowser;
  String cookiesFile;
  String ytDlpPath;
  String ffmpegPath;
  String outputDir;

  DownloadConfig copyWith({
    DownloadMode? mode,
    String? quality,
    String? audioFormat,
    String? audioQuality,
    String? subtitleLang,
    bool? downloadSubtitles,
    bool? embedThumbnail,
    bool? embedMetadata,
    String? cookieBrowser,
    String? cookiesFile,
    String? ytDlpPath,
    String? ffmpegPath,
    String? outputDir,
  }) {
    return DownloadConfig(
      mode: mode ?? this.mode,
      quality: quality ?? this.quality,
      audioFormat: audioFormat ?? this.audioFormat,
      audioQuality: audioQuality ?? this.audioQuality,
      subtitleLang: subtitleLang ?? this.subtitleLang,
      downloadSubtitles: downloadSubtitles ?? this.downloadSubtitles,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      cookieBrowser: cookieBrowser ?? this.cookieBrowser,
      cookiesFile: cookiesFile ?? this.cookiesFile,
      ytDlpPath: ytDlpPath ?? this.ytDlpPath,
      ffmpegPath: ffmpegPath ?? this.ffmpegPath,
      outputDir: outputDir ?? this.outputDir,
    );
  }
}

class DownloadItem {
  DownloadItem({
    required this.id,
    required this.url,
    this.title = '',
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.error,
    this.speed,
    this.eta,
    this.fileSize,
    this.thumbnailUrl,
    this.duration,
    DownloadConfig? config,
  }) : config = config ?? DownloadConfig();

  final String id;
  String url;
  String title;
  DownloadStatus status;
  double progress;
  String? error;
  String? speed;
  String? eta;
  String? fileSize;
  String? thumbnailUrl;
  String? duration;
  DownloadConfig config;
}
