import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../habits/screens/habit_tracker_screen.dart';
import '../../habits/screens/daily_metrics_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../community/screens/community_feed_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../screens/bmi_calculator_screen.dart';
import '../screens/progress_calendar_screen.dart';
import '../../nutrition/screens/nutrition_dashboard_screen.dart';
import '../../nutrition/screens/enhanced_food_detection_screen.dart';
import '../../nutrition/screens/recipes_screen.dart';
import '../../nutrition/screens/meal_planning_screen.dart';
import '../../settings/screens/notification_settings_screen.dart';


import '../../gamification/screens/leaderboard_screen.dart' as gamification;
import '../../profile/screens/edit_profile_screen.dart';
import '../../community/screens/professionals_directory_screen.dart';
import '../../coach/screens/browse_coaches_screen.dart';
import '../../subscription/screens/paywall_screen.dart';
import '../../settings/screens/app_limits_screen.dart';
import '../../../../shared/widgets/glass_card.dart';

// Since the router hasn't been completely refactored to go_router natively for these nested routes,
// I will keep Navigator.push for compatibility or use go_router if context.go works.
// Given go_router wasn't consistently used deeply, I'll stick to MaterialPageRoute for now
// to avoid breaking until go_router config is fully addressed, BUT I will consolidate duplicate screens.

class QuickActionsGrid extends StatelessWidget {
  final bool isSimpleMode;

  const QuickActionsGrid({
    super.key,
    required this.isSimpleMode,
  });

  @override
  Widget build(BuildContext context) {
    // Consolidated actions! Track Habits, Photo Calorie, Daily Quests used to all go to HabitTrackerScreen
    final actions = [
      {
        'title': 'XP Rankings',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFFFD700),
        'screen': const gamification.LeaderboardScreen(),
      },
      {
        'title': 'Edit Profile',
        'icon': Icons.person_outline,
        'color': const Color(0xFF6C63FF),
        'screen': const EditProfileScreen(),
      },
      {
        'title': 'Quests Tracker',
        'icon': Icons.track_changes,
        'color': const Color(0xFF00BFA5),
        'screen': const HabitTrackerScreen(),
      },
      {
        'title': 'AI Food',
        'icon': Icons.camera_alt,
        'color': const Color(0xFF2979FF),
        'screen': const EnhancedFoodDetectionScreen(),
      },
      {
        'title': 'Nutrition',
        'icon': Icons.restaurant_menu,
        'color': const Color(0xFF00C853),
        'screen': const NutritionDashboardScreen(),
      },
      {
        'title': 'Recipes',
        'icon': Icons.menu_book,
        'color': const Color(0xFFFF6D00),
        'screen': const RecipesScreen(),
      },
      {
        'title': 'Meal Plan',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF00BCD4),
        'screen': const MealPlanningScreen(),
      },
      {
        'title': 'Notifications',
        'icon': Icons.notifications,
        'color': const Color(0xFF9C27B0),
        'screen': const NotificationSettingsScreen(),
      },
      {
        'title': 'Life Metrics',
        'icon': Icons.health_and_safety,
        'color': Colors.redAccent,
        'screen': const DailyMetricsScreen(),
      },
      {
        'title': 'Statistics',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF2979FF),
        'screen': const StatisticsScreen(),
      },
      {
        'title': 'Lock Screen',
        'icon': Icons.lock,
        'color': const Color(0xFFFF5252),
        'screen': const AppLimitsScreen(),
      },
      {
        'title': 'Find Coach',
        'icon': Icons.sports,
        'color': const Color(0xFF1565C0),
        'screen': const BrowseCoachesScreen(),
      },
      {
        'title': 'Go Premium',
        'icon': Icons.workspace_premium,
        'color': const Color(0xFFFF8F00),
        'screen': const PaywallScreen(),
      },
    if (!isSimpleMode) ...[
        {
          'title': 'Community',
          'icon': Icons.group,
          'color': const Color(0xFF00BFA5),
          'screen': const CommunityFeedScreen(),
        },
        {
          'title': 'Hire Pros',
          'icon': Icons.medical_services,
          'color': const Color(0xFF9C27B0), // Purple
          'screen': const ProfessionalsDirectoryScreen(),
        },
        {
          'title': 'AI Chatbot',
          'icon': Icons.smart_toy,
          'color': const Color(0xFF2979FF),
          'screen': const AIChatbotScreen(),
        },
      ],
      {
        'title': 'BMI Calc',
        'icon': Icons.calculate,
        'color': const Color(0xFF00BFA5),
        'screen': const BMICalculatorScreen(),
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today,
        'color': const Color(0xFF2979FF),
        'screen': const ProgressCalendarScreen(),
      },
    ];

    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final color = action['color'] as Color;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: () {
            final screenWidget = action['screen'] as Widget?;
            if (screenWidget != null) {
               Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => screenWidget),
              );
            }
          },
          child: Row(
            children: [
                Icon(
                  action['icon'] as IconData,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
            ],
          ),
        );
      },
    ),
  );
  }
}
