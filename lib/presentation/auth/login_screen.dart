import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
        _isLoading = false;
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
        _isLoading = false;
      });
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password);
      // Navigation handled by AppRouter's auth listener
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            _errorMessage = 'Invalid email or password.';
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
          case 'too-many-requests':
            _errorMessage = 'Too many attempts. Please try again later.';
          case 'network-request-failed':
            _errorMessage = 'No internet connection.';
          default:
            _errorMessage = 'Authentication failed. Please try again.';
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // Allows layout to shift when keyboard opens on small screens
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              // Horizontal: 24dp — Material 3 canonical page margin
              // Vertical: 48dp top, 32dp bottom
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Brand ─────────────────────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Heading group ──────────────────────────────────────────
                  Text(
                    'Welcome back',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to your SmartSpend account',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ── Error banner ───────────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.negative.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.negative.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.negative, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.negative),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Email field ────────────────────────────────────────────
                  _buildLabel('Email address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocusNode),
                    decoration: _fieldDecoration(
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                    ),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                  ),

                  const SizedBox(height: 20),

                  // ── Password field ─────────────────────────────────────────
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isLoading ? null : _login(),
                    decoration: _fieldDecoration(
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15),
                  ),

                  // ── Forgot Password — 14dp below the field ─────────────────
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      label: 'Reset your password',
                      button: true,
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : () => context.go('/forgot-password'),
                        style: TextButton.styleFrom(
                          // Padding keeps the tap zone 44dp tall without
                          // adding extra visual whitespace
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 10),
                          minimumSize: const Size(88, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          overlayColor:
                              AppColors.accentAI.withValues(alpha: 0.08),
                          foregroundColor: AppColors.accentAI,
                          animationDuration:
                              const Duration(milliseconds: 150),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.accentAI.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 24dp gap to Login button ───────────────────────────────
                  const SizedBox(height: 24),

                  // ── Login button ───────────────────────────────────────────
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentAI,
                      disabledBackgroundColor:
                          AppColors.accentAI.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      // Material 3 large button height = 56dp
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('spinner'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              key: ValueKey('label'),
                              'Sign in',
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Divider ────────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Sign Up link ───────────────────────────────────────────
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      overlayColor:
                          AppColors.accentAI.withValues(alpha: 0.06),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary),
                        children: const [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              color: AppColors.accentAI,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
      filled: true,
      fillColor: AppColors.surfaceHighlight,
      // Consistent 52dp height via content padding
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.accentAI, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
