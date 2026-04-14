import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/premium_bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating transparent navbar
      body: navigationShell,
      bottomNavigationBar: PremiumBottomNav(navigationShell: navigationShell),
    );
  }
}
