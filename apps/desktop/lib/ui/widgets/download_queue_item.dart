import 'package:flutter/material.dart';

import '../../backend/models.dart';
import '../../core/download_status.dart';
import '../../core/theme_tokens.dart';
import '../../core/utils.dart';
import 'status_badge.dart';

/// A single download row/card in the queue. Visual state is driven entirely by
/// [DownloadStatus] (derived from [DownloadItem.status]).
class DownloadQueueItem extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
  final VoidCallback? onReveal;

  const DownloadQueueItem({
    super.key,
    required this.item,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onRemove,
    this.onReveal,
  });

  bool _active(String s) => item.status == s;
  bool _canPause() => _active('downloading');
  bool _canResume() => _active('paused');
  bool _canCancel() => _active('downloading') || _active('paused');
  bool _canRetry() => _active('error') || _active('cancelled');
  bool _canReveal() => _active('done');

  @override
  Widget build(BuildContext context) {
    final tokens = TubeRipTheme.of(context);
    final status = DownloadStatusX.fromString(item.status);
    final color = tokens.statusColor(status);
    final showProgress =
        status == DownloadStatus.downloading || status == DownloadStatus.paused;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : item.url,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(status),
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Trailing(
                  status: status,
                  color: color,
                  label: _statusLabel(status),
                  canPause: _canPause(),
                  canResume: _canResume(),
                  canCancel: _canCancel(),
                  canRetry: _canRetry(),
                  canReveal: _canReveal(),
                  onPause: onPause,
                  onResume: onResume,
                  onCancel: onCancel,
                  onRetry: onRetry,
                  onRemove: onRemove,
                  onReveal: onReveal,
                ),
              ],
            ),
          ),
          if (item.error != null && status == DownloadStatus.error)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                item.error!,
                style: TextStyle(
                  color: tokens.errorText,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (showProgress)
            LinearProgressIndicator(
              value: item.progress / 100,
              backgroundColor: tokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
        ],
      ),
    );
  }

  String _statusLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.error:
        return 'Error';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.downloading:
        return 'Downloading';
    }
  }

  String _subtitle(DownloadStatus status) {
    final parts = <String>[];
    if (item.config != null) {
      parts.add(item.config!.mode == Mode.video ? 'Video' : 'Audio');
      if (item.config!.mode == Mode.video) {
        parts.add(item.config!.quality == 'best'
            ? 'Best'
            : '${item.config!.quality}p');
      } else {
        parts.add(item.config!.audioFormat.toUpperCase());
      }
    }
    if (status == DownloadStatus.downloading && item.speed != null) {
      parts.add(item.speed!);
    }
    parts.add(
      '${item.progress.toStringAsFixed(item.progress == 0 ? 0 : 1)}%',
    );
    parts.add(AppUtils.relativeTime(item.createdAt));
    return parts.join('   •   ');
  }
}

class _Trailing extends StatelessWidget {
  final DownloadStatus status;
  final Color color;
  final String label;
  final bool canPause;
  final bool canResume;
  final bool canCancel;
  final bool canRetry;
  final bool canReveal;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
  final VoidCallback? onReveal;

  const _Trailing({
    required this.status,
    required this.color,
    required this.label,
    required this.canPause,
    required this.canResume,
    required this.canCancel,
    required this.canRetry,
    required this.canReveal,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onRemove,
    this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(status: status, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        if (canReveal && onReveal != null)
          _ActionIcon(Icons.folder_open_outlined, color, onReveal!),
        if (canPause && onPause != null)
          _ActionIcon(Icons.pause, color, onPause!),
        if (canResume && onResume != null)
          _ActionIcon(Icons.play_arrow, color, onResume!),
        if (canCancel && onCancel != null)
          _ActionIcon(Icons.close, color, onCancel!),
        if (canRetry && onRetry != null)
          _ActionIcon(Icons.refresh, color, onRetry!),
        _ActionIcon(
          Icons.delete_outline,
          TubeRipTheme.of(context).textMuted,
          onRemove ?? () {},
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
