import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 52, height: 52, radius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: MediaQuery.of(context).size.width * 0.5, height: 14),
                const SizedBox(height: 8),
                ShimmerBox(width: MediaQuery.of(context).size.width * 0.7, height: 12),
                const SizedBox(height: 6),
                ShimmerBox(width: MediaQuery.of(context).size.width * 0.4, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double? height;
  const ShimmerCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShimmerBox(
        width: double.infinity,
        height: height ?? 120,
        radius: 20,
      ),
    );
  }
}

class ShimmerChatMessage extends StatelessWidget {
  final bool isMe;
  const ShimmerChatMessage({super.key, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const ShimmerBox(width: 32, height: 32, radius: 16),
            const SizedBox(width: 8),
          ],
          ShimmerBox(
            width: MediaQuery.of(context).size.width * (isMe ? 0.45 : 0.55),
            height: 40,
            radius: 16,
          ),
        ],
      ),
    );
  }
}

class ShimmerDashboardScreen extends StatelessWidget {
  const ShimmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        ShimmerBox(width: double.infinity, height: 180, radius: 24),
        SizedBox(height: 20),
        ShimmerBox(width: 160, height: 22, radius: 8),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 100, radius: 20),
        SizedBox(height: 20),
        ShimmerBox(width: 140, height: 22, radius: 8),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 200, radius: 20),
        SizedBox(height: 20),
        ShimmerBox(width: double.infinity, height: 140, radius: 20),
      ],
    );
  }
}

class ShimmerChatList extends StatelessWidget {
  const ShimmerChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (_, i) => ShimmerListItem(),
    );
  }
}
