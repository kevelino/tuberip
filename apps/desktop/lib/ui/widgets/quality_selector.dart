import 'package:flutter/material.dart';

import '../../core/theme_tokens.dart';
import 'primary_dropdown.dart';

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

  // Two-line menu metadata: top = quality, bottom = descriptor.
  static const videoMeta = {
    'best': ('Best', 'Highest resolution'),
    '1080': ('1080p', 'Full HD'),
    '720': ('720p', 'HD'),
    '480': ('480p', 'SD'),
    '360': ('360p', 'Low'),
    '144': ('144p', 'Lowest'),
  };

  static const audioMeta = {
    'mp3': ('MP3', 'Audio'),
    'm4a': ('M4A', 'Audio'),
    'flac': ('FLAC', 'Lossless'),
    'wav': ('WAV', 'Lossless'),
    'opus': ('OPUS', 'Audio'),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);

    if (isAudio) {
      return PrimaryDropdown<String>(
        value: audioFormat,
        leading: Icon(Icons.music_note_outlined,
            size: 14, color: tokens.textSecondary),
        selectedBuilder: Text(
          audioFormat.toUpperCase(),
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onChanged: onAudioFormatChanged,
        items: audioFormats
            .map((f) => _item(context, f, f.toUpperCase(), audioMeta[f]!.$2))
            .toList(),
      );
    }

    final top = videoMeta[selectedQuality]?.$1 ??
        (selectedQuality == 'best' ? 'Best' : '${selectedQuality}p');
    return PrimaryDropdown<String>(
      value: selectedQuality,
      leading: Icon(Icons.high_quality_outlined,
          size: 14, color: tokens.textSecondary),
      selectedBuilder: Text(
        top,
        style: TextStyle(
          color: tokens.textPrimary,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
        overflow: TextOverflow.ellipsis,
      ),
      onChanged: onQualityChanged,
      items: videoQualities
          .map((q) {
            final m = videoMeta[q]!;
            return _item(context, q, m.$1, m.$2);
          })
          .toList(),
    );
  }

  DropdownMenuItem<String> _item(
    BuildContext context,
    String value,
    String top,
    String bottom,
  ) {
    final tokens = TubeRipTheme.of(context);
    return DropdownMenuItem(
      value: value,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            top,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bottom,
            style: TextStyle(
              color: tokens.textMuted,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
