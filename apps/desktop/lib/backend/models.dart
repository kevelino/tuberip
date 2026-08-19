import 'dart:io';

import 'package:flutter/foundation.dart';

enum Mode { video, audio }

class DownloadConfig {
  final Mode mode;
  final String quality;
  final String audioFormat;
  final String audioQuality;
  final String subtitleLang;
  final bool downloadSubtitles;
  final bool embedThumbnail;
  final bool embedMetadata;
  final String rateLimit;
  final String outputDir;

  DownloadConfig({
    this.mode = Mode.video,
    this.quality = '480',
    this.audioFormat = 'mp3',
    this.audioQuality = '0',
    this.subtitleLang = 'en,fr',
    this.downloadSubtitles = false,
    this.embedThumbnail = true,
    this.embedMetadata = true,
    this.rateLimit = '',
    String? outputDir,
  }) : outputDir = outputDir ?? _defaultOutputDir();

  static String _defaultOutputDir() {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Downloads/YouTube';
  }

  DownloadConfig copyWith({
    Mode? mode,
    String? quality,
    String? audioFormat,
    String? audioQuality,
    String? subtitleLang,
    bool? downloadSubtitles,
    bool? embedThumbnail,
    bool? embedMetadata,
    String? rateLimit,
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
      rateLimit: rateLimit ?? this.rateLimit,
      outputDir: outputDir ?? this.outputDir,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.index,
      'quality': quality,
      'audioFormat': audioFormat,
      'audioQuality': audioQuality,
      'subtitleLang': subtitleLang,
      'downloadSubtitles': downloadSubtitles,
      'embedThumbnail': embedThumbnail,
      'embedMetadata': embedMetadata,
      'rateLimit': rateLimit,
      'outputDir': outputDir,
    };
  }

  factory DownloadConfig.fromMap(Map<String, dynamic> map) {
    return DownloadConfig(
      mode: Mode.values[map['mode'] as int? ?? 0],
      quality: map['quality'] as String? ?? '480',
      audioFormat: map['audioFormat'] as String? ?? 'mp3',
      audioQuality: map['audioQuality'] as String? ?? '0',
      subtitleLang: map['subtitleLang'] as String? ?? 'en,fr',
      downloadSubtitles: map['downloadSubtitles'] as bool? ?? false,
      embedThumbnail: map['embedThumbnail'] as bool? ?? true,
      embedMetadata: map['embedMetadata'] as bool? ?? true,
      rateLimit: map['rateLimit'] as String? ?? '',
      outputDir: map['outputDir'] as String?,
    );
  }
}

class DownloadItem {
  String url;
  String title;
  String status;
  double progress;
  String? error;
  DownloadConfig? config;

  DownloadItem({
    required this.url,
    this.title = '',
    this.status = 'pending',
    this.progress = 0.0,
    this.error,
    this.config,
  });
}
