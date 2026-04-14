import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/quest_model.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/widgets/responsive_wrapper.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  final _questController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _questController.dispose();
    super.dispose();
  }

  Future<void> _addQuest() async {
    if (_questController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final quest = Quest(
      id: const Uuid().v4(),
      title: _questController.text.trim(),
      userId: user.uid,
      createdAt: DateTime.now(),
    );

    await ref.read(questRepositoryProvider).addQuest(quest);
    _questController.clear();
    setState(() => _isAdding = false);
  }

  Future<void> _toggleQuest(
    String questId,
    bool? completed,
    DailyLog? todayLog,
    bool isCoachSuggested,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final Map<String, bool> updatedQuests = Map<String, bool>.from(
      todayLog?.quests ?? {},
    );
    updatedQuests[questId] = completed ?? false;

    await ref.read(dailyLogRepositoryProvider).updateDailyLog(
      user.uid,
      DateTime.now(),
      {'quests': updatedQuests},
    );
    
    if (completed == true) {
      // Award Double XP for Coach-Suggested Quests
      final xpAmount = isCoachSuggested ? 100 : 50;
      await ref.read(userRepositoryProvider).addXP(user.uid, xpAmount);
      await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
// ... existing code ...
    final questsAsync = ref.watch(questsProvider);
    final todayLogAsync = ref.watch(todayLogProvider);
    final allLogsAsync = ref.watch(
      dailyLogsProvider(ref.watch(currentUserProvider)?.uid ?? ''),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Quests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildQuestInput(context),
              const SizedBox(height: 32),
              Text(
                'Today\'s Quests',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              questsAsync.when(
                data: (quests) => todayLogAsync.when(
                  data: (log) => _buildQuestList(quests, log, context),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 40),
              questsAsync.when(
                data: (quests) {
                  if (quests.isEmpty) return const SizedBox();

                  // Find the earliest quest creation date to start the history
                  DateTime earliestDate = DateTime.now();
                  for (var q in quests) {
                    if (q.createdAt.isBefore(earliestDate)) {
                      earliestDate = q.createdAt;
                    }
                  }

                  final int daysDiff = DateTime.now()
                      .difference(earliestDate)
                      .inDays;
                  final title = daysDiff <= 7
                      ? 'Quest History (Last 7 Days)'
                      : 'Quest History (Since Creation)';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      allLogsAsync.when(
                        data: (logs) =>
                            _buildQuestHistoryGrid(quests, logs, context),
                        loading: () => const SizedBox(),
                        error: (e, _) => const SizedBox(),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Daily Journey',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Complete your quests to level up!',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_isAdding) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _isAdding = true),
          icon: const Icon(Icons.add),
          label: const Text('Add New Quest'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isDark ? 0 : 2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _questController,
            autofocus: true,
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Wake up at 6 AM',
              hintStyle: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _addQuest(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isAdding = false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: AppColors.textLight),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Quest'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildQuestList(
    List<Quest> quests,
    DailyLog? log,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (quests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color:
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.05))
              : null,
        ),
        child: Center(
          child: Text(
            'No quests added yet. Create your first one above!',
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quest = quests[index];
        final isCompleted = log?.quests?[quest.id] ?? false;

        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary
                  : (quest.isCoachSuggested ? AppColors.accent : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 5,
              ),
            ],
          ),
          child: ListTile(
            leading: Checkbox(
              value: isCompleted,
              activeColor: AppColors.primary,
              side: isDark ? const BorderSide(color: Colors.white24) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (val) => _toggleQuest(quest.id, val, log, quest.isCoachSuggested),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quest.isCoachSuggested)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 12, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Suggested by ${quest.assignedByName ?? "Pro"}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  quest.title,
                  style: GoogleFonts.poppins(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? (isDark ? Colors.white38 : AppColors.textLight)
                        : (isDark ? Colors.white : AppColors.text),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () async {
                await ref.read(questRepositoryProvider).deleteQuest(quest.id);
              },
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideX();
      },
    );
  }

  Widget _buildQuestHistoryGrid(
    List<Quest> quests,
    List<DailyLog> logs,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (quests.isEmpty) return const SizedBox();

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

    final int daysToShow = today.difference(earliestDate).inDays + 1;

    final dynamicDates = List.generate(daysToShow, (i) {
      final date = today.subtract(Duration(days: i));
      return DateTime(date.year, date.month, date.day);
    }).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
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
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ),
            ...dynamicDates.map(
              (date) => DataColumn(
                label: Text(
                  DateFormat('MMM d').format(date),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                ...dynamicDates.map((date) {
                  final log = logs.firstWhere(
                    (l) => isSameDay(l.date, date),
                    orElse: () => DailyLog(id: '', userId: '', date: date),
                  );
                  final isCompleted = log.quests?[quest.id] ?? false;
                  final isFuture = date.isAfter(DateTime.now());
                  final wasCreatedBeforeDate = !date.isBefore(
                    DateTime(
                      quest.createdAt.year,
                      quest.createdAt.month,
                      quest.createdAt.day,
                    ),
                  );

                  return DataCell(
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: !wasCreatedBeforeDate
                            ? (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[100])
                            : (isFuture
                                  ? (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey[100])
                                  : (isCompleted
                                        ? AppColors.success
                                        : AppColors.danger)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: wasCreatedBeforeDate && !isFuture
                          ? Icon(
                              isCompleted ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
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
