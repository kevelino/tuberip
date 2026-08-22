/// App-wide constants for TubeRip.
abstract final class AppConstants {
  static const String appName = 'TubeRip';
  static const String logoAsset = 'assets/icons/tuberip.svg';

  static const String defaultOutputSubdir = 'YouTube';
  static const String outputTemplate = '%(title)s [%(id)s].%(ext)s';

  static const List<String> videoQualities = ['best', '1080', '720', '480'];
  static const List<String> audioFormats = ['mp3', 'm4a', 'best'];
  static const List<String> cookieBrowsers = [
    'firefox',
    'chrome',
    'chromium',
    'brave',
  ];

  static const String remoteComponents = 'ejs:github';
}
