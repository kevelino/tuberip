import 'package:flutter/material.dart';

import '../../backend/models.dart';
import '../../core/constants.dart';

class ModeSelector extends StatelessWidget {
  final Mode selectedMode;
  final ValueChanged<Mode> onModeChanged;

  const ModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(
          color: AppColors.border,
          width: AppSizes.borderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Mode.values.map((mode) {
          final isSelected = selectedMode == mode;
          final label = mode == Mode.video
              ? AppStrings.downloadVideo
              : AppStrings.downloadAudio;
          return GestureDetector(
            onTap: () => onModeChanged(mode),
            child: Container(
              width: 140,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cyan : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mode == Mode.video
                        ? Icons.videocam_outlined
                        : Icons.audio_file_outlined,
                    size: 14,
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
