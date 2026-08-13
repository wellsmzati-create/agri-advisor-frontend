import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'epa_theme.dart';
import 'screens/epa_shell.dart';

class EpaWebApp extends StatelessWidget {
  const EpaWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriAdvisor — EPA Officer Dashboard',
      debugShowCheckedModeBanner: false,
      theme: EpaTheme.theme,
      home: const EpaShell(),
    );
  }
}

class EpaLoginScreen extends StatefulWidget {
  const EpaLoginScreen({super.key});

  @override
  State<EpaLoginScreen> createState() => _EpaLoginScreenState();
}

class _EpaLoginScreenState extends State<EpaLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'k.agyeman@epa.gov.gh');
  final _passCtrl  = TextEditingController(text: '••••••••');
  bool _remember = true, _obscure = true, _loading = false;

  void _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EpaShell()));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: EpaColors.pageBg,
      body: Row(children: [
        if (isWide) Expanded(flex: 5, child: _LeftPanel()),
        Expanded(
          flex: isWide ? 4 : 10,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _LoginForm(
                  emailCtrl: _emailCtrl, passCtrl: _passCtrl,
                  remember: _remember, obscure: _obscure, loading: _loading,
                  onRemember: (v) => setState(() => _remember = v ?? false),
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onLogin: _login,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF0D3B6E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: EpaColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AgriAdvisor', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('EPA Intelligence Platform', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ]),
            ]).animate().fadeIn(duration: 600.ms),
            const Spacer(),
            Text('Agricultural\nIntelligence\nCommand Center.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1.15),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 20),
            Text('Monitor outbreaks, supervise extension workers, coordinate EPA-wide agricultural responses, and generate intelligence reports.',
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.6),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 32),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _Chip(icon: Icons.warning_amber, label: '5 Active Alerts'),
              _Chip(icon: Icons.people, label: '6 Extension Workers'),
              _Chip(icon: Icons.analytics, label: 'Real-time Monitoring'),
              _Chip(icon: Icons.shield, label: 'EPA Certified'),
            ]).animate().fadeIn(delay: 600.ms, duration: 600.ms),
            const SizedBox(height: 40),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: EpaColors.danger.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: EpaColors.danger.withValues(alpha: 0.4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: EpaColors.danger, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('2 Critical Outbreaks Pending Validation', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ])),
            ]).animate().fadeIn(delay: 800.ms, duration: 600.ms),
          ]),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: EpaColors.primaryLight, size: 14),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final bool remember, obscure, loading;
  final ValueChanged<bool?> onRemember;
  final VoidCallback onToggleObscure, onLogin;

  const _LoginForm({required this.emailCtrl, required this.passCtrl,
    required this.remember, required this.obscure, required this.loading,
    required this.onRemember, required this.onToggleObscure, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: EpaColors.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shield, color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AgriAdvisor EPA', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)),
          Text('Officer Portal', style: GoogleFonts.inter(fontSize: 11, color: EpaColors.textSecondary)),
        ]),
      ]).animate().fadeIn(duration: 500.ms),
      const SizedBox(height: 32),
      Text('Officer Sign In', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: EpaColors.textPrimary)).animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 6),
      Text('Access the EPA Agricultural Intelligence Dashboard', style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary)).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 28),
      _Field(label: 'EPA Email Address', controller: emailCtrl, icon: Icons.badge_outlined).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 14),
      _Field(label: 'Password', controller: passCtrl, icon: Icons.lock_outline, obscure: obscure,
        suffix: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: EpaColors.textSecondary), onPressed: onToggleObscure),
      ).animate().fadeIn(delay: 400.ms),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          SizedBox(width: 18, height: 18, child: Checkbox(value: remember, onChanged: onRemember, activeColor: EpaColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
          const SizedBox(width: 8),
          Text('Remember me', style: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary)),
        ]),
        TextButton(onPressed: () {}, child: Text('Forgot password?', style: GoogleFonts.inter(fontSize: 13, color: EpaColors.primary, fontWeight: FontWeight.w500))),
      ]).animate().fadeIn(delay: 500.ms),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: loading ? null : onLogin,
          style: ElevatedButton.styleFrom(backgroundColor: EpaColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Sign In to EPA Dashboard', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ).animate().fadeIn(delay: 600.ms),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: EpaColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: EpaColors.primary.withValues(alpha: 0.15))),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: EpaColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Demo credentials pre-filled. Click Sign In to explore the EPA dashboard.', style: GoogleFonts.inter(fontSize: 12, color: EpaColors.primary))),
        ]),
      ).animate().fadeIn(delay: 700.ms),
    ]);
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;

  const _Field({required this.label, required this.controller, required this.icon, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: EpaColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: EpaColors.textSecondary), suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EpaColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EpaColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EpaColors.primary, width: 1.5)),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); }
    for (double y = 0; y < size.height; y += 40) { canvas.drawLine(Offset(0, y), Offset(size.width, y), paint); }
  }
  @override bool shouldRepaint(_) => false;
}
