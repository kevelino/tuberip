import 'package:shared_preferences/shared_preferences.dart';

import '../backend/models.dart';

class SettingsService {
  static const _prefix = 'tuberip_';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // ── Output dir ──────────────────────────────────────────────

  String get outputDir {
    return _prefs.getString('${_prefix}output_dir') ??
        DownloadConfig().outputDir;
  }

  Future<void> setOutputDir(String value) async {
    await _prefs.setString('${_prefix}output_dir', value);
  }

  // ── Audio quality ───────────────────────────────────────────

  String get audioQuality {
    return _prefs.getString('${_prefix}audio_quality') ?? '0';
  }

  Future<void> setAudioQuality(String value) async {
    await _prefs.setString('${_prefix}audio_quality', value);
  }

  // ── Subtitle lang ───────────────────────────────────────────

  String get subtitleLang {
    return _prefs.getString('${_prefix}subtitle_lang') ?? 'en,fr';
  }

  Future<void> setSubtitleLang(String value) async {
    await _prefs.setString('${_prefix}subtitle_lang', value);
  }

  // ── Download subtitles ──────────────────────────────────────

  bool get downloadSubtitles {
    return _prefs.getBool('${_prefix}download_subtitles') ?? false;
  }

  Future<void> setDownloadSubtitles(bool value) async {
    await _prefs.setBool('${_prefix}download_subtitles', value);
  }

  // ── Embed thumbnail ─────────────────────────────────────────

  bool get embedThumbnail {
    return _prefs.getBool('${_prefix}embed_thumbnail') ?? true;
  }

  Future<void> setEmbedThumbnail(bool value) async {
    await _prefs.setBool('${_prefix}embed_thumbnail', value);
  }

  // ── Embed metadata ─────────────────────────────────────────

  bool get embedMetadata {
    return _prefs.getBool('${_prefix}embed_metadata') ?? true;
  }

  Future<void> setEmbedMetadata(bool value) async {
    await _prefs.setBool('${_prefix}embed_metadata', value);
  }

  // ── Rate limit ──────────────────────────────────────────────

  String get rateLimit {
    return _prefs.getString('${_prefix}rate_limit') ?? '';
  }

  Future<void> setRateLimit(String value) async {
    await _prefs.setString('${_prefix}rate_limit', value);
  }

  // ── Build DownloadConfig ────────────────────────────────────

  DownloadConfig buildConfig({
    required Mode mode,
    required String quality,
    required String audioFormat,
    String? outputDir,
  }) {
    return DownloadConfig(
      mode: mode,
      quality: quality,
      audioFormat: audioFormat,
      audioQuality: audioQuality,
      subtitleLang: subtitleLang,
      downloadSubtitles: downloadSubtitles,
      embedThumbnail: embedThumbnail,
      embedMetadata: embedMetadata,
      rateLimit: rateLimit,
      outputDir: outputDir ?? this.outputDir,
    );
  }

  // ── Factory ─────────────────────────────────────────────────

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // ── Export all settings as map ─────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'audio_quality': audioQuality,
      'subtitle_lang': subtitleLang,
      'download_subtitles': downloadSubtitles,
      'embed_thumbnail': embedThumbnail,
      'embed_metadata': embedMetadata,
      'rate_limit': rateLimit,
    };
  }

  Future<void> saveMap(Map<String, dynamic> map) async {
    if (map['audio_quality'] != null) {
      await setAudioQuality(map['audio_quality'] as String);
    }
    if (map['subtitle_lang'] != null) {
      await setSubtitleLang(map['subtitle_lang'] as String);
    }
    if (map['download_subtitles'] != null) {
      await setDownloadSubtitles(map['download_subtitles'] as bool);
    }
    if (map['embed_thumbnail'] != null) {
      await setEmbedThumbnail(map['embed_thumbnail'] as bool);
    }
    if (map['embed_metadata'] != null) {
      await setEmbedMetadata(map['embed_metadata'] as bool);
    }
    if (map['rate_limit'] != null) {
      await setRateLimit(map['rate_limit'] as String);
    }
  }
}
