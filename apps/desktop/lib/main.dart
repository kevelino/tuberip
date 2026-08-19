import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await windowManager.setMinSize(const Size(720, 480));
  await windowManager.setSize(const Size(860, 560));
  await windowManager.setAlignment(Alignment.center);
  await windowManager.setTitle('TubeRip');

  runApp(const TubeRipApp());
}
