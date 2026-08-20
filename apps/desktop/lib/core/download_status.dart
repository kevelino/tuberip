/// Status of a download, derived from [DownloadItem.status].
enum DownloadStatus {
  downloading,
  completed,
  queued,
  paused,
  error,
  cancelled,
}

extension DownloadStatusX on DownloadStatus {
  static DownloadStatus fromString(String status) {
    switch (status) {
      case 'done':
        return DownloadStatus.completed;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'pending':
        return DownloadStatus.queued;
      case 'error':
        return DownloadStatus.error;
      case 'cancelled':
        return DownloadStatus.cancelled;
      default:
        return DownloadStatus.downloading;
    }
  }
}
