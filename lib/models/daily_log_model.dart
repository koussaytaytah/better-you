import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  final String id;
  final String userId;
  final DateTime date;
  final int? cigarettes;
  final double? alcohol; // in units, e.g., beers
  final int? calories;
  final int? exerciseMinutes;
  final List<String>? meals;

  DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    this.cigarettes,
    this.alcohol,
    this.calories,
    this.exerciseMinutes,
    this.meals,
  });

  factory DailyLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyLog(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      cigarettes: data['cigarettes'],
      alcohol: data['alcohol'],
      calories: data['calories'],
      exerciseMinutes: data['exerciseMinutes'],
      meals: List<String>.from(data['meals'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'cigarettes': cigarettes,
      'alcohol': alcohol,
      'calories': calories,
      'exerciseMinutes': exerciseMinutes,
      'meals': meals,
    };
  }
}
