import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/user_onboarding_screen.dart';
import '../../features/onboarding/screens/coach_onboarding_screen.dart';
import '../../features/onboarding/screens/doctor_onboarding_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

import '../../shared/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      if (isLoggedIn) {
        // Only redirect if we effectively know the user document
        if (currentUser != null && !currentUser.hasCompletedOnboarding) {
          if (state.matchedLocation != '/user-onboarding' && currentUser.role.name == 'user') {
            return '/user-onboarding';
          }
        } else if (isLoggingIn && state.matchedLocation != '/') {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/user-onboarding',
        builder: (context, state) => const UserOnboardingScreen(),
      ),
      GoRoute(
        path: '/coach-onboarding',
        builder: (context, state) => const CoachOnboardingScreen(),
      ),
      GoRoute(
        path: '/doctor-onboarding',
        builder: (context, state) => const DoctorOnboardingScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
