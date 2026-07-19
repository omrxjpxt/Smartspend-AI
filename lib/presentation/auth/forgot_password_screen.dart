import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  late final AnimationController _successAnimController;
  late final Animation<double> _successFadeIn;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successFadeIn = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeOut,
    );
    // Auto-focus the email field on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  /// Validates the email field locally before hitting Firebase.
  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  /// Maps FirebaseAuthException codes to friendly messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _sendResetLink() async {
    // Dismiss keyboard
    _emailFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final validationError = _validateEmail(email);

    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        _successAnimController.forward();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapFirebaseError(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _emailSent
              ? _buildSuccessView()
              : _buildFormView(),
        ),
      ),
    );
  }

  // ─── Form View ─────────────────────────────────────────────────────────────

  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              label: 'Go back to Login',
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => context.go('/login'),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Lock icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentAI.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Subtitle
          Text(
            "Enter your email address and we'll send you a link to reset your password.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Error banner
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _errorMessage != null
                ? Container(
                    margin:
                        const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.negative, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Email field
          Semantics(
            label: 'Email address',
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onSubmitted: (_) => _sendResetLink(),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _errorMessage != null
                        ? AppColors.negative.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.accentAI, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.textSecondary),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Send Reset Link button
          Semantics(
            label: 'Send reset link',
            button: true,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAI,
                disabledBackgroundColor:
                    AppColors.accentAI.withValues(alpha: 0.5),
                padding:
                    const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        key: ValueKey('label'),
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Back to Login text button
          TextButton(
            onPressed: _isLoading ? null : () => context.go('/login'),
            child: Text(
              'Back to Login',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success View ───────────────────────────────────────────────────────────

  Widget _buildSuccessView() {
    return FadeTransition(
      key: const ValueKey('success'),
      opacity: _successFadeIn,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success icon with glow
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.positive.withValues(alpha: 0.30),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.positive,
                  size: 48,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Success title
            Text(
              'Check your inbox!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Success description
            Text(
              'Password reset email sent.\n\nCheck your inbox (and spam folder) for instructions to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Sent-to info chip
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.accentAI, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _emailController.text.trim(),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Return to Login button
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAI,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Return to Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Resend link
            TextButton(
              onPressed: () {
                setState(() {
                  _emailSent = false;
                  _successAnimController.reset();
                });
              },
              child: Text(
                "Didn't receive it? Try again",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
