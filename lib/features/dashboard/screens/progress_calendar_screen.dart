import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/quest_model.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

class ProgressCalendarScreen extends ConsumerStatefulWidget {
  const ProgressCalendarScreen({super.key});

  @override
  ConsumerState<ProgressCalendarScreen> createState() =>
      _ProgressCalendarScreenState();
}

class _ProgressCalendarScreenState
    extends ConsumerState<ProgressCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final logsAsync = ref.watch(dailyLogsProvider(user.uid));
    final questsAsync = ref.watch(questsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Health Calendar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: logsAsync.when(
        data: (logs) {
          final Map<DateTime, DailyLog> logsMap = {
            for (var log in logs)
              DateTime(log.date.year, log.date.month, log.date.day): log,
          };

          final selectedLog = _selectedDay != null
              ? logsMap[DateTime(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day,
                )]
              : null;

          return ResponsiveWrapper(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarCard(logsMap),
                  const SizedBox(height: 24),
                  if (selectedLog != null)
                    _buildLogDetails(selectedLog)
                  else
                    _buildEmptyState(),
                  const SizedBox(height: 40),
                  Text(
                    'Quest History (Last 10 Days)',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  questsAsync.when(
                    data: (quests) => _buildQuestTable(quests, logs),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading quests: $e'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCalendarCard(Map<DateTime, DailyLog> logsMap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 30)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) =>
            _selectedDay != null && isSameDay(_selectedDay!, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return logsMap.containsKey(normalizedDay)
              ? [logsMap[normalizedDay]]
              : [];
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            if (logsMap.containsKey(normalizedDay)) {
              final score = logsMap[normalizedDay]!.calculateHealthScore();
              return Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _getScoreColor(score), width: 2),
                ),
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          titleTextStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          weekendStyle: GoogleFonts.poppins(color: AppColors.accent),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.accent;
    return AppColors.danger;
  }

  Widget _buildLogDetails(DailyLog log) {
    final score = log.calculateHealthScore();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d').format(log.date),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $score',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatChip(
                'Calories',
                '${log.calories ?? 0} kcal',
                Icons.restaurant,
                AppColors.accent,
              ),
              _buildStatChip(
                'Water',
                '${log.waterGlasses ?? 0} glasses',
                Icons.local_drink,
                AppColors.secondary,
              ),
              _buildStatChip(
                'Exercise',
                '${log.exerciseMinutes ?? 0} min',
                Icons.fitness_center,
                AppColors.success,
              ),
              _buildStatChip(
                'Sleep',
                '${log.sleepHours ?? 0.0} hrs',
                Icons.bedtime,
                Colors.indigo,
              ),
              _buildStatChip(
                'Steps',
                '${log.steps ?? 0}',
                Icons.directions_walk,
                Colors.orange,
              ),
              if ((log.cigarettes ?? 0) > 0)
                _buildStatChip(
                  'Cigarettes',
                  '${log.cigarettes}',
                  Icons.smoking_rooms,
                  AppColors.danger,
                ),
              if ((log.alcohol ?? 0.0) > 0)
                _buildStatChip(
                  'Alcohol',
                  '${log.alcohol} units',
                  Icons.local_bar,
                  Colors.purple,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      Theme.of(context).textTheme.bodySmall?.color ??
                      AppColors.textLight,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a date to see your progress',
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTable(List<Quest> quests, List<DailyLog> logs) {
    if (quests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('No active quests found. Add some in the Quests screen!'),
        ),
      );
    }

    // Find the earliest quest creation date to start the history
    DateTime earliestDate = DateTime.now();
    for (var q in quests) {
      if (q.createdAt.isBefore(earliestDate)) {
        earliestDate = q.createdAt;
      }
    }

    // Normalize to start of day
    earliestDate = DateTime(
      earliestDate.year,
      earliestDate.month,
      earliestDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final int daysDiff = today.difference(earliestDate).inDays;
    // Show at least 7 days, even if quest was just created
    final int daysToShow = daysDiff < 7 ? 7 : daysDiff + 1;

    final dynamicDates = List.generate(daysToShow, (i) {
      final date = today.subtract(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    }).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          columns: [
            DataColumn(
              label: Text(
                'Quest',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
            ...dynamicDates.map(
              (date) => DataColumn(
                label: Text(
                  DateFormat('MMM d').format(date),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          rows: quests.map((quest) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    quest.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...dynamicDates.map((date) {
                  final log = logs.firstWhere(
                    (l) => isSameDay(l.date, date),
                    orElse: () => DailyLog(id: '', userId: '', date: date),
                  );
                  final isCompleted = log.quests?[quest.id] ?? false;

                  return DataCell(
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
