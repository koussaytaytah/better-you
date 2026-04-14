import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../habits/screens/habit_tracker_screen.dart';
import '../../habits/screens/ai_food_detection_screen.dart';
import '../../habits/screens/daily_metrics_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../community/screens/community_feed_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../screens/bmi_calculator_screen.dart';
import '../screens/progress_calendar_screen.dart';

import 'package:go_router/go_router.dart';

import '../../community/screens/leaderboard_screen.dart';
import '../../community/screens/professionals_directory_screen.dart';
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
        'title': 'Leaderboard',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFFFD700),
        'screen': const LeaderboardScreen(),
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
        'screen': const AIFoodDetectionScreen(),
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2, // Made it slightly wider
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final color = action['color'] as Color;
        return GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onTap: () {
            final screenWidget = action['screen'] as Widget?;
            if (screenWidget != null) {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screenWidget),
              );
            }
          },
          child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
