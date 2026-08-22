import 'dart:io';

import 'package:flutter/material.dart';

import '../../backend/models.dart';
import '../../core/download_status.dart';
import '../../core/theme.dart';
import 'status_badge.dart';

class DownloadQueueItem extends StatelessWidget {
  const DownloadQueueItem({
    super.key,
    required this.index,
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onOpenFolder,
    required this.onRemove,
  });

  final int index;
  final DownloadItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onOpenFolder;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<TubeRipTheme>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeLabel =
        item.config.mode == DownloadMode.audio ? 'Audio' : 'Video';
    final qualityLabel = item.config.mode == DownloadMode.audio
        ? item.config.audioFormat.toUpperCase()
        : item.config.quality == 'best'
            ? 'Best'
            : '${item.config.quality}p';

    final subtitleParts = <String>[
      modeLabel,
      qualityLabel,
      if (item.duration != null) item.duration!,
      if (item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.paused)
        '${item.progress.toStringAsFixed(0)}%',
    ];

    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacingMd),
      padding: EdgeInsets.all(tokens.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray900 : Colors.white,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.gray800 : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    isDark ? AppColors.gray800 : AppColors.gray200,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: tokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.url : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: tokens.spacingXs),
                    Text(
                      subtitleParts.join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray400,
                          ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.paused) ...[
            SizedBox(height: tokens.spacingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              child: LinearProgressIndicator(
                value: (item.progress / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.gray800 : AppColors.gray200,
                color: tokens.accent,
              ),
            ),
            if (item.speed != null || item.eta != null) ...[
              SizedBox(height: tokens.spacingXs),
              Text(
                [
                  if (item.speed != null) item.speed!,
                  if (item.eta != null) item.eta!,
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray400,
                    ),
              ),
            ],
          ],
          if (item.status == DownloadStatus.error && item.error != null) ...[
            SizedBox(height: tokens.spacingSm),
            Text(
              item.error!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.error, fontSize: 12),
            ),
          ],
          SizedBox(height: tokens.spacingSm),
          Row(
            children: [
              if (item.status == DownloadStatus.downloading &&
                  (Platform.isLinux || Platform.isMacOS))
                IconButton(
                  tooltip: 'Pause',
                  onPressed: onPause,
                  icon: const Icon(Icons.pause),
                ),
              if (item.status == DownloadStatus.paused)
                IconButton(
                  tooltip: 'Resume',
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                ),
              if (item.status == DownloadStatus.downloading ||
                  item.status == DownloadStatus.paused ||
                  item.status == DownloadStatus.queued)
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                ),
              if (item.status == DownloadStatus.completed)
                TextButton.icon(
                  onPressed: onOpenFolder,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Location'),
                ),
              const Spacer(),
              if (item.status == DownloadStatus.completed ||
                  item.status == DownloadStatus.error ||
                  item.status == DownloadStatus.cancelled)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
