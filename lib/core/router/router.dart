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
import '../../features/nutrition/screens/nutrition_dashboard_screen.dart';
import '../../features/nutrition/screens/recipes_screen.dart';
import '../../features/nutrition/screens/meal_planning_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart' as gamification;
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/coach/screens/browse_coaches_screen.dart';
import '../../features/coach/screens/my_sessions_screen.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../../features/settings/screens/terms_screen.dart';

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
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const NutritionDashboardScreen(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipesScreen(),
      ),
      GoRoute(
        path: '/meal-plan',
        builder: (context, state) => const MealPlanningScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const gamification.LeaderboardScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/browse-coaches',
        builder: (context, state) => const BrowseCoachesScreen(),
      ),
      GoRoute(
        path: '/my-sessions',
        builder: (context, state) {
          final userId = state.extra as String? ?? '';
          return MySessionsScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const LegalScreen(type: LegalDocType.terms),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const LegalScreen(type: LegalDocType.privacy),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
