import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType { streak, count, boolean }

enum ChallengeTier { bronze, silver, gold, platinum }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final ChallengeType type;
  final ChallengeTier tier;
  final String metric; // e.g., 'cigarettes', 'steps', 'water'
  final int targetValue;
  final int durationDays;
  final int xpReward;
  final String category; // e.g., 'fitness', 'health', 'mental'

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.tier = ChallengeTier.bronze,
    required this.metric,
    required this.targetValue,
    required this.durationDays,
    this.xpReward = 100,
    this.category = 'general',
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      type: ChallengeType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ChallengeType.count,
      ),
      tier: ChallengeTier.values.firstWhere(
        (e) => e.toString().split('.').last == data['tier'],
        orElse: () => ChallengeTier.bronze,
      ),
      metric: data['metric'] ?? '',
      targetValue: data['targetValue'] ?? 0,
      durationDays: data['durationDays'] ?? 1,
      xpReward: data['xpReward'] ?? 100,
      category: data['category'] ?? 'general',
    );
  }
}

class UserChallenge {
  final String id;
  final String userId;
  final String challengeId;
  final int currentProgress;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.currentProgress,
    required this.isCompleted,
    required this.startedAt,
    this.completedAt,
  });

  factory UserChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserChallenge(
      id: doc.id,
      userId: data['userId'] ?? '',
      challengeId: data['challengeId'] ?? '',
      currentProgress: data['currentProgress'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }
}
