import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../app_routing.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'farmer@agri.local');
  final _passCtrl = TextEditingController(text: 'password');
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted || !ok) return;
    final destination = shellForRole(auth.user?.role ?? 'farmer');
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
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌾', style: TextStyle(fontSize: 52))
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      const Text(
                        'AgriAdvisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 4),
                      Text(
                        'Your Smart Farming Companion',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Consumer<AuthProvider>(
                        builder: (_, auth, __) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Welcome Back 👋',
                                style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text('Sign in to your account',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 28),
                            if (auth.error != null)
                              _ErrorBanner(
                                message: auth.error!,
                                onDismiss: auth.clearError,
                              ),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: AppColors.primary),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Enter your email' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => v == null || v.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.busy ? null : _login,
                                child: auth.busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ",
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RegisterScreen()),
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13))),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close, color: Colors.red, size: 16),
        ),
      ]),
    );
  }
}
