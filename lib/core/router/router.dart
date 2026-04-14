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
import '../../features/auth/screens/pending_verification_screen.dart';
import '../../features/coach/screens/coach_dashboard_screen.dart';
import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/profile_screen.dart';
import '../../features/community/screens/global_chat_screen.dart';
import '../../features/community/screens/leaderboard_screen.dart';
import '../../features/main_layout/screens/main_scaffold.dart';

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
        if (currentUser != null) {
          final role = currentUser.role.name;
          
          // FORCED ROLE SELECTION
          if (role == 'initial' && state.matchedLocation != '/role-selection') {
            return '/role-selection';
          }

          if (!currentUser.hasCompletedOnboarding) {
            if (role == 'user' && state.matchedLocation != '/user-onboarding') return '/user-onboarding';
            if (role == 'coach' && state.matchedLocation != '/coach-onboarding') return '/coach-onboarding';
            if (role == 'doctor' && state.matchedLocation != '/doctor-onboarding') return '/doctor-onboarding';
          } else {
            // Fully onboarded users
            if (role == 'admin') {
              if (state.matchedLocation == '/' || state.matchedLocation == '/login' || state.matchedLocation == '/register') return '/admin';
            } else if (role == 'coach') {
              if (currentUser.verificationStatus != 'approved') {
                if (state.matchedLocation != '/pending-verification') return '/pending-verification';
              } else {
                if (state.matchedLocation == '/' || state.matchedLocation == '/login' || state.matchedLocation == '/register') return '/coach-dashboard';
              }
            } else if (role == 'doctor') {
              if (currentUser.verificationStatus != 'approved') {
                if (state.matchedLocation != '/pending-verification') return '/pending-verification';
              } else {
                if (state.matchedLocation == '/' || state.matchedLocation == '/login' || state.matchedLocation == '/register') return '/doctor-dashboard';
              }
            } else if (role == 'user') {
              if (state.matchedLocation == '/' || state.matchedLocation == '/login' || state.matchedLocation == '/register') return '/dashboard';
            }
          }
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const GlobalChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quests',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/coach-dashboard',
        builder: (context, state) => const CoachDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor-dashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/pending-verification',
        builder: (context, state) => const PendingVerificationScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
