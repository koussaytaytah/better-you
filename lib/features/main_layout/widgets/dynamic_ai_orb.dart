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

class _DynamicAIOrbState extends ConsumerState<DynamicAIOrb> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _openChatbot();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _openChatbot() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.03, 1.03), duration: 2.seconds, curve: Curves.easeInOut),
      ),
    );
  }
}
