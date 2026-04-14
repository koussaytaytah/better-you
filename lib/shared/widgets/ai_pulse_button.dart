import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_theme.dart';

class AIPulseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isListening;
  final double size;

  const AIPulseButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pulses
          if (isListening)
            ...[1, 2, 3].map((i) => Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  duration: 1500.ms,
                  delay: (400 * i).ms,
                  begin: const Offset(1, 1),
                  end: const Offset(2.5, 2.5),
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 1500.ms)),

          // The main glowing orb background
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
                child: Container(
                    decoration: const BoxDecoration(
                    gradient: SweepGradient(
                        colors: [
                            AppColors.primary,
                            AppColors.secondary,
                            AppColors.accent,
                            AppColors.primary,
                        ],
                    ),
                    ),
                ).animate(onPlay: (c) => c.repeat())
                .custom(
                    duration: 4.seconds,
                    builder: (context, value, child) {
                        return Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: child,
                        );
                    },
                ),
            ),
          ),
          
          // The center icon/waveform (steady)
          Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Center(
                child: isListening
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...[0.4, 0.8, 1.0, 0.8, 0.4].map((h) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 3,
                          height: 20 * h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                          begin: 0.5,
                          end: 1.5,
                          duration: 400.ms,
                          curve: Curves.easeInOut,
                        )),
                      ],
                    )
                  : const Icon(
                      Icons.blur_on,
                      color: Colors.white,
                      size: 32,
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scaleXY(end: 1.1, duration: 2.seconds),
              ),
          )
        ],
      )
      .animate(target: isListening ? 1 : 0)
      .scale(end: const Offset(1.15, 1.15), duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}
