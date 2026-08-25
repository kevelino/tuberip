import 'package:desktop/backend/models.dart';
import 'package:desktop/backend/progress_parser.dart';
import 'package:desktop/backend/yt_dlp_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YtDlpCommandBuilder', () {
    const builder = YtDlpCommandBuilder();

    test('buildUrl accepts full URL', () {
      expect(
        YtDlpCommandBuilder.buildUrl('https://youtu.be/abc'),
        'https://youtu.be/abc',
      );
    });

    test('buildUrl expands video id', () {
      expect(
        YtDlpCommandBuilder.buildUrl('8IemOewC04s'),
        'https://www.youtube.com/watch?v=8IemOewC04s',
      );
    });

    test('buildFormat for best video', () {
      final fmt = builder.buildFormat(
        DownloadConfig(mode: DownloadMode.video, quality: 'best'),
      );
      expect(fmt, contains('bestvideo'));
    });

    test('buildFormat for 480p', () {
      final fmt = builder.buildFormat(
        DownloadConfig(mode: DownloadMode.video, quality: '480'),
      );
      expect(fmt, contains('height<=480'));
    });

    test('buildFormat for audio', () {
      final fmt = builder.buildFormat(
        DownloadConfig(mode: DownloadMode.audio),
      );
      expect(fmt, 'bestaudio/best');
    });

    test('buildCommand video includes merge and cookies', () {
      final cmd = builder.buildCommand(
        url: 'https://www.youtube.com/watch?v=abc',
        config: DownloadConfig(
          mode: DownloadMode.video,
          quality: '720',
          cookieBrowser: 'firefox',
          outputDir: '/tmp/out',
        ),
        ytDlpExecutable: 'yt-dlp',
      );
      expect(cmd.first, 'yt-dlp');
      expect(cmd, contains('--cookies-from-browser'));
      expect(cmd, contains('firefox'));
      expect(cmd, contains('--merge-output-format'));
      expect(cmd, contains('mp4'));
      expect(cmd, contains('--remote-components'));
      expect(cmd, contains('--js-runtimes'));
      expect(cmd.last, 'https://www.youtube.com/watch?v=abc');
    });

    test('buildCommand passes explicit node path', () {
      final cmd = builder.buildCommand(
        url: 'https://www.youtube.com/watch?v=abc',
        config: DownloadConfig(outputDir: '/tmp/out'),
        ytDlpExecutable: 'yt-dlp',
        nodePath: '/usr/bin/node',
      );
      expect(cmd, contains('--js-runtimes'));
      expect(cmd, contains('node:/usr/bin/node'));
    });

    test('jsRuntimeArgs uses explicit path when provided', () {
      expect(
        YtDlpCommandBuilder.jsRuntimeArgs('/usr/bin/node'),
        ['--js-runtimes', 'node:/usr/bin/node'],
      );
    });

    test('buildCommand audio uses -x', () {
      final cmd = builder.buildCommand(
        url: 'https://www.youtube.com/watch?v=abc',
        config: DownloadConfig(
          mode: DownloadMode.audio,
          audioFormat: 'mp3',
          outputDir: '/tmp/out',
        ),
        ytDlpExecutable: 'yt-dlp',
      );
      expect(cmd, contains('-x'));
      expect(cmd, contains('--audio-format'));
      expect(cmd, contains('mp3'));
    });

    test('cookies file takes precedence over browser', () {
      final cmd = builder.buildCommand(
        url: 'https://www.youtube.com/watch?v=abc',
        config: DownloadConfig(
          cookieBrowser: 'firefox',
          cookiesFile: '/tmp/cookies.txt',
          outputDir: '/tmp/out',
        ),
        ytDlpExecutable: 'yt-dlp',
      );
      expect(cmd, contains('--cookies'));
      expect(cmd, contains('/tmp/cookies.txt'));
      expect(cmd, isNot(contains('--cookies-from-browser')));
    });
  });

  group('ProgressParser', () {
    const parser = ProgressParser();

    test('parses percent', () {
      expect(
        parser.parsePercent(
          '[download]  45.2% of 10.00MiB at 1.2MiB/s ETA 00:05',
        ),
        45.2,
      );
    });

    test('ignores non-progress lines', () {
      expect(parser.parsePercent('[info] Downloading'), isNull);
    });

    test('parses speed and eta', () {
      final info = parser.parseSpeedInfo(
        '[download]  45.2% of 10.00MiB at  1.23MiB/s ETA 00:05',
      );
      expect(info.speed, contains('MiB/s'));
      expect(info.eta, 'ETA 00:05');
    });

    test('detects error lines', () {
      expect(parser.isErrorLine('ERROR: Video unavailable'), isTrue);
      expect(parser.isErrorLine('[download] 100%'), isFalse);
    });
    test('detects missing js runtime errors', () {
      expect(
        parser.looksLikeMissingJsRuntime(
          'ERROR: Requested format is not available',
        ),
        isFalse,
      );
      expect(
        parser.looksLikeMissingJsRuntime(
          'n challenge solving failed\nOnly images are available',
        ),
        isTrue,
      );
    });
  });
}
