import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

/// Animated button with scale, ripple, and haptic feedback
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final Duration animationDuration;
  final double scaleDownFactor;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.borderRadius = 16,
    this.shadows,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleDownFactor = 0.95,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = widget.backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF00A86B));
    final fgColor = widget.foregroundColor ??
        (isDark ? Colors.white : Colors.white);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.shadows ??
                    (isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF00A86B).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Gradient button with animation
class GradientButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF00A86B), Color(0xFF00D68A)],
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    this.borderRadius = 18,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.microAnimationFast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.05),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: -5,
                        ),
                      ],
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Icon button with ripple and scale animation
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.microAnimationFast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = widget.backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white);
    final iconColor = widget.color ??
        (isDark ? Colors.white : const Color(0xFF0F172A));

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_controller.value * 0.15),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Icon(
                widget.icon,
                color: iconColor,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating action button with pulse animation
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final String? tooltip;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: ModernTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
