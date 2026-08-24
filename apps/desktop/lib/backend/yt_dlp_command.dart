import 'package:path/path.dart' as p;

import '../core/constants.dart';
import 'models.dart';

/// Builds yt-dlp CLI arguments (parity with yt.py / Python downloader).
class YtDlpCommandBuilder {
  const YtDlpCommandBuilder();

  static String buildUrl(String videoIdOrUrl) {
    final trimmed = videoIdOrUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://www.youtube.com/watch?v=$trimmed';
  }

  String buildFormat(DownloadConfig config) {
    if (config.mode == DownloadMode.audio) {
      return 'bestaudio/best';
    }
    final quality = config.quality;
    if (quality == 'best') {
      return 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best';
    }
    return 'bestvideo[height<=$quality][ext=mp4]+'
        'bestaudio[ext=m4a]/'
        'best[height<=$quality]';
  }

  List<String> buildCommand({
    required String url,
    required DownloadConfig config,
    required String ytDlpExecutable,
  }) {
    final outputTemplate = p.join(
      config.outputDir,
      AppConstants.outputTemplate,
    );

    final cmd = <String>[
      ytDlpExecutable,
      '--remote-components',
      AppConstants.remoteComponents,
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
      '--newline',
    ];

    if (config.playerClient.isNotEmpty) {
      cmd.addAll(['--extractor-args', 'youtube:player_client=${config.playerClient}']);
    }

    if (config.cookiesFile.isNotEmpty) {
      cmd.addAll(['--cookies', config.cookiesFile]);
    } else if (config.cookieBrowser.isNotEmpty) {
      cmd.addAll(['--cookies-from-browser', config.cookieBrowser]);
    }

    if (config.ffmpegPath.isNotEmpty) {
      cmd.addAll(['--ffmpeg-location', config.ffmpegPath]);
    }

    if (config.mode == DownloadMode.audio) {
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
        buildFormat(config),
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
      cmd.add('--add-metadata');
    }

    cmd.add(url);
    return cmd;
  }

  List<String> buildMetadataCommand({
    required String url,
    required String ytDlpExecutable,
    String? cookieBrowser,
    String? cookiesFile,
  }) {
    final cmd = <String>[
      ytDlpExecutable,
      '--dump-json',
      '--no-warnings',
      '--no-playlist',
    ];
    if (cookiesFile != null && cookiesFile.isNotEmpty) {
      cmd.addAll(['--cookies', cookiesFile]);
    } else if (cookieBrowser != null && cookieBrowser.isNotEmpty) {
      cmd.addAll(['--cookies-from-browser', cookieBrowser]);
    }
    cmd.add(url);
    return cmd;
  }
}
