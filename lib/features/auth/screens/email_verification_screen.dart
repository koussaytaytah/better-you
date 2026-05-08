import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  Timer? _checkTimer;
  Timer? _resendCooldown;
  int _cooldownSeconds = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _resendCooldown?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  Future<void> _checkVerified() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final authService = ref.read(authServiceProvider);
      await authService.reloadUser();
      if (authService.isEmailVerified && mounted) {
        _checkTimer?.cancel();
        await ref.read(currentUserAsyncProvider.notifier).refreshUser();
        if (mounted) context.go('/role-selection');
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return;
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _cooldownSeconds = 60);
        _resendCooldown = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() {
            _cooldownSeconds--;
            if (_cooldownSeconds <= 0) t.cancel();
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authServiceProvider).isEmailVerified
        ? ''
        : (ref.read(currentUserProvider)?.email ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 52, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text('Verify Your Email', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification link to\n$email\n\nPlease check your inbox and click the link to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.6, fontSize: 15),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This page will automatically update once you verify your email.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _cooldownSeconds > 0 ? null : _resendEmail,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend Verification Email',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _checkVerified,
                icon: const Icon(Icons.refresh),
                label: const Text('I\'ve verified, check now'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _signOut,
                child: const Text('Use a different account', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
