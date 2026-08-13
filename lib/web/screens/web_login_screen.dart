import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_routing.dart';
import '../../providers/auth_provider.dart';
import '../web_theme.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailCtrl = TextEditingController(
    text: 'advisor@agri.local',
  );
  final _passCtrl = TextEditingController(text: 'password');
  bool _rememberMe = true;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted || !ok) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => shellForRole(auth.user?.role ?? 'advisor'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: WebColors.pageBg,
      body: Row(
        children: [
          if (isWide) Expanded(flex: 5, child: const _LeftPanel()),
          Expanded(
            flex: isWide ? 4 : 10,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Consumer<AuthProvider>(
                    builder: (_, auth, __) => _LoginForm(
                      emailCtrl: _emailCtrl,
                      passCtrl: _passCtrl,
                      rememberMe: _rememberMe,
                      obscure: _obscure,
                      loading: auth.busy,
                      error: auth.error,
                      onRememberMe: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onLogin: _login,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1923), Color(0xFF1B3A2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: WebColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AgriAdvisor',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: WebColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),
                const Spacer(),
                Text(
                  'Empowering\nAgricultural\nAdvisors.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 20),
                Text(
                  'Manage farmers, generate intelligent crop recommendations, and drive agricultural transformation across your region.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                const SizedBox(height: 40),
                Row(
                  children: const [
                    _FeatureChip(icon: Icons.people, label: '48 Farmers'),
                    SizedBox(width: 12),
                    _FeatureChip(
                      icon: Icons.recommend,
                      label: '23 Active Recs',
                    ),
                    SizedBox(width: 12),
                    _FeatureChip(icon: Icons.analytics, label: 'AI-Powered'),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                const SizedBox(height: 48),
                Row(
                  children: [
                    const _AvatarStack(),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trusted by 200+ advisors',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'across West Africa',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: WebColors.primaryLight, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    final colors = [WebColors.primary, WebColors.info, WebColors.warning];
    const initials = ['AM', 'KB', 'AO'];

    return SizedBox(
      width: 80,
      height: 32,
      child: Stack(
        children: List.generate(
          3,
          (i) => Positioned(
            left: i * 22.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(color: const Color(0xFF0F1923), width: 2),
              ),
              child: Center(
                child: Text(
                  initials[i],
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool rememberMe;
  final bool obscure;
  final bool loading;
  final String? error;
  final ValueChanged<bool?> onRememberMe;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;

  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.rememberMe,
    required this.obscure,
    required this.loading,
    this.error,
    required this.onRememberMe,
    required this.onToggleObscure,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WebColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'AgriAdvisor',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: WebColors.textPrimary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 36),
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: WebColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
        const SizedBox(height: 6),
        Text(
          'Sign in and we will route you to the correct dashboard.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: WebColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        const SizedBox(height: 32),
        if (error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error!,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        _FormField(
          label: 'Email Address',
          controller: emailCtrl,
          icon: Icons.email_outlined,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 16),
        _FormField(
          label: 'Password',
          controller: passCtrl,
          icon: Icons.lock_outline,
          obscure: obscure,
          suffix: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: WebColors.textSecondary,
            ),
            onPressed: onToggleObscure,
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: onRememberMe,
                    activeColor: WebColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember me',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: WebColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: WebColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: loading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: WebColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: WebColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: WebColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: WebColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use a backend account for advisor or EPA and the app will route automatically after sign in.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: WebColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: WebColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: WebColors.textSecondary),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: WebColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: WebColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: WebColors.primary,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
