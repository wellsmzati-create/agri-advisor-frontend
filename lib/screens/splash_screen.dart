import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../app_routing.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Run session restore and minimum splash duration in parallel.
    await Future.wait([
      context.read<AuthProvider>().restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    final destination = auth.status == AuthStatus.authenticated
        ? shellForRole(auth.user?.role ?? 'farmer')
        : loginScreenForPlatform();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientGreen),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🌾', style: TextStyle(fontSize: 56)),
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 28),
                const Text(
                  'AgriAdvisor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ).animate(delay: 300.ms).slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 10),
                Text(
                  'Smart Farming. Better Harvests.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 500.ms).slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 80),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Colors.white.withOpacity(0.7),
                    strokeWidth: 2.5,
                  ),
                ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
