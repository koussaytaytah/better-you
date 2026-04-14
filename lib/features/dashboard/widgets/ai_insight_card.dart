import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class AIInsightCard extends ConsumerWidget {
  const AIInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiInsightAsync = ref.watch(dailyAIInsightProvider);

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Wellness Coach',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                onPressed: () => ref.invalidate(dailyAIInsightProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          aiInsightAsync.when(
            data: (insight) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTag('Personalized Advice'),
                    const SizedBox(width: 8),
                    _buildTag('Data-Driven'),
                  ],
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Text(
              'Failed to load insights. Start logging to get AI tips!',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1);
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
