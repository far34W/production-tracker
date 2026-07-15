// lib/screens/login_screen.dart
//
// Modern login screen for the Production Tracker.
// Matches the app's industrial steel-blue palette.
// All auth logic lives in AuthProvider — this screen is pure UI.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Make the status bar match the gradient
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildCard(),
                          const SizedBox(height: 28),
                          _buildHint(),
                        ],
                      ),
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

  // ── Background gradient ────────────────────────────────────────────────────

  Widget _buildBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF002171), // primaryDark
          Color(0xFF0D47A1), // primary
          Color(0xFF1565C0), // primaryLight
          Color(0xFF1976D2),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ),
    ),
  );

  // ── Logo + title ───────────────────────────────────────────────────────────

  Widget _buildHeader() => Column(
    children: [
      // Logo mark
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.factory_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Production Tracker',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Sign in to access your dashboard',
        style: TextStyle(
          color: Colors.white.withOpacity(0.75),
          fontSize: 14,
        ),
      ),
    ],
  );

  // ── Main card ─────────────────────────────────────────────────────────────

  Widget _buildCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ],
    ),
    padding: const EdgeInsets.all(32),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your credentials to continue.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 28),

          // ── Email ──────────────────────────────
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
          ),
          const SizedBox(height: 16),

          // ── Password ───────────────────────────
          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            onChanged: (_) => context.read<AuthProvider>().clearError(),
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          // ── Server error message ───────────────
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (auth.errorMessage == null) return const SizedBox(height: 20);
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: _ErrorBanner(message: auth.errorMessage!),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Login button ───────────────────────
          Consumer<AuthProvider>(
            builder: (_, auth, __) => _LoginButton(
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : _submit,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Demo credentials hint ─────────────────────────────────────────────────

  Widget _buildHint() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 14, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          'Demo: admin@example.com / password',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth    = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text, _passwordCtrl.text);

    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(auth.errorMessage!)),
            ],
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // Navigation is handled by AuthGate — no Navigator.push needed.
  }
}

// ── Login button with loading state ──────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0D47A1).withOpacity(0.7),
          elevation: isLoading ? 0 : 3,
          shadowColor: const Color(0xFF0D47A1).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  key: ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Error banner (shown inside the card) ─────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
