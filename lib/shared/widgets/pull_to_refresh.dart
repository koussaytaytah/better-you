import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

/// Custom pull-to-refresh indicator with smooth animations
class ModernRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const ModernRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? const Color(0xFF00A86B),
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1A1A1A) : Colors.white),
      strokeWidth: 3,
      displacement: 60,
      edgeOffset: 20,
      child: child,
    );
  }
}

/// Animated pull-to-refresh header with custom design
class AnimatedRefreshHeader extends StatefulWidget {
  final AnimationController controller;
  final double pullDistance;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const AnimatedRefreshHeader({
    super.key,
    required this.controller,
    required this.pullDistance,
    required this.refreshTriggerPullDistance,
    required this.refreshIndicatorExtent,
  });

  @override
  State<AnimatedRefreshHeader> createState() => _AnimatedRefreshHeaderState();
}

class _AnimatedRefreshHeaderState extends State<AnimatedRefreshHeader> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final percentageComplete =
        (widget.pullDistance / widget.refreshTriggerPullDistance).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Container(
          height: widget.pullDistance,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              AnimatedContainer(
                duration: ModernTheme.microAnimationFast,
                width: 50 + (percentageComplete * 10),
                height: 50 + (percentageComplete * 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1 * percentageComplete)
                      : const Color(0xFF00A86B)
                          .withValues(alpha: 0.1 * percentageComplete),
                  shape: BoxShape.circle,
                ),
              ),
              // Rotating icon
              Transform.rotate(
                angle: widget.controller.isAnimating
                    ? widget.controller.value * 2 * 3.14159
                    : percentageComplete * 3.14159,
                child: Icon(
                  widget.pullDistance >= widget.refreshTriggerPullDistance
                      ? Icons.refresh
                      : Icons.arrow_downward,
                  color: const Color(0xFF00A86B),
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom scrollable wrapper with modern pull-to-refresh
class ModernScrollView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const ModernScrollView({
    super.key,
    required this.children,
    this.onRefresh,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: physics ?? ModernTheme.smoothScroll,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList(
            delegate: SliverChildListDelegate(children),
          ),
        ),
      ],
    );

    if (onRefresh != null) {
      return ModernRefreshIndicator(
        onRefresh: onRefresh!,
        child: scrollView,
      );
    }

    return scrollView;
  }
}

/// Animated list with staggered item animations
class AnimatedListView extends StatefulWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final Future<void> Function()? onRefresh;

  const AnimatedListView({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.physics,
    this.reverse = false,
    this.onRefresh,
  });

  @override
  State<AnimatedListView> createState() => _AnimatedListViewState();
}

class _AnimatedListViewState extends State<AnimatedListView> {
  @override
  Widget build(BuildContext context) {
    final listView = ListView.builder(
      padding: widget.padding,
      physics: widget.physics ?? ModernTheme.smoothScroll,
      reverse: widget.reverse,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: widget.children[index],
        );
      },
    );

    if (widget.onRefresh != null) {
      return ModernRefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}

/// Single animated list item with slide + fade
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernTheme.microAnimationNormal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Stagger animation based on index
    Future.delayed(
      Duration(milliseconds: widget.index * 50),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Grid view with animated items
class AnimatedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;

  const AnimatedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding = const EdgeInsets.all(16),
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final gridView = GridView.builder(
      padding: padding,
      physics: ModernTheme.smoothScroll,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: children[index],
        );
      },
    );

    if (onRefresh != null) {
      return ModernRefreshIndicator(
        onRefresh: onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }
}

/// Loading shimmer for pull-to-refresh
class RefreshShimmer extends StatelessWidget {
  final bool isRefreshing;

  const RefreshShimmer({
    super.key,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: ModernTheme.microAnimationFast,
      opacity: isRefreshing ? 1.0 : 0.0,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
        ),
      ),
    );
  }
}

/// Scroll behavior for smooth scrolling across platforms
class SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return ModernTheme.smoothScroll;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
