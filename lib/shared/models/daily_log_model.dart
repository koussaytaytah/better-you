import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: 0)
class DailyLog {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final int? cigarettes;
  @HiveField(4)
  final double? alcohol;
  @HiveField(5)
  final int? calories;
  @HiveField(6)
  final double? protein;
  @HiveField(7)
  final double? carbs;
  @HiveField(8)
  final double? fat;
  @HiveField(9)
  final int? exerciseMinutes;
  @HiveField(10)
  final int? waterGlasses;
  @HiveField(11)
  final double? sleepHours;
  @HiveField(12)
  final int? steps;
  @HiveField(13)
  final Map<String, dynamic>? meals;
  @HiveField(14)
  final Map<String, bool>? quests;
  @HiveField(15)
  final String? mood;

  DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    this.cigarettes,
    this.alcohol,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.exerciseMinutes,
    this.waterGlasses,
    this.sleepHours,
    this.steps,
    this.meals,
    this.quests,
    this.mood,
  });

  factory DailyLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      cigarettes: (data['cigarettes'] as num?)?.toInt(),
      alcohol: (data['alcohol'] as num?)?.toDouble(),
      calories: (data['calories'] as num?)?.toInt(),
      protein: (data['protein'] as num?)?.toDouble(),
      carbs: (data['carbs'] as num?)?.toDouble(),
      fat: (data['fat'] as num?)?.toDouble(),
      exerciseMinutes: (data['exerciseMinutes'] as num?)?.toInt(),
      waterGlasses: (data['waterGlasses'] as num?)?.toInt(),
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      steps: (data['steps'] as num?)?.toInt(),
      meals: data['meals'] as Map<String, dynamic>?,
      quests: data['quests'] != null
          ? Map<String, bool>.from(data['quests'])
          : null,
      mood: data['mood'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'cigarettes': cigarettes,
      'alcohol': alcohol,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'exerciseMinutes': exerciseMinutes,
      'waterGlasses': waterGlasses,
      'sleepHours': sleepHours,
      'steps': steps,
      'meals': meals,
      'quests': quests,
      'mood': mood,
    };
  }

  int calculateHealthScore() {
    double score = 50.0; // Start at baseline

    // Mood: +10 for Happy, +5 for Good, -5 for Sad, -10 for Angry
    if (mood != null) {
      switch (mood) {
        case 'happy':
          score += 10;
          break;
        case 'good':
          score += 5;
          break;
        case 'sad':
          score -= 5;
          break;
        case 'angry':
          score -= 10;
          break;
      }
    }

    // Water: +5 per glass, max +20 (8 glasses)
    if (waterGlasses != null) {
      score += (waterGlasses! * 2.5).clamp(0, 20);
    }

    // Exercise: +1 per minute, max +30 (30 mins)
    if (exerciseMinutes != null) {
      score += (exerciseMinutes! * 1.0).clamp(0, 30);
    }

    // Sleep: 7-9 hours is ideal (+20)
    if (sleepHours != null) {
      if (sleepHours! >= 7 && sleepHours! <= 9) {
        score += 20;
      } else if (sleepHours! > 5) {
        score += 10;
      }
    }

    // Steps: +1 per 500 steps, max +20 (10k steps)
    if (steps != null) {
      score += (steps! / 500.0).clamp(0, 20);
    }

    // Cigarettes: -10 per cigarette, max -50
    if (cigarettes != null) {
      score -= (cigarettes! * 10.0).clamp(0, 50);
    }

    // Alcohol: -10 per unit, max -30
    if (alcohol != null) {
      score -= (alcohol! * 10.0).clamp(0, 30);
    }

    return score.clamp(0, 100).toInt();
  }
}
