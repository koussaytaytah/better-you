import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00A86B),
              const Color(0xFF00D68A),
              const Color(0xFF00A86B).withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container with Pulse Animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      size: 56,
                      color: Color(0xFF00A86B),
                    ),
                  ),
                )
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 600.ms)
                    .then(delay: 200.ms)
                    .shake(duration: 400.ms, rotation: 0.05),
                
                const SizedBox(height: 40),
                
                // App Name
                Text(
                  'Better You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                
                const SizedBox(height: 12),
                
                // Tagline
                Text(
                  'Your Health, Bettered.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms),
                
                const SizedBox(height: 80),
                
                // Loading Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                
                const SizedBox(height: 40),
                
                // Loading Text
                Text(
                  'Loading...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
