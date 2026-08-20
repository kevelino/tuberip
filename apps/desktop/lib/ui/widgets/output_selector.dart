import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';

class OutputSelector extends StatelessWidget {
  final String outputDir;
  final ValueChanged<String> onOutputDirChanged;
  final bool compact;

  const OutputSelector({
    super.key,
    required this.outputDir,
    required this.onOutputDirChanged,
    this.compact = false,
  });

  Future<void> _pickFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output folder',
      initialDirectory: outputDir,
    );

    if (result != null && result.isNotEmpty) {
      onOutputDirChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPath = AppUtils.expandPath(outputDir);
    final isHovered = true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pickFolder(context),
        child: Container(
          height: compact ? 24 : 34,
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                Icons.folder_outlined,
                size: compact ? 12 : 14,
                color: isHovered ? AppColors.cyan : AppColors.textSecondary,
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  AppStrings.saveToLabel,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 2),
              Expanded(
                child: Text(
                  displayPath,
                  style: TextStyle(
                    color: isHovered
                        ? AppColors.cyan
                        : AppColors.textSecondary,
                    fontSize: compact ? 11 : 12,
                    fontFamily: 'Inter',
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_folder_outlined,
                  size: 12,
                  color: AppColors.cyan,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
