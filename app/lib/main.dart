import 'package:flutter/material.dart';
import 'src/app/app.dart';
import 'src/core/theme/theme_controller.dart';
import 'src/core/session/auth_session.dart';

/// Bootstrap: load persisted theme + session before first frame.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ThemeController.instance.load(),
    AuthSession.instance.load(),
  ]);
  runApp(const KopsisApp());
}
