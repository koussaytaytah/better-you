import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../dashboard/screens/ai_chatbot_screen.dart';

class DynamicAIOrb extends ConsumerStatefulWidget {
  const DynamicAIOrb({super.key});

  @override
  ConsumerState<DynamicAIOrb> createState() => _DynamicAIOrbState();
}

class _DynamicAIOrbState extends ConsumerState<DynamicAIOrb> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.5),
          builder: (_) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: const AIChatbotScreen(),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                if (isDark)
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Rotating Sweep Gradient
                Positioned.fill(
                  child: Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: isDark 
                            ? [
                                AppColors.primary,
                                Colors.blueAccent,
                                Colors.deepPurpleAccent,
                                AppColors.primary,
                              ]
                            : [
                                AppColors.primary,
                                AppColors.secondary,
                                Colors.tealAccent,
                                AppColors.primary,
                              ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Inner Dark/Light circle for contrast
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    ),
                  ),
                ),
                // Core Icon
                Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: isDark ? Colors.white : AppColors.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 2.seconds)
           .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.2));
        },
      ),
    );
  }
}
