import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/social_login_buttons.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy Policy to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Create basic user profile
      final isMasterAdmin = _emailController.text.trim().toLowerCase() == 'admin@betteryou.com' || 
                            _emailController.text.trim().toLowerCase() == 'admin2@betteryou.com' ||
                            _emailController.text.trim().toLowerCase() == 'admin3@betteryou.com';
      
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: isMasterAdmin ? UserRole.admin : UserRole.initial,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: isMasterAdmin, // Admin bypasses onboarding
      );

      await authService.createUserProfile(user);

      // Send email verification (skip for admin accounts)
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
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthErrorHandler.getFriendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Better You for a healthier lifestyle',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your name';
                    if (value.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least one uppercase letter';
                    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Create Account',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                
                // Social Login Buttons
                SocialLoginButtons(
                  isLoading: _isLoading,
                  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
                ),
                const SizedBox(height: 16),
                
                // Quick sign up hint
                Center(
                  child: Text(
                    'Or sign up quickly with Google or Facebook',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            children: [
              const Text('I agree to the ', style: TextStyle(fontSize: 13)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalDocType.terms)),
                ),
                child: const Text('Terms of Service', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const Text(' and ', style: TextStyle(fontSize: 13)),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LegalScreen(type: LegalDocType.privacy)),
                ),
                child: const Text('Privacy Policy', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
