import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // No need to call _checkAuthState here anymore, we'll watch the provider
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to determine where to go
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Once we have data (even if null), we can navigate
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/dashboard');
          }
        });
        return _buildSplash();
      },
      loading: () => _buildSplash(),
      error: (e, stack) => _buildError(e),
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Better You',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Health, Bettered.',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Auth Error: $e'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(authStateProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
