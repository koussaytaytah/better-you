import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/social_login_buttons.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/theme/modern_theme.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';
import '../../../core/utils/auth_error_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService
          .signIn(_emailController.text.trim(), _passwordController.text.trim())
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      await authService.reloadUser();
      if (!authService.isEmailVerified) {
        await authService.signOut();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
        }
        return;
      }

      await ref.read(currentUserAsyncProvider.notifier).refreshUser();

      if (!mounted) return;

      context.go('/dashboard');
    } catch (e) {
      _showErrorSnackBar(AuthErrorHandler.getFriendlyErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        title: Text(
          'Reset Password',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkTextLight : Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          SecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          CustomButton(
            text: 'Send Reset Link',
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(AuthErrorHandler.getFriendlyErrorMessage(e))),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
    emailCtrl.dispose();
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    if (_lastTap == null ||
        now.difference(_lastTap!) > const Duration(seconds: 1)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTap = now;

    if (_tapCount >= 3) {
      _tapCount = 0;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin Login Detected'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Logo & Welcome
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: ModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 400.ms),
                
                const SizedBox(height: 32),
                
                // Welcome Text
                Center(
                  child: GestureDetector(
                    onTap: _handleTitleTap,
                    child: Text(
                      'Welcome Back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 8),
                
                Center(
                  child: Text(
                    'Sign in to continue your health journey',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 48),
                
                // Login Card
                ModernCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).moveX(begin: -30),
                
                const SizedBox(height: 32),
                
                // Sign In Button
                CustomButton(
                  text: 'Sign In',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  height: 58,
                ).animate().fadeIn(delay: 600.ms).scale(),
                
                const SizedBox(height: 24),
                
                // Social Login
                SocialLoginButtons(
                  isLoading: _isLoading,
                  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
                ).animate().fadeIn(delay: 750.ms),
                
                const SizedBox(height: 32),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
