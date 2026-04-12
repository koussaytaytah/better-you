import 'package:csv/csv.dart';
import '../../shared/models/daily_log_model.dart';
import '../utils/logger.dart';

// Conditional imports for cross-platform compatibility
import 'export_stub.dart'
    if (dart.library.io) 'export_non_web.dart'
    if (dart.library.html) 'export_web.dart';

class ExportService {
  Future<String?> exportLogsToCsv(List<DailyLog> logs) async {
    try {
      List<List<dynamic>> csvData = [
        [
          'Date',
          'Calories',
          'Water (Glasses)',
          'Steps',
          'Exercise (Mins)',
          'Sleep (Hours)',
          'Cigarettes',
          'Alcohol (Units)',
          'Health Score',
        ],
      ];

      for (var log in logs) {
        csvData.add([
          log.date.toIso8601String().split('T')[0],
          log.calories ?? 0,
          log.waterGlasses ?? 0,
          log.steps ?? 0,
          log.exerciseMinutes ?? 0,
          log.sleepHours ?? 0,
          log.cigarettes ?? 0,
          log.alcohol ?? 0,
          log.calculateHealthScore(),
        ]);
      }

      String csvString = '\u{FEFF}${csv.encode(csvData)}';
      
      final result = await exportPlatformCsv(csvString);
      AppLogger.i('Logs exported successfully to $result');
      return result;

    } catch (e, stack) {
      AppLogger.e('Error exporting logs to CSV', e, stack);
      return null;
    }
  }
}
