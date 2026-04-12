import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../core/utils/logger.dart';

class DailyMetricsScreen extends ConsumerStatefulWidget {
  const DailyMetricsScreen({super.key});

  @override
  ConsumerState<DailyMetricsScreen> createState() => _DailyMetricsScreenState();
}

class _DailyMetricsScreenState extends ConsumerState<DailyMetricsScreen> {
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  @override
  void dispose() {
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _audioPath = '${dir.path}/log_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );
        setState(() => _isRecording = true);
      }
    } catch (e) {
      AppLogger.e('Recording start failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        await _processAudio(path);
      }
    } catch (e) {
      AppLogger.e('Recording stop failed: $e');
    }
  }

  Future<void> _processAudio(String path) async {
    setState(() => _isProcessing = true);
    try {
      final text = await ref.read(aiServiceProvider).transcribeAudio(path);
      if (text != null && text.isNotEmpty) {
        _textController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transcribed: "$text"')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _submitLog() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isProcessing = true);
    
    try {
      final parsedData = await ref.read(aiServiceProvider).parseQuickLog(text);
      if (parsedData != null && parsedData.isNotEmpty) {
        await _updateLogFromAI(parsedData);
        _textController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Metrics logged successfully! ✨')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not understand metrics from text.')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateLogFromAI(Map<String, dynamic> data) async {
    final user = ref.read(currentUserAsyncProvider).value;
    final log = ref.read(todayLogProvider).value;
    if (user == null || log == null) return;

    Map<String, dynamic> updates = {};
    
    if (data.containsKey('water_glasses')) {
      updates['waterGlasses'] = (log.waterGlasses ?? 0) + (data['water_glasses'] as num).toInt();
    }
    if (data.containsKey('exercise_minutes')) {
      updates['exerciseMinutes'] = (log.exerciseMinutes ?? 0) + (data['exercise_minutes'] as num).toInt();
    }
    if (data.containsKey('cigarettes')) {
      updates['cigarettes'] = (log.cigarettes ?? 0) + (data['cigarettes'] as num).toInt();
    }
    if (data.containsKey('alcohol_units')) {
      updates['alcohol'] = (log.alcohol ?? 0) + (data['alcohol_units'] as num).toDouble();
    }
    if (data.containsKey('sleep_hours')) {
      updates['sleepHours'] = (data['sleep_hours'] as num).toDouble(); // Overwrite instead of add
    }
    if (data.containsKey('steps')) {
      updates['steps'] = (log.steps ?? 0) + (data['steps'] as num).toInt();
    }

    if (data.containsKey('calories')) {
      updates['calories'] = (log.calories ?? 0) + (data['calories'] as num).toInt();
    }
    if (data.containsKey('protein_g')) {
      updates['protein'] = (log.protein ?? 0) + (data['protein_g'] as num).toDouble();
    }
    if (data.containsKey('carbs_g')) {
      updates['carbs'] = (log.carbs ?? 0) + (data['carbs_g'] as num).toDouble();
    }
    if (data.containsKey('fat_g')) {
      updates['fat'] = (log.fat ?? 0) + (data['fat_g'] as num).toDouble();
    }

    if (updates.isNotEmpty) {
      await ref.read(dailyLogRepositoryProvider).updateDailyLog(user.uid, DateTime.now(), updates);
      ref.invalidate(todayLogProvider);
      
      // Award XP for logging via AI!
      await ref.read(userRepositoryProvider).addXP(user.uid, 50);
      await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);
    }
  }

  Future<void> _incrementMetric(String field, num currentVal, num incrementAmount) async {
    final user = ref.read(currentUserAsyncProvider).value;
    if (user == null) return;

    num newVal = currentVal + incrementAmount;
    if (newVal < 0) newVal = 0;

    await ref.read(dailyLogRepositoryProvider).updateDailyLog(user.uid, DateTime.now(), {
      field: newVal,
    });
    ref.invalidate(todayLogProvider);
    
    // Increment a tiny bit of XP for manual interaction
    await ref.read(userRepositoryProvider).addXP(user.uid, 5);
    await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(todayLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Life Metrics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: logAsync.when(
        data: (log) {
          final currentLog = log ?? DailyLog(id: '', userId: '', date: DateTime.now());
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Tap to log quickly, or use voice!',
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _buildMetricCard(
                      title: 'Water',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      value: '${currentLog.waterGlasses ?? 0}',
                      unit: 'Glasses',
                      onAdd: () => _incrementMetric('waterGlasses', currentLog.waterGlasses ?? 0, 1),
                      onSub: () => _incrementMetric('waterGlasses', currentLog.waterGlasses ?? 0, -1),
                    ),
                    _buildMetricCard(
                      title: 'Steps',
                      icon: Icons.directions_walk,
                      color: Colors.green,
                      value: '${currentLog.steps ?? 0}',
                      unit: 'Steps',
                      onAdd: () => _incrementMetric('steps', currentLog.steps ?? 0, 1000),
                      onSub: () => _incrementMetric('steps', currentLog.steps ?? 0, -1000),
                    ),
                    _buildMetricCard(
                      title: 'Sleep',
                      icon: Icons.bedtime,
                      color: Colors.indigo,
                      value: '${currentLog.sleepHours ?? 0.0}',
                      unit: 'Hours',
                      onAdd: () => _incrementMetric('sleepHours', currentLog.sleepHours ?? 0.0, 0.5),
                      onSub: () => _incrementMetric('sleepHours', currentLog.sleepHours ?? 0.0, -0.5),
                    ),
                    _buildMetricCard(
                      title: 'Exercise',
                      icon: Icons.fitness_center,
                      color: Colors.orange,
                      value: '${currentLog.exerciseMinutes ?? 0}',
                      unit: 'Minutes',
                      onAdd: () => _incrementMetric('exerciseMinutes', currentLog.exerciseMinutes ?? 0, 10),
                      onSub: () => _incrementMetric('exerciseMinutes', currentLog.exerciseMinutes ?? 0, -10),
                    ),
                    const Divider(height: 48),
                    Text('Vices Tracking', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      title: 'Cigarettes',
                      icon: Icons.smoking_rooms,
                      color: Colors.grey.shade700,
                      value: '${currentLog.cigarettes ?? 0}',
                      unit: 'Cigs',
                      onAdd: () => _incrementMetric('cigarettes', currentLog.cigarettes ?? 0, 1),
                      onSub: () => _incrementMetric('cigarettes', currentLog.cigarettes ?? 0, -1),
                    ),
                    _buildMetricCard(
                      title: 'Alcohol',
                      icon: Icons.wine_bar,
                      color: Colors.purple,
                      value: '${currentLog.alcohol ?? 0}',
                      unit: 'Units',
                      onAdd: () => _incrementMetric('alcohol', currentLog.alcohol ?? 0, 1),
                      onSub: () => _incrementMetric('alcohol', currentLog.alcohol ?? 0, -1),
                    ),
                  ],
                ),
              ),
              _buildVoiceInputBar(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required VoidCallback onAdd,
    required VoidCallback onSub,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 22, color: color)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(unit, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onSub,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey,
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle),
                color: color,
                iconSize: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: LinearProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'e.g. I drank 2 cups of water and slept 8h',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _submitLog(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _submitLog,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2)]
                        : [],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
