import 'package:flutter/material.dart';

import '../../backend/models.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/settings_service.dart';
import '../../services/yt_dlp_updater.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.config,
    required this.themeMode,
    required this.settings,
    required this.onSaved,
    this.ytDlpUpdater,
  });

  final DownloadConfig config;
  final String themeMode;
  final SettingsService settings;
  final void Function(DownloadConfig config, String themeMode) onSaved;
  final YtDlpUpdater? ytDlpUpdater;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late DownloadConfig _config;
  late String _themeMode;
  late final TextEditingController _subtitleLang;
  late final TextEditingController _cookiesFile;
  late final TextEditingController _ytDlpPath;
  late final TextEditingController _ffmpegPath;
  String? _ytDlpVersion;
  String? _playerClient;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config.copyWith();
    _themeMode = widget.themeMode;
    _subtitleLang = TextEditingController(text: _config.subtitleLang);
    _cookiesFile = TextEditingController(text: _config.cookiesFile);
    _ytDlpPath = TextEditingController(text: _config.ytDlpPath);
    _ffmpegPath = TextEditingController(text: _config.ffmpegPath);
    _playerClient = _config.playerClient;
    _loadYtDlpVersion();
  }

  Future<void> _loadYtDlpVersion() async {
    final updater = widget.ytDlpUpdater;
    if (updater == null) return;
    final version = await updater.readLocalVersion();
    if (!mounted) return;
    setState(() => _ytDlpVersion = version);
  }

  Future<void> _checkYtDlpUpdates() async {
    final updater = widget.ytDlpUpdater;
    if (updater == null || _checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final result = await updater.checkAndUpdate(force: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (result.version != null) {
      _ytDlpVersion = result.version;
    }
  }

  String _ytDlpVersionLabel() {
    final custom = _config.ytDlpPath.trim().isNotEmpty;
    if (custom) {
      return 'Custom path — auto-update off';
    }
    if (_ytDlpVersion != null && _ytDlpVersion!.isNotEmpty) {
      return 'Current version: $_ytDlpVersion';
    }
    return 'Current version: unknown';
  }

  @override
  void dispose() {
    _subtitleLang.dispose();
    _cookiesFile.dispose();
    _ytDlpPath.dispose();
    _ffmpegPath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;

    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Download subtitles'),
                value: _config.downloadSubtitles,
                activeThumbColor: tokens.accent,
                onChanged: (v) => setState(() {
                  _config = _config.copyWith(downloadSubtitles: v);
                }),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Subtitle languages',
                  hintText: 'fr,en',
                ),
                controller: _subtitleLang,
                onChanged: (v) =>
                    _config = _config.copyWith(subtitleLang: v),
              ),
              SizedBox(height: tokens.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _config.cookieBrowser,
                decoration: const InputDecoration(
                  labelText: 'Cookies from browser',
                ),
                items: AppConstants.cookieBrowsers
                    .map(
                      (b) => DropdownMenuItem(value: b, child: Text(b)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _config = _config.copyWith(cookieBrowser: v);
                    });
                  }
                },
              ),
              SizedBox(height: tokens.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _playerClient,
                decoration: const InputDecoration(
                  labelText: 'YouTube player client',
                ),
                items: const [
                  DropdownMenuItem(value: 'web_embedded', child: Text('web_embedded')),
                  DropdownMenuItem(value: 'default', child: Text('default')),
                  DropdownMenuItem(value: 'android', child: Text('android')),
                  DropdownMenuItem(value: 'ios', child: Text('ios')),
                  DropdownMenuItem(value: 'tv', child: Text('tv')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _config = _config.copyWith(playerClient: v);
                      _playerClient = v;
                    });
                  }
                },
              ),
              SizedBox(height: tokens.spacingMd),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cookies file (optional)',
                  hintText: '/path/to/cookies.txt',
                ),
                controller: _cookiesFile,
                onChanged: (v) =>
                    _config = _config.copyWith(cookiesFile: v),
              ),
              SizedBox(height: tokens.spacingMd),
              Text(
                'yt-dlp',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _ytDlpVersionLabel(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.ytDlpUpdater != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _checkingUpdate ? null : _checkYtDlpUpdates,
                    child: const Text('Check for updates'),
                  ),
                ),
              ],
              if (_checkingUpdate)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Checking…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              SizedBox(height: tokens.spacingMd),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Custom yt-dlp path',
                  helperText:
                      'If set, TubeRip uses this binary and will not auto-update it',
                ),
                controller: _ytDlpPath,
                onChanged: (v) =>
                    _config = _config.copyWith(ytDlpPath: v),
              ),
              SizedBox(height: tokens.spacingMd),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Custom ffmpeg path',
                ),
                controller: _ffmpegPath,
                onChanged: (v) =>
                    _config = _config.copyWith(ffmpegPath: v),
              ),
              SizedBox(height: tokens.spacingMd),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Embed thumbnail'),
                value: _config.embedThumbnail,
                activeThumbColor: tokens.accent,
                onChanged: (v) => setState(() {
                  _config = _config.copyWith(embedThumbnail: v);
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Embed metadata'),
                value: _config.embedMetadata,
                activeThumbColor: tokens.accent,
                onChanged: (v) => setState(() {
                  _config = _config.copyWith(embedMetadata: v);
                }),
              ),
              SizedBox(height: tokens.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _themeMode,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'system', child: Text('System')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _themeMode = v);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.settings.saveConfig(_config);
            await widget.settings.saveThemeMode(_themeMode);
            widget.onSaved(_config, _themeMode);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
