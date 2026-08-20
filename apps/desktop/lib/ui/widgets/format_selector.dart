import 'package:flutter/material.dart';

import '../../backend/models.dart';
import '../../core/theme_tokens.dart';
import 'primary_dropdown.dart';

/// Format selector: Video (MP4) / Audio (MP3) as a themed dropdown.
class FormatSelector extends StatelessWidget {
  final Mode selectedMode;
  final ValueChanged<Mode> onModeChanged;

  const FormatSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    final selectedLabel =
        selectedMode == Mode.video ? 'Video (MP4)' : 'Audio (MP3)';
    return PrimaryDropdown<Mode>(
      value: selectedMode,
      leading: Icon(
        selectedMode == Mode.video
            ? Icons.videocam_outlined
            : Icons.audio_file_outlined,
        size: 14,
        color: tokens.textSecondary,
      ),
      selectedBuilder: Text(
        selectedLabel,
        style: TextStyle(
          color: tokens.textPrimary,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onChanged: (m) {
        if (m != null) onModeChanged(m);
      },
      items: const [
        DropdownMenuItem(value: Mode.video, child: Text('Video (MP4)')),
        DropdownMenuItem(value: Mode.audio, child: Text('Audio (MP3)')),
      ],
    );
  }
}
