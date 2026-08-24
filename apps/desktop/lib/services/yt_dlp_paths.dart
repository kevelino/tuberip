import 'dart:io';

import 'package:path/path.dart' as p;

/// XDG / platform paths and GitHub asset names for the managed yt-dlp binary.
class YtDlpPaths {
  static const linuxDataSubdir = 'tuberip';
  static const macDataSubdir = 'tuberip';
  static const windowsDataSubdir = 'TubeRip';

  static String fileName({bool? isWindows}) {
    final windows = isWindows ?? Platform.isWindows;
    return windows ? 'yt-dlp.exe' : 'yt-dlp';
  }

  /// Standalone release asset (matches AppImage packaging, not the zipapp).
  static String releaseAssetName({String? os, String? arch}) {
    final platform = (os ?? Platform.operatingSystem).toLowerCase();
    final resolvedArch = arch ?? _currentArch();

    if (platform.startsWith('win')) {
      return 'yt-dlp.exe';
    }
    if (platform == 'macos' || platform == 'osx' || platform == 'darwin') {
      return 'yt-dlp_macos';
    }
    if (resolvedArch == 'aarch64' || resolvedArch == 'arm64') {
      return 'yt-dlp_linux_aarch64';
    }
    return 'yt-dlp_linux';
  }

  static String _currentArch() {
    final env =
        Platform.environment['HOSTTYPE'] ??
        Platform.environment['CPU'] ??
        '';
    if (env.isNotEmpty) return env;
    // Dart has no portable uname; fall back to ABI.
    if (const bool.fromEnvironment('dart.library.io')) {
      try {
        final info = Process.runSync('uname', ['-m']);
        if (info.exitCode == 0) {
          return info.stdout.toString().trim();
        }
      } catch (_) {}
    }
    return Platform.version.contains('arm') ? 'aarch64' : 'x86_64';
  }

  static String managedDirectory({
    Map<String, String>? environment,
    String? home,
    String? os,
  }) {
    final env = environment ?? Platform.environment;
    final platform = (os ?? Platform.operatingSystem).toLowerCase();
    final homeDir =
        home ?? env['HOME'] ?? env['USERPROFILE'] ?? Directory.current.path;

    if (platform.startsWith('win')) {
      final local = env['LOCALAPPDATA'];
      if (local != null && local.isNotEmpty) {
        return p.join(local, windowsDataSubdir, 'bin');
      }
      return p.join(homeDir, 'AppData', 'Local', windowsDataSubdir, 'bin');
    }

    if (platform == 'macos' || platform == 'osx' || platform == 'darwin') {
      return p.join(
        homeDir,
        'Library',
        'Application Support',
        macDataSubdir,
        'bin',
      );
    }

    final xdg = env['XDG_DATA_HOME'];
    if (xdg != null && xdg.isNotEmpty) {
      return p.join(xdg, linuxDataSubdir, 'bin');
    }
    return p.join(homeDir, '.local', 'share', linuxDataSubdir, 'bin');
  }

  static String managedBinaryPath({
    Map<String, String>? environment,
    String? home,
    String? os,
    bool? isWindows,
  }) {
    return p.join(
      managedDirectory(environment: environment, home: home, os: os),
      fileName(isWindows: isWindows ?? (os?.toLowerCase().startsWith('win'))),
    );
  }
}

/// Compare yt-dlp versions like `2026.08.19` (optional `v` prefix).
class YtDlpVersion {
  static String normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';
    s = s.split(RegExp(r'\s+')).first;
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    return s;
  }

  static List<int> _parts(String version) {
    return normalize(version).split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  static int compare(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  static bool isNewer(String remote, String local) => compare(remote, local) > 0;
}

Future<void> makeExecutable(File file) async {
  if (Platform.isWindows) return;
  await Process.run('chmod', ['+x', file.path]);
}

/// Copy [sourcePath] to [destPath], creating parents and setting +x.
Future<void> seedSidecarToManaged(String sourcePath, String destPath) async {
  final dest = File(destPath);
  await dest.parent.create(recursive: true);
  await File(sourcePath).copy(destPath);
  await makeExecutable(dest);
}

/// Write [bytes] to `target.tmp`, then rename over [target].
Future<File> atomicReplaceBinary(File target, List<int> bytes) async {
  if (bytes.isEmpty) {
    throw StateError('Refusing to install an empty yt-dlp binary');
  }
  await target.parent.create(recursive: true);
  final tmp = File('${target.path}.tmp');
  await tmp.writeAsBytes(bytes, flush: true);
  await makeExecutable(tmp);
  try {
    await tmp.rename(target.path);
  } on FileSystemException {
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(target.path);
  }
  return target;
}

/// Parse `SHA2-256SUMS` lines (`<hex>  filename` or `<hex> *filename`).
String? sha256ForAsset(String sumsBody, String assetName) {
  for (final raw in sumsBody.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final match = RegExp(
      r'^([a-fA-F0-9]{64})\s+\*?(\S+)\s*$',
    ).firstMatch(line);
    if (match == null) continue;
    if (match.group(2) == assetName) {
      return match.group(1)!.toLowerCase();
    }
  }
  return null;
}
