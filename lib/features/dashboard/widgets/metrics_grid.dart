import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/models/daily_log_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';

// Removed invalid settings import
// Wait, simpleModeProvider is in auth_provider probably.
// Let me verify if simpleModeProvider is needed. Yes, it's used to hide metrics.

class MetricsGrid extends ConsumerWidget {
  final DailyLog log;
  final bool isSimpleMode;

  const MetricsGrid({
    super.key,
    required this.log,
    required this.isSimpleMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildMetricCard(
          context,
          ref,
          '${log.calories ?? 0}',
          'Calories',
          Icons.restaurant,
          const Color(0xFFFFF3E0),
          const Color(0xFFFF9800),
          'calories',
          false,
          (log.calories ?? 0) / 2500.0,
        ),
        _buildMetricCard(
          context,
          ref,
          '${log.exerciseMinutes ?? 0}m',
          'Exercise',
          Icons.fitness_center,
          const Color(0xFFE8F5E9),
          const Color(0xFF4CAF50),
          'exerciseMinutes',
          false,
          (log.exerciseMinutes ?? 0) / 60.0,
        ),
        _buildMetricCard(
          context,
          ref,
          '${log.waterGlasses ?? 0}',
          'Water',
          Icons.water_drop,
          const Color(0xFFE3F2FD),
          const Color(0xFF2196F3),
          'waterGlasses',
          false,
          (log.waterGlasses ?? 0) / 8.0,
        ),
        _buildMetricCard(
          context,
          ref,
          '${log.sleepHours?.toStringAsFixed(1) ?? "0"}h',
          'Sleep',
          Icons.bedtime,
          const Color(0xFFEDE7F6),
          const Color(0xFF673AB7),
          'sleepHours',
          true,
          (log.sleepHours ?? 0) / 8.0,
        ),
        if (!isSimpleMode) ...[
          _buildMetricCard(
            context,
            ref,
            '${log.cigarettes ?? 0}',
            'Cigarettes',
            Icons.smoke_free,
            const Color(0xFFFFEBEE),
            const Color(0xFFE91E63),
            'cigarettes',
            false,
            (log.cigarettes ?? 0) / 10.0,
          ),
          _buildMetricCard(
            context,
            ref,
            '${log.alcohol?.toStringAsFixed(1) ?? "0.0"}',
            'Alcohol',
            Icons.local_bar,
            const Color(0xFFF3E5F5),
            const Color(0xFF9C27B0),
            'alcohol',
            true,
            (log.alcohol ?? 0) / 5.0,
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    WidgetRef ref,
    String value,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
    String field,
    bool isDouble,
    double progress,
  ) {
    return GestureDetector(
      onTap: () => _showMetricUpdateDialog(context, ref, log, label, field, isDouble),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    DailyLog log,
    String label,
    String field,
    bool isDouble,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
          decoration: InputDecoration(
            hintText: 'Enter new value',
            suffixText: label == 'Exercise' ? 'min' : '',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = isDouble
                  ? double.tryParse(controller.text)
                  : int.tryParse(controller.text);
              if (value != null) {
                final user = ref.read(currentUserAsyncProvider).value;
                if (user != null) {
                  await ref
                      .read(dailyLogRepositoryProvider)
                      .updateDailyLog(user.uid, DateTime.now(), {field: value});
                  ref.invalidate(todayLogProvider);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
