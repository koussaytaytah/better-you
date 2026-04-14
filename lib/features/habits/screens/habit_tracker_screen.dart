import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';
import '../widgets/professional_prescriptions_widget.dart';
import 'ai_food_detection_screen.dart';

class HabitTrackerScreen extends ConsumerStatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  ConsumerState<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends ConsumerState<HabitTrackerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newHabitController = TextEditingController();
  String _searchQuery = '';
  bool _hasOpenedModal = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserAsyncProvider);
    final todayLogAsync = ref.watch(todayLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Habits',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();
          return todayLogAsync.when(
            data: (log) => _buildBody(
              user,
              log ?? DailyLog(id: '', userId: user.uid, date: DateTime.now()),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(user, DailyLog log) {
    final habitsList = _getHabitsList(user);
    final habitsMap = log.quests ?? {};
    final completedCount = habitsMap.values.where((v) => v == true).length;
    final totalCount = habitsList.length;
    final percentage = totalCount == 0
        ? 0
        : (completedCount / totalCount * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 32),
          _buildWeeklyQuestTable(user),
          const SizedBox(height: 32),
          const ProfessionalPrescriptionsWidget(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Today\'s Quests'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentage% Done',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHabitsList(user, log),
        ],
      ),
    );
  }

  Widget _buildWeeklyQuestTable(user) {
    final habitsList = _getHabitsList(user);
    if (habitsList.isEmpty) return const SizedBox();

    final last7DaysAsync = ref.watch(last7DaysLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Weekly Tracking'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: last7DaysAsync.when(
            data: (logs) {
              final days = List.generate(7, (index) {
                final date = DateTime.now().subtract(Duration(days: 6 - index));
                return date;
              });

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Quest',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...days.map(
                          (d) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              DateFormat('E').format(d),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...habitsList.map((habit) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              habit,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ...days.map((day) {
                            final logForDay = logs.firstWhere(
                              (l) =>
                                  l.date.year == day.year &&
                                  l.date.month == day.month &&
                                  l.date.day == day.day,
                              orElse: () =>
                                  DailyLog(id: '', userId: '', date: day),
                            );
                            final isDone = logForDay.quests?[habit] ?? false;
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isDone
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isDone
                                    ? AppColors.primary
                                    : Colors.grey[300],
                                size: 18,
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading weekly data'),
          ),
        ),
      ],
    );
  }

  void _showPhotoCalorieModal(DailyLog log) {
    final ImagePicker picker = ImagePicker();
    XFile? selectedImage;
    bool isAnalyzing = false;
    Map<String, dynamic>? detectedMacros;

    Future<void> analyzeImage(XFile image, StateSetter setModalState) async {
      setModalState(() {
        selectedImage = image;
        isAnalyzing = true;
      });

      try {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        final result = await ref
            .read(aiServiceProvider)
            .analyzeFoodImage(base64Image);

        setModalState(() {
          isAnalyzing = false;
          if (result != null) {
            detectedMacros = result;
          } else {
            // Fallback if AI fails
            detectedMacros = {
              'calories': 0,
              'protein': 0.0,
              'carbs': 0.0,
              'fat': 0.0,
              'name': 'Detection failed. Please try again.',
            };
          }
        });
      } catch (e) {
        setModalState(() {
          isAnalyzing = false;
          detectedMacros = {
            'calories': 0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'name': 'Error: $e',
          };
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI Food Detection',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        await analyzeImage(image, setModalState);
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 8,
                        ),
                        image: selectedImage != null
                            ? DecorationImage(
                                image: FileImage(File(selectedImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        await analyzeImage(image, setModalState);
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload from Gallery'),
                  ),
                  if (isAnalyzing) ...[
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Analyzing food with AI...'),
                  ] else if (detectedMacros != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      detectedMacros!['name'] ?? 'Unknown Dish',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Plate Breakdown (Macros)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: 0.85,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.pie_chart,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            children: [
                              _buildMacroRow(
                                'Calories',
                                '${detectedMacros!['calories']} kcal',
                                Colors.orange,
                              ),
                              _buildMacroRow(
                                'Protein',
                                '${detectedMacros!['protein']}g',
                                Colors.blue,
                              ),
                              _buildMacroRow(
                                'Carbs',
                                '${detectedMacros!['carbs']}g',
                                Colors.green,
                              ),
                              _buildMacroRow(
                                'Fat',
                                '${detectedMacros!['fat']}g',
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              detectedMacros == null ||
                                  detectedMacros!['calories'] == 0
                              ? null
                              : () {
                                  _updateLog(log, {
                                    'calories':
                                        (log.calories ?? 0) +
                                        (detectedMacros!['calories'] as num)
                                            .toInt(),
                                    'protein':
                                        (log.protein ?? 0) +
                                        (detectedMacros!['protein'] as num)
                                            .toDouble(),
                                    'carbs':
                                        (log.carbs ?? 0) +
                                        (detectedMacros!['carbs'] as num)
                                            .toDouble(),
                                    'fat':
                                        (log.fat ?? 0) +
                                        (detectedMacros!['fat'] as num)
                                            .toDouble(),
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added ${detectedMacros!['calories']} calories to your log!',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Add to Log',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: color, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final todayLogAsync = ref.watch(todayLogProvider);
    return todayLogAsync.when(
      data: (log) {
        final currentLog =
            log ?? DailyLog(id: '', userId: '', date: DateTime.now());
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newHabitController,
                    decoration: InputDecoration(
                      hintText: 'Write a quest (e.g. Wake up at 6am)',
                      prefixIcon: const Icon(Icons.edit_note),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _addNewHabit(val.trim());
                        _newHabitController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_newHabitController.text.trim().isNotEmpty) {
                      _addNewHabit(_newHabitController.text.trim());
                      _newHabitController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIFoodDetectionScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search quests...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildHabitsList(user, DailyLog log) {
    final habitsList = _getHabitsList(
      user,
    ).where((h) => h.toLowerCase().contains(_searchQuery)).toList();

    if (habitsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.checklist_rtl, color: Colors.grey[300], size: 64),
              const SizedBox(height: 16),
              const Text(
                'No habits found. Create one to start!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final habitsMap = log.quests ?? {};

    return Column(
      children: habitsList.map<Widget>((habitName) {
        final isCompleted = habitsMap[habitName] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            title: Text(
              habitName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
            trailing: GestureDetector(
              onTap: () {
                final newQuests = Map<String, bool>.from(habitsMap);
                newQuests[habitName] = !isCompleted;
                _updateLog(log, {'quests': newQuests});
                
                // Award XP if completing the habit!
                if (!isCompleted) {
                   final user = ref.read(currentUserProvider);
                   if (user != null) {
                     ref.read(userRepositoryProvider).addXP(user.uid, 20);
                     ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);
                   }
                }
              },
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.add,
                  color: isCompleted ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getHabitsList(user) {
    if (user.habits is List) return List<String>.from(user.habits);
    if (user.habits is Map)
      return (user.habits as Map).keys.cast<String>().toList();
    return [];
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'New Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _newHabitController,
          decoration: const InputDecoration(
            hintText: 'What habit do you want to track?',
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
              if (_newHabitController.text.trim().isEmpty) return;
              await _addNewHabit(_newHabitController.text.trim());
              if (mounted) {
                Navigator.pop(context);
                _newHabitController.clear();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewHabit(String habitName) async {
    final user = ref.read(currentUserAsyncProvider).value;
    if (user == null) return;

    final currentHabits = _getHabitsList(user);
    if (currentHabits.contains(habitName)) return;

    currentHabits.add(habitName);
    await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
      'habits': currentHabits,
    });
    ref.invalidate(currentUserAsyncProvider);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _updateLog(DailyLog log, Map<String, dynamic> data) async {
    final user = ref.read(currentUserAsyncProvider).value;
    if (user == null) return;

    await ref
        .read(dailyLogRepositoryProvider).updateDailyLog(user.uid, DateTime.now(), data);
    ref.invalidate(todayLogProvider);
  }
}
