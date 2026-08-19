import 'package:flutter/material.dart';

import '../../core/constants.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

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
        AppStrings.helpTitle,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.helpSummary,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const _FeatureTile(
                icon: Icons.download_outlined,
                title: AppStrings.featureVideoAudio,
                description: AppStrings.featureVideoDesc,
              ),
              const _FeatureTile(
                icon: Icons.high_quality_outlined,
                title: AppStrings.featureQuality,
                description: AppStrings.featureQualityDesc,
              ),
              const _FeatureTile(
                icon: Icons.music_note_outlined,
                title: AppStrings.featureAudioQuality,
                description: AppStrings.featureAudioQualityDesc,
              ),
              const _FeatureTile(
                icon: Icons.subtitles_outlined,
                title: AppStrings.featureSubtitles,
                description: AppStrings.featureSubtitlesDesc,
              ),
              const _FeatureTile(
                icon: Icons.pause_circle_outline,
                title: AppStrings.featurePauseResume,
                description: AppStrings.featurePauseDesc,
              ),
              const _FeatureTile(
                icon: Icons.folder_outlined,
                title: AppStrings.featureFolder,
                description: AppStrings.featureFolderDesc,
              ),
              const _FeatureTile(
                icon: Icons.list_alt_outlined,
                title: AppStrings.featureQueue,
                description: AppStrings.featureQueueDesc,
              ),
              const _FeatureTile(
                icon: Icons.settings_outlined,
                title: AppStrings.featureSettings,
                description: AppStrings.featureSettingsDesc,
              ),
              const SizedBox(height: 8),
              _shortcutsTable(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shortcutsTable() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard shortcuts',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _shortcutRow(
              AppStrings.shortcutEnter, AppStrings.shortcutEnterAction),
          _shortcutRow(AppStrings.shortcutSettings,
              AppStrings.shortcutSettingsAction),
          _shortcutRow(
              AppStrings.shortcutQuit, AppStrings.shortcutQuitAction),
          _shortcutRow(
              AppStrings.shortcutHelp, AppStrings.shortcutHelpAction),
        ],
      ),
    );
  }

  Widget _shortcutRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
