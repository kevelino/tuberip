import 'package:flutter/material.dart';

import '../../core/download_status.dart';
import '../../core/theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;
    final (color, icon) = switch (status) {
      DownloadStatus.downloading => (tokens.accent, Icons.downloading),
      DownloadStatus.completed => (tokens.success, Icons.check_circle),
      DownloadStatus.queued || DownloadStatus.pending => (
          tokens.warning,
          Icons.schedule
        ),
      DownloadStatus.paused => (tokens.warning, Icons.pause_circle),
      DownloadStatus.error || DownloadStatus.cancelled => (
          tokens.error,
          Icons.error
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
