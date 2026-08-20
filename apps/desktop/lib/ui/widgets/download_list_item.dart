import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../backend/models.dart';

class DownloadListItem extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  const DownloadListItem({
    super.key,
    required this.item,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRemove,
    this.onRetry,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.green;
      case 'error':
      case 'cancelled':
        return AppColors.red;
      case 'paused':
        return AppColors.yellow;
      case 'downloading':
      default:
        return AppColors.cyan;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'done':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'paused':
        return Icons.pause_circle_outline;
      case 'downloading':
      default:
        return Icons.download_outlined;
    }
  }

  bool _canPause(String status) => status == 'downloading';
  bool _canResume(String status) => status == 'paused';
  bool _canCancel(String status) =>
      status == 'downloading' || status == 'paused';
  bool _canRetry(String status) => status == 'error' || status == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    final icon = _statusIcon(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + status
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title.isNotEmpty ? item.title : item.url,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          if (item.status != 'done' &&
              item.status != 'error' &&
              item.status != 'cancelled' &&
              item.status != 'pending')
            LinearProgressIndicator(
              value: item.progress / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 2,
            ),
          // Progress text + speed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.status == 'done'
                      ? 'Complete'
                      : '${item.progress.toStringAsFixed(item.progress == 0 ? 0 : 1)}%',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                if (item.error != null && item.status == 'error')
                  Text(
                    item.error!,
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Speed info',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          // Controls at bottom right
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_canPause(item.status) && onPause != null)
                  _controlButton(
                    Icons.pause,
                    'Pause',
                    AppColors.textSecondary,
                    onPause!,
                  ),
                if (_canPause(item.status) && onPause != null)
                  const SizedBox(width: 4),
                if (_canResume(item.status) && onResume != null)
                  _controlButton(
                    Icons.play_arrow,
                    'Resume',
                    AppColors.cyan,
                    onResume!,
                  ),
                if (_canResume(item.status) && onResume != null)
                  const SizedBox(width: 4),
                if (_canCancel(item.status) && onCancel != null)
                  _controlButton(
                    Icons.stop,
                    'Cancel',
                    AppColors.textSecondary,
                    onCancel!,
                  ),
                if (_canCancel(item.status) && onCancel != null)
                  const SizedBox(width: 4),
                if (_canRetry(item.status) && onRetry != null)
                  _controlButton(
                    Icons.refresh,
                    'Retry',
                    AppColors.yellow,
                    onRetry!,
                  ),
                if (_canRetry(item.status) && onRetry != null)
                  const SizedBox(width: 4),
                _controlButton(
                  Icons.close,
                  'Remove',
                  AppColors.textSecondary,
                  onRemove ?? () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Done';
      case 'error':
        return 'Error';
      case 'cancelled':
        return 'Cancelled';
      case 'paused':
        return 'Paused';
      case 'pending':
        return 'Pending';
      default:
        return 'Downloading';
    }
  }

  Widget _controlButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
