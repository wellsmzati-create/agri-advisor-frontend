import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_routing.dart';
import 'providers/auth_provider.dart';
import 'providers/farmer_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmerProvider()),
      ],
      child: const AgriAdvisorApp(),
    ),
  );
}

class AgriAdvisorApp extends StatelessWidget {
  const AgriAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => MaterialApp(
        title: 'AgriAdvisor',
        debugShowCheckedModeBanner: false,
        theme: appThemeForRole(auth.user?.role),
        home: const SplashScreen(),
      ),
    );
  }
}
