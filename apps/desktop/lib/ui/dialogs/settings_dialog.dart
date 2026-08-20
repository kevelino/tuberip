import 'package:flutter/material.dart';

import '../../core/constants.dart';

class SettingsDialog extends StatefulWidget {
  final Map<String, dynamic> settings;
  final void Function(Map<String, dynamic> updated) onApply;

  const SettingsDialog({
    super.key,
    required this.settings,
    required this.onApply,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final Map<String, dynamic> _localSettings;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _localSettings = Map<String, dynamic>.of(widget.settings);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue);
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
      ),
      title: const Text(
        AppStrings.settingsTitle,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.settingsSubtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(AppStrings.metadataTitle, [
                _buildSwitch('embedThumbnail', 'Embed video thumbnail',
                    'Adds cover art to audio/video files'),
                _buildSwitch('embedMetadata', 'Embed metadata',
                    'Writes title/artist info into file tags'),
              ]),
              _buildSection(AppStrings.subtitlesTitle, [
                _buildSwitch('downloadSubtitles', 'Download subtitles',
                    'Fetches .srt subtitle files'),
                _buildTextField(
                  'subtitleLang',
                  'Subtitle languages',
                  'Comma-separated language codes (e.g. en,es,fr)',
                ),
              ]),
              _buildSection(AppStrings.audioQualityTitle, [
                _buildTextField(
                  'audioQuality',
                  'VBR quality',
                  '0 (best) to 9 (smallest) for VBR encoding',
                ),
              ]),
              _buildSection(AppStrings.networkTitle, [
                _buildTextField(
                  'rateLimit',
                  'Rate limit',
                  'Max download speed (e.g. 500K, 2M). Leave empty for no limit.',
                ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onApply(_localSettings);
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: const Text(
              AppStrings.applyButton,
              style: TextStyle(
                color: AppColors.background,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitch(
    String key,
    String label,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch(
              value: _localSettings[key] as bool? ?? false,
              onChanged: (v) {
                setState(() {
                  _localSettings[key] = v;
                });
              },
              activeThumbColor: AppColors.cyan,
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.border,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    String hint,
  ) {
    final initialValue = _localSettings[key]?.toString() ?? '';
    final controller = _getController(key, initialValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: const BorderSide(color: AppColors.cyan),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (v) {
            _localSettings[key] = v;
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
