import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../backend/models.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'primary_dropdown.dart';

class FormatSelector extends StatelessWidget {
  const FormatSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final DownloadMode mode;
  final ValueChanged<DownloadMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PrimaryDropdown<DownloadMode>(
      label: 'Format',
      value: mode,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: const [
        DropdownMenuItem(
          value: DownloadMode.video,
          child: Text('Video (MP4)'),
        ),
        DropdownMenuItem(
          value: DownloadMode.audio,
          child: Text('Audio'),
        ),
      ],
    );
  }
}

class QualitySelector extends StatelessWidget {
  const QualitySelector({
    super.key,
    required this.mode,
    required this.quality,
    required this.audioFormat,
    required this.onQualityChanged,
    required this.onAudioFormatChanged,
  });

  final DownloadMode mode;
  final String quality;
  final String audioFormat;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onAudioFormatChanged;

  @override
  Widget build(BuildContext context) {
    if (mode == DownloadMode.audio) {
      return PrimaryDropdown<String>(
        label: 'Audio format',
        value: audioFormat,
        onChanged: (v) {
          if (v != null) onAudioFormatChanged(v);
        },
        items: AppConstants.audioFormats
            .map(
              (f) => DropdownMenuItem(
                value: f,
                child: Text(f.toUpperCase()),
              ),
            )
            .toList(),
      );
    }

    return PrimaryDropdown<String>(
      label: 'Quality',
      value: quality,
      onChanged: (v) {
        if (v != null) onQualityChanged(v);
      },
      items: AppConstants.videoQualities
          .map(
            (q) => DropdownMenuItem(
              value: q,
              child: Text(q == 'best' ? 'Best' : '${q}p'),
            ),
          )
          .toList(),
    );
  }
}

class OutputSelector extends StatelessWidget {
  const OutputSelector({
    super.key,
    required this.path,
    required this.onChanged,
  });

  final String path;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose download folder',
      initialDirectory: path,
    );
    if (dir != null && dir.isNotEmpty) {
      onChanged(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;

    return Row(
      children: [
        Text(
          'Save to:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray400,
              ),
        ),
        SizedBox(width: tokens.spacingSm),
        Expanded(
          child: Text(
            path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          tooltip: 'Choose folder',
          onPressed: () => _pick(context),
          icon: const Icon(Icons.folder_outlined, size: 20),
        ),
      ],
    );
  }
}
