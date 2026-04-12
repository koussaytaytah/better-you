import 'package:cloud_firestore/cloud_firestore.dart';

class GroupQuest {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., 'diet', 'exercise', 'smoking'
  final int goalDays;
  final DateTime startDate;
  final List<String> participantIds;
  final Map<String, int> participantProgress; // userId: daysCompleted
  final String creatorId;

  GroupQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.goalDays,
    required this.startDate,
    this.participantIds = const [],
    this.participantProgress = const {},
    required this.creatorId,
  });

  factory GroupQuest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupQuest(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      goalDays: data['goalDays'] ?? 30,
      startDate: (data['startDate'] as Timestamp).toDate(),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantProgress: Map<String, int>.from(data['participantProgress'] ?? {}),
      creatorId: data['creatorId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'goalDays': goalDays,
      'startDate': Timestamp.fromDate(startDate),
      'participantIds': participantIds,
      'participantProgress': participantProgress,
      'creatorId': creatorId,
    };
  }
}
