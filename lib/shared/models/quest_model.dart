import 'package:cloud_firestore/cloud_firestore.dart';

class Quest {
  final String id;
  final String title;
  final String userId;
  final DateTime createdAt;
  final bool isActive;
  final String? assignedBy;
  final String? assignedByName;
  final bool isCoachSuggested;

  Quest({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    this.isActive = true,
    this.assignedBy,
    this.assignedByName,
    this.isCoachSuggested = false,
  });

  factory Quest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quest(
      id: doc.id,
      title: data['title'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      assignedBy: data['assignedBy']?.toString(),
      assignedByName: data['assignedByName']?.toString(),
      isCoachSuggested: data['isCoachSuggested'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'isCoachSuggested': isCoachSuggested,
    };
  }
}
