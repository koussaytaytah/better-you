import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

/// Modern floating bottom navigation bar with glassmorphism effect
class FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final List<NavBarItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final double height;
  final double iconSize;
  final double borderRadius;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.height = 72,
    this.iconSize = 24,
    this.borderRadius = 28,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.microAnimationNormal,
      vsync: this,
    );
    _animations = List.generate(
      widget.items.length,
      (index) => _createAnimation(index),
    );
    _controller.forward();
  }

  Animation<double> _createAnimation(int index) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.1,
          0.5 + index * 0.1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      HapticFeedback.lightImpact();
    }
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
        (isDark
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: isDark ? ModernTheme.cardShadowDark : ModernTheme.cardShadowLight,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final item = widget.items[index];
    final isSelected = widget.currentIndex == index;
    final animation = _animations[index];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFF00A86B).withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: ModernTheme.microAnimationFast,
                  curve: Curves.easeOutCubic,
                  child: Transform.scale(
                    scale: isSelected ? 1.1 : 1.0,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: widget.iconSize,
                      color: isSelected
                          ? const Color(0xFF00A86B)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  duration: ModernTheme.microAnimationFast,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00A86B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Navigation bar item configuration
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? badge;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Curved floating navigation bar with notch for FAB
class CurvedFloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final List<NavBarItem> items;
  final ValueChanged<int> onTap;
  final Widget? centerButton;

  const CurvedFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.centerButton,
  });

  @override
  State<CurvedFloatingNavBar> createState() => _CurvedFloatingNavBarState();
}

class _CurvedFloatingNavBarState extends State<CurvedFloatingNavBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: isDark ? ModernTheme.cardShadowDark : ModernTheme.cardShadowLight,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...widget.items.take(2).map((item) => _buildItem(item, widget.items.indexOf(item), isDark)),
              if (widget.centerButton != null) ...[
                const SizedBox(width: 60),
                widget.centerButton!,
                const SizedBox(width: 60),
              ],
              ...widget.items.skip(widget.centerButton != null ? 2 : 0).map(
                (item) => _buildItem(item, widget.items.indexOf(item), isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(NavBarItem item, int index, bool isDark) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap(index);
      },
      child: AnimatedContainer(
        duration: ModernTheme.microAnimationFast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00A86B).withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? item.activeIcon : item.icon,
          size: 24,
          color: isSelected
              ? const Color(0xFF00A86B)
              : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
