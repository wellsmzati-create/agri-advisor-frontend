import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'epa/epa_theme.dart';
import 'epa/screens/epa_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/main_shell.dart';
import 'theme/app_theme.dart';
import 'web/screens/web_login_screen.dart';
import 'web/screens/web_shell.dart';
import 'web/web_theme.dart';

ThemeData appThemeForRole(String? role) {
  return switch (role) {
    'advisor' => WebTheme.theme,
    'epa' => EpaTheme.theme,
    'farmer' => AppTheme.theme,
    _ when kIsWeb => WebTheme.theme,
    _ => AppTheme.theme,
  };
}

Widget loginScreenForPlatform() => kIsWeb ? const WebLoginScreen() : const LoginScreen();

Widget shellForRole(String role) => switch (role) {
  'advisor' => const WebShell(),
  'epa' => const EpaShell(),
  _ => const MainShell(),
};
