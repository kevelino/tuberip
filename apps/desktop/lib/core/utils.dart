import 'dart:io';

class AppUtils {
  static String expandPath(String path) {
    if (path.isEmpty) return path;
    final expanded = path
        .replaceAll('%USERPROFILE%', Platform.environment['HOME'] ?? '')
        .replaceAll('\$HOME', Platform.environment['HOME'] ?? '');
    if (expanded.startsWith('~')) {
      final home = Platform.environment['HOME'] ?? '';
      return home + expanded.substring(1);
    }
    return expanded;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration d) {
    if (d.isNegative) return '--:--';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String parseSpeed(String line) {
    final speedMatch = RegExp(r'\bat\s+([\d.]+)\s*(\w+/s)').firstMatch(line);
    final etaMatch = RegExp(r'\bETA\s+([\d:]+)').firstMatch(line);
    final parts = <String>[];
    if (speedMatch != null) {
      parts.add('${speedMatch.group(1)} ${speedMatch.group(2)}');
    }
    if (etaMatch != null) {
      parts.add('ETA ${etaMatch.group(1)}');
    }
    return parts.join(' • ');
  }

  static String parsePercent(String line) {
    final match = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(line);
    if (match != null) {
      return match.group(1)!;
    }
    return '';
  }

  /// Human-friendly relative time, e.g. "just now", "5 min ago", "Yesterday".
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
