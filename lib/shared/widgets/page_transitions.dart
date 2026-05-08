import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

/// Smooth page transitions for the app
class PageTransitions {
  // Slide from right (default push)
  static Route<T> slideRight<T>({
    required Widget page,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: ModernTheme.pageTransitionDuration,
      reverseTransitionDuration: ModernTheme.pageTransitionDuration,
    );
  }

  // Slide from bottom (modal style)
  static Route<T> slideUp<T>({
    required Widget page,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: ModernTheme.pageTransitionDuration,
      reverseTransitionDuration: ModernTheme.pageTransitionDuration,
    );
  }

  // Fade transition
  static Route<T> fade<T>({
    required Widget page,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: ModernTheme.pageTransitionDuration,
      reverseTransitionDuration: ModernTheme.pageTransitionDuration,
    );
  }

  // Scale + fade (for dialogs/sheets)
  static Route<T> scaleFade<T>({
    required Widget page,
    String? routeName,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeOutCubic;
        var curveTween = CurveTween(curve: curve);

        var scaleTween = Tween(begin: 0.9, end: 1.0).chain(curveTween);
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(curveTween);

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: ModernTheme.pageTransitionDuration,
      reverseTransitionDuration: ModernTheme.pageTransitionDuration,
    );
  }

  // Shared element transition (hero-like)
  static Route<T> sharedAxis<T>({
    required Widget page,
    String? routeName,
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
      transitionDuration: ModernTheme.pageTransitionDuration,
      reverseTransitionDuration: ModernTheme.pageTransitionDuration,
    );
  }
}

/// Animated route wrapper for smooth transitions
class AnimatedRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteType type;

  AnimatedRoute({
    required this.page,
    this.type = RouteType.slideRight,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: ModernTheme.pageTransitionDuration,
          reverseTransitionDuration: ModernTheme.pageTransitionDuration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case RouteType.slideRight:
        return _buildSlideRight(animation, child);
      case RouteType.slideUp:
        return _buildSlideUp(animation, child);
      case RouteType.fade:
        return _buildFade(animation, child);
      case RouteType.scale:
        return _buildScale(animation, child);
      case RouteType.sharedAxis:
        return _buildSharedAxis(animation, secondaryAnimation, child);
    }
  }

  Widget _buildSlideRight(Animation<double> animation, Widget child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  Widget _buildSlideUp(Animation<double> animation, Widget child) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  Widget _buildFade(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  Widget _buildScale(Animation<double> animation, Widget child) {
    var curve = Curves.easeOutCubic;
    var tween = Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: curve));
    return ScaleTransition(
      scale: animation.drive(tween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  Widget _buildSharedAxis(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.scaled,
      child: child,
    );
  }
}

enum RouteType {
  slideRight,
  slideUp,
  fade,
  scale,
  sharedAxis,
}

/// Shared axis transition from Material Design
class SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _buildAnimation(),
          child: child,
        );
      },
      child: child,
    );
  }

  Animation<double> _buildAnimation() {
    const curve = Curves.easeOutCubic;
    return Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)).animate(animation);
  }
}

enum SharedAxisTransitionType {
  scaled,
  horizontal,
  vertical,
}

/// Extension for easy navigation with animations
extension NavigationExtensions on BuildContext {
  Future<T?> pushAnimated<T>(
    Widget page, {
    RouteType type = RouteType.slideRight,
  }) {
    return Navigator.of(this).push<T>(
      AnimatedRoute<T>(
        page: page,
        type: type,
      ),
    );
  }

  Future<T?> pushReplacementAnimated<T>(
    Widget page, {
    RouteType type = RouteType.fade,
  }) {
    return Navigator.of(this).pushReplacement(
      AnimatedRoute<T>(
        page: page,
        type: type,
      ),
    );
  }

  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideUp(page: page),
    );
  }

  Future<T?> pushScaleFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      PageTransitions.scaleFade(page: page),
    );
  }
}
