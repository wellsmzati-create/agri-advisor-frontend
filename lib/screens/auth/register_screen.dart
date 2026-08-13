import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_routing.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _farmNameCtrl = TextEditingController();
  final _farmLocationCtrl = TextEditingController();
  final _farmSizeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _farmNameCtrl.dispose();
    _farmLocationCtrl.dispose();
    _farmSizeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
      phone: _phoneCtrl.text.trim(),
      farmName: _farmNameCtrl.text.trim(),
      farmLocation: _farmLocationCtrl.text.trim(),
      farmSizeAcres: int.tryParse(_farmSizeCtrl.text.trim()) ?? 0,
    );
    if (!mounted || !ok) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => shellForRole(auth.user?.role ?? 'farmer'),
      ),
      (_) => false,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
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
                            Text('Join AgriAdvisor 🌱',
                                style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text('Register your first farm and get matched to the right EPA advisor',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            const Text(
                              'Your account is personal, but advisor assignment now happens per farm location.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (auth.error != null)
                              _ErrorBanner(
                                  message: auth.error!,
                                  onDismiss: auth.clearError),
                            _field(_nameCtrl, 'Full Name', Icons.person_outline,
                                capitalize: TextCapitalization.words,
                                validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            _field(_emailCtrl, 'Email', Icons.email_outlined,
                                type: TextInputType.emailAddress,
                                validator: (v) =>
                                    !v!.contains('@') ? 'Enter a valid email' : null),
                            const SizedBox(height: 16),
                            _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                                type: TextInputType.phone,
                                hint: '+265 XX XXX XXXX',
                                validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            _field(_farmNameCtrl, 'Primary Farm Name',
                                Icons.agriculture_outlined,
                                capitalize: TextCapitalization.words,
                                hint: 'Main Farm Plot',
                                validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            _field(_farmLocationCtrl, 'Primary Farm Location',
                                Icons.location_on_outlined,
                                hint: 'Village, district, or landmark',
                                validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 16),
                            _field(_farmSizeCtrl, 'Primary Farm Size (acres)',
                                Icons.landscape_outlined,
                                type: TextInputType.number,
                                validator: (v) => int.tryParse(v ?? '') == null
                                    ? 'Enter a valid number'
                                    : null),
                            const SizedBox(height: 16),
                            _passwordField(
                              ctrl: _passCtrl,
                              label: 'Password',
                              obscure: _obscure,
                              onToggle: () =>
                                  setState(() => _obscure = !_obscure),
                              validator: (v) => v!.length < 6
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _passwordField(
                              ctrl: _confirmCtrl,
                              label: 'Confirm Password',
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                              validator: (v) => v != _passCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.busy ? null : _register,
                                child: auth.busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account? ',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Sign In',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: capitalize,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
    );
  }

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
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
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13))),
        GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.red, size: 16)),
      ]),
    );
  }
}
