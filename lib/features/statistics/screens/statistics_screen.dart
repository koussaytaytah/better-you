import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final logsAsync = ref.watch(dailyLogsProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No data yet. Start tracking to see your progress!',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            );
          }

          // Sort logs by date ascending for the chart
          final sortedLogs = List<DailyLog>.from(logs)
            ..sort((a, b) => a.date.compareTo(b.date));
          // Take last 7 days
          final recentLogs = sortedLogs.length > 7
              ? sortedLogs.sublist(sortedLogs.length - 7)
              : sortedLogs;

          final habits = user.habits ?? {};
          final targetCalories = habits['targetCalories']?.toDouble() ?? 2000.0;
          final targetCigarettes = (habits['smoking']?['dailyCigarettes'] ?? 0)
              .toDouble();
          final targetAlcohol =
              (habits['alcohol']?['weeklyBeers'] ?? 0).toDouble() / 7;
          final targetExercise =
              (habits['weeklySessions'] ?? 0).toDouble() * 45 / 7;
          final targetWater = 8.0; // Standard 8 glasses
          final targetSleep = 8.0; // Standard 8 hours

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.displaySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your weekly health journey',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),
                _buildComparisonSummary(recentLogs, habits, context),
                const SizedBox(height: 32),
                _buildChartContainer(
                  _buildQuestCompletionChart(recentLogs, context),
                  'Habit Completion Rate (%)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildLineChart(
                    recentLogs,
                    (log) => (log.calories ?? 0).toDouble(),
                    AppColors.accent,
                    targetCalories,
                    context,
                  ),
                  'Daily Calorie Intake (kcal)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildLineChart(
                    recentLogs,
                    (log) => (log.waterGlasses ?? 0).toDouble(),
                    Colors.blue,
                    targetWater,
                    context,
                  ),
                  'Water Intake (glasses)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildLineChart(
                    recentLogs,
                    (log) => (log.sleepHours ?? 0.0).toDouble(),
                    Colors.indigo,
                    targetSleep,
                    context,
                  ),
                  'Sleep Duration (hours)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildBarChart(
                    recentLogs,
                    (log) => (log.cigarettes ?? 0).toDouble(),
                    AppColors.danger,
                    targetCigarettes,
                    context,
                  ),
                  'Cigarettes Smoked (count)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildLineChart(
                    recentLogs,
                    (log) => (log.steps ?? 0).toDouble(),
                    Colors.orange,
                    10000.0, // Default 10k steps target
                    context,
                  ),
                  'Daily Steps (steps)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildLineChart(
                    recentLogs,
                    (log) => (log.exerciseMinutes ?? 0).toDouble(),
                    AppColors.success,
                    targetExercise,
                    context,
                  ),
                  'Exercise Time (minutes)',
                  context,
                ),
                const SizedBox(height: 24),
                _buildChartContainer(
                  _buildBarChart(
                    recentLogs,
                    (log) => (log.alcohol ?? 0.0).toDouble(),
                    AppColors.secondary,
                    targetAlcohol,
                    context,
                  ),
                  'Alcohol Units',
                  context,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChartContainer(
    Widget chart,
    String description,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<DailyLog> logs,
    double Function(DailyLog) getValue,
    Color color,
    double targetValue,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LineChart(
      LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetValue,
              color: Theme.of(
                context,
              ).textTheme.bodySmall!.color!.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => 'Target',
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(
                context,
              ).textTheme.bodySmall!.color!.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: _buildTitlesData(logs, context),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: logs.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), getValue(e.value));
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
                    strokeWidth: 2,
                    strokeColor: color,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    List<DailyLog> logs,
    double Function(DailyLog) getValue,
    Color color,
    double targetValue,
    BuildContext context,
  ) {
    return BarChart(
      BarChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetValue,
              color: Theme.of(
                context,
              ).textTheme.bodySmall!.color!.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => 'Limit',
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(
                context,
              ).textTheme.bodySmall!.color!.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: _buildTitlesData(logs, context),
        borderData: FlBorderData(show: false),
        barGroups: logs
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: getValue(e.value),
                    color: color,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildComparisonSummary(
    List<DailyLog> logs,
    Map<String, dynamic> habits,
    BuildContext context,
  ) {
    final double avgCalories = logs.isEmpty
        ? 0.0
        : logs.fold(0.0, (sum, e) => sum + (e.calories ?? 0)) / logs.length;
    final targetCalories = habits['targetCalories']?.toDouble() ?? 2000.0;

    final avgCigarettes = logs.isEmpty
        ? 0.0
        : logs.fold(0.0, (sum, e) => sum + (e.cigarettes ?? 0)) / logs.length;
    final limitCigarettes = (habits['smoking']?['dailyCigarettes'] ?? 0)
        .toDouble();

    final avgWater = logs.isEmpty
        ? 0.0
        : logs.fold(0.0, (sum, e) => sum + (e.waterGlasses ?? 0)) / logs.length;
    final targetWater = 8.0;

    final avgSleep = logs.isEmpty
        ? 0.0
        : logs.fold(0.0, (sum, e) => sum + (e.sleepHours ?? 0.0)) / logs.length;
    final targetSleep = 8.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Averages',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(
                'Calories',
                '${avgCalories.toInt()}',
                'Target: ${targetCalories.toInt()}',
                avgCalories <= targetCalories,
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                'Smoking',
                '${avgCigarettes.toInt()}',
                'Limit: ${limitCigarettes.toInt()}',
                avgCigarettes <= limitCigarettes,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryItem(
                'Water',
                avgWater.toStringAsFixed(1),
                'Goal: $targetWater',
                avgWater >= targetWater,
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                'Sleep',
                '${avgSleep.toStringAsFixed(1)}h',
                'Goal: ${targetSleep.toInt()}h',
                avgSleep >= targetSleep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    String sub,
    bool isPositive,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.check_circle : Icons.warning,
                  size: 12,
                  color: isPositive ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  sub,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCompletionChart(List<DailyLog> logs, BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(
              context,
            ).textTheme.bodySmall!.color!.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: _buildTitlesData(logs, context),
        borderData: FlBorderData(show: false),
        barGroups: logs.asMap().entries.map((e) {
          final quests = e.value.quests ?? {};
          final completed = quests.values.where((v) => v == true).length;
          final total = quests.length;
          final rate = total == 0 ? 0.0 : (completed / total) * 100;

          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: rate,
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        maxY: 100,
      ),
    );
  }

  FlTitlesData _buildTitlesData(List<DailyLog> logs, BuildContext context) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < logs.length) {
              return SideTitleWidget(
                meta: meta,
                space: 10,
                child: Text(
                  DateFormat('dd/MM').format(logs[index].date),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 35,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              meta: meta,
              space: 10,
              child: Text(
                value.toInt().toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
