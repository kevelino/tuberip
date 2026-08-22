/// Parses yt-dlp progress / speed lines from stdout.
class ProgressParser {
  const ProgressParser();

  static final _percentRe = RegExp(r'(\d+(?:\.\d+)?)\s*%');
  static final _speedRe = RegExp(r'\bat\s+([\d.]+\s*\w+/s)', caseSensitive: false);
  static final _etaRe = RegExp(r'\bETA\s+([\d:]+)', caseSensitive: false);

  /// Returns progress percent 0–100, or null if not a progress line.
  double? parsePercent(String line) {
    if (!line.contains('[download]') || !line.contains('%')) {
      return null;
    }
    final match = _percentRe.firstMatch(line);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  ({String? speed, String? eta}) parseSpeedInfo(String line) {
    final speedMatch = _speedRe.firstMatch(line);
    final etaMatch = _etaRe.firstMatch(line);
    return (
      speed: speedMatch?.group(1)?.trim(),
      eta: etaMatch != null ? 'ETA ${etaMatch.group(1)}' : null,
    );
  }

  bool isErrorLine(String line) => line.trimLeft().startsWith('ERROR:');
}
