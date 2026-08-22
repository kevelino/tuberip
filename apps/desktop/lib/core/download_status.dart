enum DownloadStatus {
  pending,
  queued,
  downloading,
  paused,
  completed,
  error,
  cancelled,
}

extension DownloadStatusLabel on DownloadStatus {
  String get label => switch (this) {
        DownloadStatus.pending => 'Pending',
        DownloadStatus.queued => 'Queued',
        DownloadStatus.downloading => 'Downloading',
        DownloadStatus.paused => 'Paused',
        DownloadStatus.completed => 'Completed',
        DownloadStatus.error => 'Error',
        DownloadStatus.cancelled => 'Cancelled',
      };
}
