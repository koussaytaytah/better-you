import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/social_auth_service.dart';
import '../../core/utils/auth_error_handler.dart';
import '../../shared/providers/auth_provider.dart';

class SocialLoginButtons extends ConsumerWidget {
  final bool isLoading;
  final Function(bool) onLoadingChanged;

  const SocialLoginButtons({
    super.key,
    required this.isLoading,
    required this.onLoadingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialAuthService = SocialAuthService();

    Future<void> handleGoogleSignIn() async {
      onLoadingChanged(true);
      try {
        final userCredential = await socialAuthService.signInWithGoogle();
        
        if (userCredential == null) {
          onLoadingChanged(false);
          return; // User cancelled
        }

        // Refresh the user state
        await ref.read(currentUserAsyncProvider.notifier).refreshUser();

        if (!context.mounted) return;

        // Check if user needs role selection
        final needsRole = await socialAuthService.needsRoleSelection(userCredential.user!.uid);
        final hasOnboarded = await socialAuthService.hasCompletedOnboarding(userCredential.user!.uid);

        if (!context.mounted) return;
        if (needsRole) {
          context.go('/role-selection');
        } else if (!hasOnboarded) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final role = user.role.name;
            if (!context.mounted) return;
            if (role == 'user') {
              context.go('/user-onboarding');
            } else if (role == 'coach') {
              context.go('/coach-onboarding');
            } else if (role == 'doctor') {
              context.go('/doctor-onboarding');
            } else {
              context.go('/role-selection');
            }
          }
        } else {
          context.go('/dashboard');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, AuthErrorHandler.getFriendlyErrorMessage(e));
        }
      } finally {
        onLoadingChanged(false);
      }
    }

    Future<void> handleFacebookSignIn() async {
      onLoadingChanged(true);
      try {
        final userCredential = await socialAuthService.signInWithFacebook();
        
        if (userCredential == null) {
          onLoadingChanged(false);
          return; // User cancelled
        }

        // Refresh the user state
        await ref.read(currentUserAsyncProvider.notifier).refreshUser();

        if (!context.mounted) return;

        // Check if user needs role selection
        final needsRole = await socialAuthService.needsRoleSelection(userCredential.user!.uid);
        final hasOnboarded = await socialAuthService.hasCompletedOnboarding(userCredential.user!.uid);

        if (!context.mounted) return;
        if (needsRole) {
          context.go('/role-selection');
        } else if (!hasOnboarded) {
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final role = user.role.name;
            if (!context.mounted) return;
            if (role == 'user') {
              context.go('/user-onboarding');
            } else if (role == 'coach') {
              context.go('/coach-onboarding');
            } else if (role == 'doctor') {
              context.go('/doctor-onboarding');
            } else {
              context.go('/role-selection');
            }
          }
        } else {
          context.go('/dashboard');
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, AuthErrorHandler.getFriendlyErrorMessage(e));
        }
      } finally {
        onLoadingChanged(false);
      }
    }

    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 24),
        
        // Social login buttons
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/google.png',
                fallbackIcon: Icons.g_mobiledata,
                label: 'Google',
                color: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey[300]!,
                onPressed: isLoading ? null : handleGoogleSignIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/facebook.png',
                fallbackIcon: Icons.facebook,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                textColor: Colors.white,
                onPressed: isLoading ? null : handleFacebookSignIn,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String? icon;
  final IconData fallbackIcon;
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null 
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon != null
            ? Image.asset(
                icon!,
                width: 24,
                height: 24,
                errorBuilder: (ctx, err, st) => Icon(fallbackIcon, size: 24),
              )
            : Icon(fallbackIcon, size: 24, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
