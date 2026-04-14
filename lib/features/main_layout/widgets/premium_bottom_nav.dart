import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import 'dynamic_ai_orb.dart';

class PremiumBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PremiumBottomNav({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Frosted Glass Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.6) 
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home', currentIndex, context),
                    _buildNavItem(1, Icons.people_rounded, 'Social', currentIndex, context),
                    const SizedBox(width: 60), // Space for AI Orb
                    _buildNavItem(2, Icons.track_changes_rounded, 'Quests', currentIndex, context),
                    _buildNavItem(3, Icons.person_rounded, 'Profile', currentIndex, context),
                  ],
                ),
              ),
            ),
          ),
          // Dominant Center AI Orb
          const Positioned(
            bottom: 12,
            child: DynamicAIOrb(),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default inactive colors
    final baseColor = isDark ? Colors.white54 : Colors.grey[400];
    // Active glowing colors
    final activeColor = AppColors.primary;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 26 : 24,
              color: isSelected ? activeColor : baseColor,
            ).animate(target: isSelected ? 1 : 0)
             .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate().scale(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}
