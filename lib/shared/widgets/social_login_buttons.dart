import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/social_auth_service.dart';
import '../../core/utils/auth_error_handler.dart';
import '../../shared/providers/auth_provider.dart';
import '../theme/modern_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        // Modern divider with text
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.2),
                      isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Or continue with',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.4),
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Modern social login buttons
        Row(
          children: [
            Expanded(
              child: _ModernSocialButton(
                icon: 'assets/icons/google.png',
                fallbackIcon: Icons.g_mobiledata,
                label: 'Google',
                isGoogle: true,
                onPressed: isLoading ? null : handleGoogleSignIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernSocialButton(
                icon: 'assets/icons/facebook.png',
                fallbackIcon: Icons.facebook,
                label: 'Facebook',
                isGoogle: false,
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

class _ModernSocialButton extends StatefulWidget {
  final String? icon;
  final IconData fallbackIcon;
  final String label;
  final bool isGoogle;
  final VoidCallback? onPressed;

  const _ModernSocialButton({
    this.icon,
    required this.fallbackIcon,
    required this.label,
    required this.isGoogle,
    this.onPressed,
  });

  @override
  State<_ModernSocialButton> createState() => _ModernSocialButtonState();
}

class _ModernSocialButtonState extends State<_ModernSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.microAnimationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Google colors
    final googleBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final googleBorder = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3);
    final googleText = isDark ? Colors.white : Colors.black87;
    
    // Facebook colors
    final facebookBg = const Color(0xFF1877F2);
    final facebookText = Colors.white;

    final bgColor = widget.isGoogle ? googleBg : facebookBg;
    final textColor = widget.isGoogle ? googleText : facebookText;
    final borderColor = widget.isGoogle ? googleBorder : null;

    Widget buttonContent = Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: widget.onPressed != null
            ? [
                BoxShadow(
                  color: (widget.isGoogle ? Colors.black : const Color(0xFF1877F2))
                      .withValues(alpha: widget.isGoogle ? 0.05 : 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon != null
              ? Image.asset(
                  widget.icon!,
                  width: 22,
                  height: 22,
                  errorBuilder: (ctx, err, st) => Icon(widget.fallbackIcon, size: 22, color: textColor),
                )
              : Icon(widget.fallbackIcon, size: 22, color: textColor),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: buttonContent,
          );
        },
      ),
    );
  }
}
