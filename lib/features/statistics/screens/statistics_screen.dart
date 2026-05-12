import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _periodDays = 7; // 7, 30, 90

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final logsAsync = ref.watch(dailyLogsProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: logsAsync.when(
        data: (allLogs) {
          final sorted = List<DailyLog>.from(allLogs)..sort((a, b) => a.date.compareTo(b.date));
          final logs = sorted.length > _periodDays ? sorted.sublist(sorted.length - _periodDays) : sorted;
          final habits = user.habits ?? {};

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildPeriodToggle().animate().fadeIn().slideY()),
              if (logs.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else ...[
                SliverToBoxAdapter(child: _buildHealthScoreCard(logs).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildStreakRow(logs).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildAveragesCard(logs, habits).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildSectionTitle('Activity').animate().fadeIn(delay: 200.ms).slideX(begin: -0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Steps', subtitle: 'Daily step count', icon: Icons.directions_walk, color: Colors.orange,
                  chart: _buildLineChart(logs, (l) => (l.steps ?? 0).toDouble(), Colors.orange, 10000),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Exercise', subtitle: 'Minutes active', icon: Icons.fitness_center, color: AppColors.success,
                  chart: _buildBarChart(logs, (l) => (l.exerciseMinutes ?? 0).toDouble(), AppColors.success),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildSectionTitle('Nutrition').animate().fadeIn(delay: 350.ms).slideX(begin: -0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Calories', subtitle: 'kcal per day', icon: Icons.local_fire_department, color: AppColors.accent,
                  chart: _buildLineChart(logs, (l) => (l.calories ?? 0).toDouble(), AppColors.accent,
                      (habits['targetCalories'] ?? 2000).toDouble()),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildMacroPieCard(logs).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Water', subtitle: 'Glasses per day', icon: Icons.water_drop, color: const Color(0xFF2563EB),
                  chart: _buildLineChart(logs, (l) => (l.waterGlasses ?? 0).toDouble(), const Color(0xFF2563EB), 8),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildSectionTitle('Wellness').animate().fadeIn(delay: 550.ms).slideX(begin: -0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Sleep', subtitle: 'Hours per night', icon: Icons.bedtime, color: Colors.indigo,
                  chart: _buildLineChart(logs, (l) => (l.sleepHours ?? 0).toDouble(), Colors.indigo, 8),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildMoodChart(logs).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Habit Completion', subtitle: '% of daily quests done', icon: Icons.task_alt, color: AppColors.primary,
                  chart: _buildBarChart(logs, (l) {
                    final q = l.quests ?? {};
                    if (q.isEmpty) return 0.0;
                    return (q.values.where((v) => v).length / q.length * 100);
                  }, AppColors.primary, maxY: 100),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildSectionTitle('Health Risks').animate().fadeIn(delay: 750.ms).slideX(begin: -0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Cigarettes', subtitle: 'Smoked per day', icon: Icons.smoking_rooms, color: AppColors.danger,
                  chart: _buildBarChart(logs, (l) => (l.cigarettes ?? 0).toDouble(), AppColors.danger),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1)),
                SliverToBoxAdapter(child: _buildChartCard(
                  title: 'Alcohol', subtitle: 'Units per day', icon: Icons.local_bar, color: AppColors.warning,
                  chart: _buildBarChart(logs, (l) => (l.alcohol ?? 0).toDouble(), AppColors.warning),
                ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.1)),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Progress', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                      Text('Statistics', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            for (final days in [7, 30, 90])
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _periodDays = days);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _periodDays == days ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        days == 7 ? '7 Days' : days == 30 ? '30 Days' : '3 Months',
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _periodDays == days ? Colors.white : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(List<DailyLog> logs) {
    final avgScore = logs.isEmpty ? 0 : (logs.fold(0, (s, l) => s + l.calculateHealthScore()) / logs.length).round();
    final color = avgScore >= 70 ? AppColors.success : avgScore >= 40 ? AppColors.warning : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80, height: 80,
              child: CustomPaint(painter: _RingPainter(value: avgScore / 100.0), child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$avgScore', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('/100', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                ]),
              )),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Health Score', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  avgScore >= 70 ? 'Excellent! Keep it up 🔥' : avgScore >= 40 ? 'Good progress, stay consistent 💪' : 'Needs improvement — you got this!',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 8),
                Text('Based on ${logs.length} day${logs.length == 1 ? '' : 's'} of data',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
              ]),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildStreakRow(List<DailyLog> logs) {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < logs.length; i++) {
      final expected = today.subtract(Duration(days: i));
      final match = logs.reversed.skip(i).firstOrNull;
      if (match == null) break;
      final diff = expected.difference(match.date).abs().inDays;
      if (diff <= 1) {
        streak++;
      } else {
        break;
      }
    }

    final avgSteps = logs.isEmpty ? 0 : (logs.fold(0, (s, l) => s + (l.steps ?? 0)) / logs.length).round();
    final avgSleep = logs.isEmpty ? 0.0 : logs.fold(0.0, (s, l) => s + (l.sleepHours ?? 0)) / logs.length;
    final avgWater = logs.isEmpty ? 0.0 : logs.fold(0.0, (s, l) => s + (l.waterGlasses ?? 0)) / logs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _MiniMetricCard(label: 'Streak', value: '${streak}d', icon: Icons.local_fire_department, color: Colors.deepOrange),
          const SizedBox(width: 10),
          _MiniMetricCard(label: 'Avg Steps', value: _fmt(avgSteps.toDouble()), icon: Icons.directions_walk, color: Colors.orange),
          const SizedBox(width: 10),
          _MiniMetricCard(label: 'Avg Sleep', value: '${avgSleep.toStringAsFixed(1)}h', icon: Icons.bedtime, color: Colors.indigo),
          const SizedBox(width: 10),
          _MiniMetricCard(label: 'Avg Water', value: '${avgWater.toStringAsFixed(1)}gl', icon: Icons.water_drop, color: const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildAveragesCard(List<DailyLog> logs, Map<String, dynamic> habits) {
    final avgCal = logs.isEmpty ? 0.0 : logs.fold(0.0, (s, l) => s + (l.calories ?? 0)) / logs.length;
    final targetCal = (habits['targetCalories'] ?? 2000).toDouble();
    final avgSmoke = logs.isEmpty ? 0.0 : logs.fold(0.0, (s, l) => s + (l.cigarettes ?? 0)) / logs.length;
    final limitSmoke = (habits['smoking']?['dailyCigarettes'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Averages', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 14),
            Row(children: [
              _AvgItem(label: 'Calories', value: '${avgCal.toInt()}', sub: 'Target ${targetCal.toInt()}', ok: avgCal <= targetCal),
              const SizedBox(width: 10),
              _AvgItem(label: 'Smoking', value: avgSmoke.toStringAsFixed(1), sub: 'Limit ${limitSmoke.toInt()}', ok: avgSmoke <= limitSmoke),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPieCard(List<DailyLog> logs) {
    final totalP = logs.fold(0.0, (s, l) => s + (l.protein ?? 0));
    final totalC = logs.fold(0.0, (s, l) => s + (l.carbs ?? 0));
    final totalF = logs.fold(0.0, (s, l) => s + (l.fat ?? 0));
    final total = totalP + totalC + totalF;
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _ChartCard(
        title: 'Macronutrients',
        subtitle: 'Average macro split',
        icon: Icons.pie_chart,
        color: AppColors.accent,
        child: SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: [
                    PieChartSectionData(value: totalP, color: AppColors.success, title: '', radius: 28),
                    PieChartSectionData(value: totalC, color: AppColors.accent, title: '', radius: 28),
                    PieChartSectionData(value: totalF, color: AppColors.warning, title: '', radius: 28),
                  ],
                )),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MacroLegend(color: AppColors.success, label: 'Protein', pct: totalP / total),
                  const SizedBox(height: 8),
                  _MacroLegend(color: AppColors.accent, label: 'Carbs', pct: totalC / total),
                  const SizedBox(height: 8),
                  _MacroLegend(color: AppColors.warning, label: 'Fat', pct: totalF / total),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChart(List<DailyLog> logs) {
    const moodScore = {'happy': 5.0, 'good': 4.0, 'neutral': 3.0, 'sad': 2.0, 'angry': 1.0};
    final withMood = logs.where((l) => l.mood != null && moodScore.containsKey(l.mood)).toList();
    if (withMood.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _ChartCard(
        title: 'Mood Trend',
        subtitle: 'Daily mood over time',
        icon: Icons.mood,
        color: const Color(0xFF8B5CF6),
        child: SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x11000000), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= withMood.length) return const SizedBox.shrink();
                  return SideTitleWidget(meta: m, space: 6,
                    child: Text(DateFormat('dd/MM').format(withMood[i].date),
                        style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight)));
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, m) {
                  const labels = {1: '😠', 2: '😢', 3: '😐', 4: '😊', 5: '😁'};
                  return SideTitleWidget(meta: m, space: 4,
                    child: Text(labels[v.toInt()] ?? '', style: const TextStyle(fontSize: 12)));
                },
              )),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            minY: 0.5, maxY: 5.5,
            lineBarsData: [
              LineChartBarData(
                spots: withMood.asMap().entries.map((e) => FlSpot(e.key.toDouble(), moodScore[e.value.mood] ?? 3.0)).toList(),
                isCurved: true, color: const Color(0xFF8B5CF6), barWidth: 3, isStrokeCapRound: true,
                dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) =>
                    FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: const Color(0xFF8B5CF6))),
                belowBarData: BarAreaData(show: true, gradient: const LinearGradient(
                  colors: [Color(0x338B5CF6), Color(0x008B5CF6)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title, required String subtitle, required IconData icon,
    required Color color, required Widget chart,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _ChartCard(title: title, subtitle: subtitle, icon: icon, color: color, child: SizedBox(height: 180, child: chart)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No data yet', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textLight)),
        const SizedBox(height: 6),
        Text('Start logging daily to see your progress', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
      ]),
    );
  }

  // ─── Chart helpers ────────────────────────────────────────────────────────

  Widget _buildLineChart(List<DailyLog> logs, double Function(DailyLog) getValue, Color color, double target) {
    return LineChart(LineChartData(
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(y: target, color: color.withValues(alpha: 0.4), strokeWidth: 1.5, dashArray: [6, 4],
            label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                labelResolver: (_) => 'Target')),
      ]),
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: _buildTitlesData(logs),
      lineBarsData: [
        LineChartBarData(
          spots: logs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), getValue(e.value))).toList(),
          isCurved: true, color: color, barWidth: 2.5, isStrokeCapRound: true,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) =>
              FlDotCirclePainter(radius: 3.5, color: Colors.white, strokeWidth: 2, strokeColor: color)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
      ],
    ));
  }

  Widget _buildBarChart(List<DailyLog> logs, double Function(DailyLog) getValue, Color color, {double? maxY}) {
    return BarChart(BarChartData(
      maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: _buildTitlesData(logs),
      barGroups: logs.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: getValue(e.value), color: color, width: math.max(4, 200 / (logs.length + 1)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ])).toList(),
    ));
  }

  FlTitlesData _buildTitlesData(List<DailyLog> logs) {
    return FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 28,
        getTitlesWidget: (v, m) {
          final i = v.toInt();
          if (i < 0 || i >= logs.length) return const SizedBox.shrink();
          // Only show every nth label to avoid crowding
          final step = (logs.length / 5).ceil().clamp(1, 99);
          if (i % step != 0) return const SizedBox.shrink();
          return SideTitleWidget(meta: m, space: 6,
            child: Text(DateFormat('dd/MM').format(logs[i].date),
                style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight)));
        },
      )),
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 42,
        getTitlesWidget: (v, m) => SideTitleWidget(meta: m, space: 4,
          child: Text(_fmt(v), style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight))),
      )),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ChartCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
            ]),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniMetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight)),
        ]),
      ),
    );
  }
}

class _AvgItem extends StatelessWidget {
  final String label, value, sub;
  final bool ok;
  const _AvgItem({required this.label, required this.value, required this.sub, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          Row(children: [
            Icon(ok ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 11,
                color: ok ? Colors.greenAccent : Colors.orangeAccent),
            const SizedBox(width: 3),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
          ]),
        ]),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  const _MacroLegend({required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text('$label ${(pct * 100).toStringAsFixed(0)}%',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w500)),
    ]);
  }
}

// ─── Health Score Ring Painter ────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double value;
  const _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final bgPaint = Paint()..color = Colors.white24..strokeWidth = 7..style = PaintingStyle.stroke;
    final fgPaint = Paint()..color = Colors.white..strokeWidth = 7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * value, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
