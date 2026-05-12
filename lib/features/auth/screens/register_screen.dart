import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/social_login_buttons.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../core/utils/auth_error_handler.dart';
import '../../../features/settings/screens/terms_screen.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Please agree to the Terms and Privacy Policy to continue.'),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final isMasterAdmin = _emailController.text.trim().toLowerCase() == 'admin@betteryou.com' || 
                            _emailController.text.trim().toLowerCase() == 'admin2@betteryou.com' ||
                            _emailController.text.trim().toLowerCase() == 'admin3@betteryou.com';
      
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: isMasterAdmin ? UserRole.admin : UserRole.initial,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: isMasterAdmin,
      );

      await authService.createUserProfile(user);

      if (!isMasterAdmin) {
        await authService.sendEmailVerification();
      }

      if (mounted) {
        if (isMasterAdmin) {
          context.go('/role-selection');
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(AuthErrorHandler.getFriendlyErrorMessage(e))),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join Better You and start your health journey today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textLight,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                
                const SizedBox(height: 32),
                
                // Registration Card
                ModernCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your name';
                          if (value.trim().length < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a strong password',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 8) return 'Password must be at least 8 characters';
                          if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least one uppercase letter';
                          if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
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
                      
                      const SizedBox(height: 20),
                      
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20),
                
                const SizedBox(height: 24),
                
                // Terms Checkbox
                _TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _agreedToTerms = v ?? false);
                  },
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 24),
                
                // Create Account Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                  height: 58,
                  icon: Icons.person_add_outlined,
                ).animate().fadeIn(delay: 400.ms).scale(),
                
                const SizedBox(height: 24),
                
                // Social Login
                SocialLoginButtons(
                  isLoading: _isLoading,
                  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
                ).animate().fadeIn(delay: 500.ms),
                
                const SizedBox(height: 24),
                
                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final void Function(bool?) onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value 
              ? AppColors.primary.withValues(alpha: 0.5)
              : isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  'I agree to the ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[700]),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalDocType.terms)),
                  ),
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[700]),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalDocType.privacy)),
                  ),
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
