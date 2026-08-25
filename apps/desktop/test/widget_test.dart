import 'package:desktop/app.dart';
import 'package:desktop/services/binary_manager.dart';
import 'package:desktop/services/download_manager.dart';
import 'package:desktop/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TubeRip app shows header and CTA', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();
    final config = await settings.loadConfig();
    final dm = DownloadManager(
      binaryManager: BinaryManager(
        customYtDlpPath: config.ytDlpPath,
        customFfmpegPath: config.ffmpegPath,
      ),
    )..config = config;

    await tester.binding.setSurfaceSize(const Size(1100, 800));
    await tester.pumpWidget(
      TubeRipApp(settings: settings, downloadManager: dm),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsWidgets);
    expect(find.textContaining('Download'), findsWidgets);
    expect(find.text('No downloads yet'), findsOneWidget);
  });
}
