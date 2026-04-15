import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/models/daily_log_model.dart';
import '../../../../shared/providers/data_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/glass_card.dart';

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
    return RepaintBoundary(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildMetricCard(
            context,
            ref,
            '${log.calories ?? 0}',
            'Calories',
            Icons.local_fire_department_rounded,
            const Color(0xFFFF5252),
            'calories',
            false,
            (log.calories ?? 0) / 2500.0,
          ),
          _buildMetricCard(
            context,
            ref,
            '${log.exerciseMinutes ?? 0}m',
            'Exercise',
            Icons.bolt_rounded,
            const Color(0xFF00E676),
            'exerciseMinutes',
            false,
            (log.exerciseMinutes ?? 0) / 60.0,
          ),
          _buildMetricCard(
            context,
            ref,
            '${log.waterGlasses ?? 0}',
            'Water',
            Icons.water_drop_rounded,
            const Color(0xFF448AFF),
            'waterGlasses',
            false,
            (log.waterGlasses ?? 0) / 8.0,
          ),
          _buildMetricCard(
            context,
            ref,
            '${log.sleepHours?.toStringAsFixed(1) ?? "0"}h',
            'Sleep',
            Icons.nights_stay_rounded,
            const Color(0xFF7C4DFF),
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
              Icons.smoke_free_rounded,
              const Color(0xFFFFAB40),
              'cigarettes',
              false,
              (log.cigarettes ?? 0) / 10.0,
            ),
            _buildMetricCard(
              context,
              ref,
              '${log.alcohol?.toStringAsFixed(1) ?? "0.0"}',
              'Alcohol',
              Icons.wine_bar_rounded,
              const Color(0xFFFF4081),
              'alcohol',
              true,
              (log.alcohol ?? 0) / 5.0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    WidgetRef ref,
    String value,
    String label,
    IconData icon,
    Color color,
    String field,
    bool isDouble,
    double progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: () => _showMetricUpdateDialog(context, ref, log, label, field, isDouble),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '${(progress * 100).clamp(0, 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
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
