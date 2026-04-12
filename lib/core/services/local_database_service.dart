import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/daily_log_model.dart';
import '../utils/logger.dart';

class LocalDatabaseService {
  static const String dailyLogsBoxName = 'daily_logs';

  Future<void> saveDailyLog(DailyLog log) async {
    try {
      final box = Hive.box<DailyLog>(dailyLogsBoxName);
      await box.put(log.id, log);
      AppLogger.i('Saved log ${log.id} to Hive');
    } catch (e, stack) {
      AppLogger.e('Error saving log to Hive', e, stack);
    }
  }

  DailyLog? getDailyLog(String userId, DateTime date) {
    try {
      final box = Hive.box<DailyLog>(dailyLogsBoxName);
      final dateStr = "${date.year}-${date.month}-${date.day}";
      final logId = "${userId}_$dateStr";
      return box.get(logId);
    } catch (e, stack) {
      AppLogger.e('Error getting log from Hive', e, stack);
      return null;
    }
  }

  List<DailyLog> getAllDailyLogs(String userId) {
    try {
      final box = Hive.box<DailyLog>(dailyLogsBoxName);
      return box.values.where((log) => log.userId == userId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e, stack) {
      AppLogger.e('Error getting all logs from Hive', e, stack);
      return [];
    }
  }

  Future<void> clearAll() async {
    final box = Hive.box<DailyLog>(dailyLogsBoxName);
    await box.clear();
  }
}
