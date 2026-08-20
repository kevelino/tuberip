import 'package:flutter/material.dart';

import '../../core/download_status.dart';
import '../../core/theme_tokens.dart';

/// Leading status indicator: filled dot (downloading), check (completed),
/// outlined circle (queued), pause (paused), error/cancel icons.
class StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  final Color? color;
  final double size;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
    this.size = 10,
  });

  Color _defaultColor(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    return tokens.statusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? _defaultColor(context);
    switch (status) {
      case DownloadStatus.downloading:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
          ),
        );
      case DownloadStatus.completed:
        return Icon(Icons.check_circle_outline, size: size + 4, color: c);
      case DownloadStatus.queued:
        return Icon(Icons.circle_outlined, size: size + 4, color: c);
      case DownloadStatus.paused:
        return Icon(Icons.pause_circle_outline, size: size + 4, color: c);
      case DownloadStatus.error:
        return Icon(Icons.error_outline, size: size + 4, color: c);
      case DownloadStatus.cancelled:
        return Icon(Icons.cancel_outlined, size: size + 4, color: c);
    }
  }
}
