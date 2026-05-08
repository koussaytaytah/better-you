import 'dart:async';
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
  bool _hasNavigated = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Timeout fallback: if auth takes > 6 seconds, redirect to login
    _timeoutTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_hasNavigated) {
        _navigate('/login');
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _navigate(String route) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    authState.whenOrNull(
      data: (user) {
        // GoRouter redirect will handle the actual destination
        // We just need to leave the splash — go to dashboard root
        // and let the router's redirect function decide where to go
        _navigate('/dashboard');
      },
      error: (e, _) {
        _navigate('/login');
      },
    );

    return _buildSplash();
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F24),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 600.ms,
                    curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Text(
              'Better You',
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Your Health, Bettered.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            const SizedBox(height: 64),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.7)),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
