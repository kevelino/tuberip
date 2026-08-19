import 'package:flutter/material.dart';

import '../../core/constants.dart';

class QualitySelector extends StatelessWidget {
  final String selectedQuality;
  final String audioFormat;
  final ValueChanged<String?> onQualityChanged;
  final ValueChanged<String?> onAudioFormatChanged;
  final bool isAudio;

  const QualitySelector({
    super.key,
    required this.selectedQuality,
    required this.audioFormat,
    required this.onQualityChanged,
    required this.onAudioFormatChanged,
    this.isAudio = false,
  });

  static const videoQualities = ['best', '1080', '720', '480', '360', '144'];
  static const audioFormats = ['mp3', 'm4a', 'flac', 'wav', 'opus'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Quality label
        Text(
          'Quality:',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(width: 8),
        // Quality dropdown
        Container(
          width: 100,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(
              color: AppColors.border,
              width: AppSizes.borderWidthThin,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideScrollbar(
            child: DropdownButton<String>(
              value: selectedQuality,
              onChanged: onQualityChanged,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              dropdownButtonColor: AppColors.surface,
              dropdownBorderSide:
                  const BorderSide(color: AppColors.border, width: 1),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              items: (isAudio ? videoQualities : videoQualities)
                  .map((q) => DropdownMenuItem(
                        value: q,
                        child: Text(q == 'best' ? 'Best' : '$q p'),
                      ))
                  .toList(),
              selectedItemBuilder: (context) => List.generate(
                  (isAudio ? videoQualities : videoQualities).length,
                  (index) => Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (isAudio ? videoQualities : videoQualities)[index],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                      )),
            ),
          ),
        ),
        if (isAudio) ...[
          const SizedBox(width: 16),
          Text(
            'Format:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: AppColors.border,
                width: AppSizes.borderWidthThin,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideScrollbar(
              child: DropdownButton<String>(
                value: audioFormat,
                onChanged: onAudioFormatChanged,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                dropdownButtonColor: AppColors.surface,
                dropdownBorderSide:
                    const BorderSide(color: AppColors.border, width: 1),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
                items: audioFormats
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.toUpperCase()),
                        ))
                    .toList(),
                selectedItemBuilder: (context) => List.generate(
                    audioFormats.length,
                    (index) => Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            audioFormats[index].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
