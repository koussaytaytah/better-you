import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/daily_log_model.dart';
import '../services/challenge_service.dart';
import '../services/local_database_service.dart';
import '../utils/logger.dart';

class DailyLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChallengeService _challengeService;
  final LocalDatabaseService _localDb;

  DailyLogRepository(this._challengeService, this._localDb);

  Future<void> addDailyLog(DailyLog log) async {
    try {
      await _firestore
          .collection('daily_logs')
          .doc(log.id)
          .set(log.toFirestore());
      await _localDb.saveDailyLog(log);
      await _challengeService.checkChallenges(log.userId, log);
    } catch (e, stack) {
      AppLogger.e('Error adding daily log', e, stack);
      await _localDb.saveDailyLog(log);
    }
  }

  Future<void> updateDailyLog(
    String userId,
    DateTime date,
    Map<String, dynamic> data,
  ) async {
    final dateStr = "${date.year}-${date.month}-${date.day}";
    final logId = "${userId}_$dateStr";
    final logRef = _firestore.collection('daily_logs').doc(logId);

    try {
      final doc = await logRef.get();
      DailyLog? updatedLog;

      if (doc.exists) {
        await logRef.update(data);
        updatedLog = DailyLog.fromFirestore(await logRef.get());
      } else {
        final newLogData = {
          'userId': userId,
          'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
          ...data,
        };
        await logRef.set(newLogData);
        updatedLog = DailyLog.fromFirestore(await logRef.get());
      }

      await _localDb.saveDailyLog(updatedLog);
      await _challengeService.checkChallenges(userId, updatedLog);
    } catch (e, stack) {
      AppLogger.e('Error updating daily log in Firestore', e, stack);
      final localLog = _localDb.getDailyLog(userId, date);
      if (localLog != null) {
        final updatedLocal = DailyLog(
          id: localLog.id,
          userId: userId,
          date: localLog.date,
          calories: data['calories'] ?? localLog.calories,
          cigarettes: data['cigarettes'] ?? localLog.cigarettes,
          exerciseMinutes: data['exerciseMinutes'] ?? localLog.exerciseMinutes,
          waterGlasses: data['waterGlasses'] ?? localLog.waterGlasses,
          sleepHours: data['sleepHours'] ?? localLog.sleepHours,
          steps: data['steps'] ?? localLog.steps,
          alcohol: data['alcohol'] ?? localLog.alcohol,
          protein: data['protein'] ?? localLog.protein,
          carbs: data['carbs'] ?? localLog.carbs,
          fat: data['fat'] ?? localLog.fat,
          meals: data['meals'] ?? localLog.meals,
          quests: data['quests'] ?? localLog.quests,
        );
        await _localDb.saveDailyLog(updatedLocal);
      }
    }
  }

  Stream<DailyLog?> getDailyLog(String userId, DateTime date) {
    if (userId.isEmpty) return Stream.value(null);

    final localLog = _localDb.getDailyLog(userId, date);
    final dateStr = "${date.year}-${date.month}-${date.day}";
    final logId = "${userId}_$dateStr";

    return _firestore.collection('daily_logs').doc(logId).snapshots().map((doc) {
      if (!doc.exists) return localLog;
      try {
        final log = DailyLog.fromFirestore(doc);
        _localDb.saveDailyLog(log);
        return log;
      } catch (e) {
        AppLogger.e('Error parsing daily log', e);
        return localLog;
      }
    });
  }

  Stream<List<DailyLog>> getUserDailyLogs(String userId) {
    // Phase 4: Performance Optimization
    // Now using orderBy to let Firestore do the sorting
    return _firestore
        .collection('daily_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DailyLog.fromFirestore(doc))
              .toList();
        });
  }
}
