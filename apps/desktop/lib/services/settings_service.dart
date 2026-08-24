import 'package:shared_preferences/shared_preferences.dart';

import '../backend/models.dart';

/// Persists user preferences.
class SettingsService {
  static const _kMode = 'mode';
  static const _kQuality = 'quality';
  static const _kAudioFormat = 'audio_format';
  static const _kAudioQuality = 'audio_quality';
  static const _kOutputDir = 'output_dir';
  static const _kSubtitles = 'download_subtitles';
  static const _kSubtitleLang = 'subtitle_lang';
  static const _kCookieBrowser = 'cookie_browser';
  static const _kCookiesFile = 'cookies_file';
  static const _kYtDlpPath = 'yt_dlp_path';
  static const _kFfmpegPath = 'ffmpeg_path';
  static const _kTheme = 'theme';
  static const _kEmbedThumb = 'embed_thumbnail';
  static const _kEmbedMeta = 'embed_metadata';
  static const _kYtDlpLastCheckMs = 'yt_dlp_last_check_ms';
  static const _kYtDlpInstalledVersion = 'yt_dlp_installed_version';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<DownloadConfig> loadConfig() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    final modeStr = p.getString(_kMode) ?? 'video';
    final config = DownloadConfig(
      mode: modeStr == 'audio' ? DownloadMode.audio : DownloadMode.video,
      quality: p.getString(_kQuality) ?? '480',
      audioFormat: p.getString(_kAudioFormat) ?? 'mp3',
      audioQuality: p.getString(_kAudioQuality) ?? '0',
      downloadSubtitles: p.getBool(_kSubtitles) ?? false,
      subtitleLang: p.getString(_kSubtitleLang) ?? 'fr,en',
      cookieBrowser: p.getString(_kCookieBrowser) ?? 'firefox',
      cookiesFile: p.getString(_kCookiesFile) ?? '',
      ytDlpPath: p.getString(_kYtDlpPath) ?? '',
      ffmpegPath: p.getString(_kFfmpegPath) ?? '',
      embedThumbnail: p.getBool(_kEmbedThumb) ?? true,
      embedMetadata: p.getBool(_kEmbedMeta) ?? true,
      outputDir: p.getString(_kOutputDir),
    );
    return config;
  }

  Future<void> saveConfig(DownloadConfig config) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _kMode,
      config.mode == DownloadMode.audio ? 'audio' : 'video',
    );
    await p.setString(_kQuality, config.quality);
    await p.setString(_kAudioFormat, config.audioFormat);
    await p.setString(_kAudioQuality, config.audioQuality);
    await p.setString(_kOutputDir, config.outputDir);
    await p.setBool(_kSubtitles, config.downloadSubtitles);
    await p.setString(_kSubtitleLang, config.subtitleLang);
    await p.setString(_kCookieBrowser, config.cookieBrowser);
    await p.setString(_kCookiesFile, config.cookiesFile);
    await p.setString(_kYtDlpPath, config.ytDlpPath);
    await p.setString(_kFfmpegPath, config.ffmpegPath);
    await p.setBool(_kEmbedThumb, config.embedThumbnail);
    await p.setBool(_kEmbedMeta, config.embedMetadata);
  }

  /// `dark` | `light` | `system`
  Future<String> loadThemeMode() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(_kTheme) ?? 'dark';
  }

  Future<void> saveThemeMode(String mode) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(_kTheme, mode);
  }

  Future<DateTime?> loadYtDlpLastCheck() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final ms = p.getInt(_kYtDlpLastCheckMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveYtDlpLastCheck(DateTime time) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setInt(_kYtDlpLastCheckMs, time.millisecondsSinceEpoch);
  }

  Future<String?> loadYtDlpInstalledVersion() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(_kYtDlpInstalledVersion);
  }

  Future<void> saveYtDlpInstalledVersion(String version) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(_kYtDlpInstalledVersion, version);
  }
}
