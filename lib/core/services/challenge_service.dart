import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/challenge_model.dart';
import '../../shared/models/daily_log_model.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkChallenges(String userId, DailyLog log) async {
    // 1. Ensure user has basic challenges assigned
    await _ensureChallengesAssigned(userId);

    // 2. Get all user challenges and filter in memory to avoid index requirements
    final userChallengesQuery = await _firestore
        .collection('user_challenges')
        .where('userId', isEqualTo: userId)
        .get();

    final activeChallenges = userChallengesQuery.docs
        .where((doc) => doc.data()['isCompleted'] == false)
        .map((doc) => UserChallenge.fromFirestore(doc))
        .toList();

    for (var userChallenge in activeChallenges) {
      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(userChallenge.challengeId)
          .get();
      if (!challengeDoc.exists) continue;

      final challenge = Challenge.fromFirestore(challengeDoc);
      await _updateProgress(userChallenge, challenge, log);
    }
  }

  Future<void> _ensureChallengesAssigned(String userId) async {
    final existing = await _firestore
        .collection('user_challenges')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      // Assign initial bronze challenges
      final bronzeChallenges = await _firestore
          .collection('challenges')
          .where('tier', isEqualTo: 'bronze')
          .get();

      for (var doc in bronzeChallenges.docs) {
        await _firestore.collection('user_challenges').add({
          'userId': userId,
          'challengeId': doc.id,
          'currentProgress': 0,
          'isCompleted': false,
          'startedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _updateProgress(
    UserChallenge userChallenge,
    Challenge challenge,
    DailyLog log,
  ) async {
    int newProgress = userChallenge.currentProgress;
    bool isCompleted = false;

    switch (challenge.metric) {
      case 'cigarettes':
        if ((log.cigarettes ?? 0) == 0) {
          newProgress++;
        } else {
          newProgress = 0; // Reset streak
        }
        break;
      case 'water':
        if ((log.waterGlasses ?? 0) >= challenge.targetValue) {
          newProgress++;
        }
        break;
      case 'exercise':
        if ((log.exerciseMinutes ?? 0) >= challenge.targetValue) {
          newProgress++;
        }
        break;
      case 'sleep':
        if ((log.sleepHours ?? 0) >= challenge.targetValue) {
          newProgress++;
        }
        break;
    }

    if (newProgress >= challenge.durationDays) {
      isCompleted = true;
    }

    await _firestore
        .collection('user_challenges')
        .doc(userChallenge.id)
        .update({
          'currentProgress': newProgress,
          'isCompleted': isCompleted,
          'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
        });

    if (isCompleted) {
      await _rewardUser(userChallenge.userId, challenge);
      await _unlockNextTier(userChallenge.userId, challenge);
    }
  }

  Future<void> _rewardUser(String userId, Challenge challenge) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    int currentXp = userData['xp'] ?? 0;
    int currentLevel = userData['level'] ?? 1;

    int newXp = currentXp + challenge.xpReward;

    // Simple level up logic: level * 1000 xp needed
    int xpNeeded = currentLevel * 1000;
    if (newXp >= xpNeeded) {
      newXp -= xpNeeded;
      currentLevel++;
    }

    await _firestore.collection('users').doc(userId).update({
      'xp': newXp,
      'level': currentLevel,
    });
  }

  Future<void> _unlockNextTier(
    String userId,
    Challenge completedChallenge,
  ) async {
    String nextTier;
    switch (completedChallenge.tier) {
      case ChallengeTier.bronze:
        nextTier = 'silver';
        break;
      case ChallengeTier.silver:
        nextTier = 'gold';
        break;
      case ChallengeTier.gold:
        nextTier = 'platinum';
        break;
      default:
        return;
    }

    // Find the next tier challenge for the same metric
    final nextChallengeQuery = await _firestore
        .collection('challenges')
        .where('metric', isEqualTo: completedChallenge.metric)
        .where('tier', isEqualTo: nextTier)
        .limit(1)
        .get();

    if (nextChallengeQuery.docs.isNotEmpty) {
      final nextChallengeId = nextChallengeQuery.docs.first.id;

      // Check if user already has this challenge
      final alreadyAssigned = await _firestore
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: nextChallengeId)
          .limit(1)
          .get();

      if (alreadyAssigned.docs.isEmpty) {
        await _firestore.collection('user_challenges').add({
          'userId': userId,
          'challengeId': nextChallengeId,
          'currentProgress': 0,
          'isCompleted': false,
          'startedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Helper to seed some initial challenges if needed
  Future<void> seedChallenges() async {
    final challenges = [
      // NO SMOKING
      Challenge(
        id: 'no_smoking_bronze',
        title: 'Smoke Free Starter',
        description: 'Go 3 days without smoking.',
        icon: '🚭',
        type: ChallengeType.streak,
        metric: 'cigarettes',
        targetValue: 0,
        durationDays: 3,
        tier: ChallengeTier.bronze,
        xpReward: 200,
        category: 'health',
      ),
      Challenge(
        id: 'no_smoking_silver',
        title: 'Smoke Free Week',
        description: 'Go 7 days without smoking.',
        icon: '🚭',
        type: ChallengeType.streak,
        metric: 'cigarettes',
        targetValue: 0,
        durationDays: 7,
        tier: ChallengeTier.silver,
        xpReward: 500,
        category: 'health',
      ),
      Challenge(
        id: 'no_smoking_gold',
        title: 'Smoke Free Month',
        description: 'Go 30 days without smoking.',
        icon: '🚭',
        type: ChallengeType.streak,
        metric: 'cigarettes',
        targetValue: 0,
        durationDays: 30,
        tier: ChallengeTier.gold,
        xpReward: 2000,
        category: 'health',
      ),

      // WATER
      Challenge(
        id: 'water_bronze',
        title: 'Hydration Novice',
        description: 'Drink 8 glasses of water for 3 days.',
        icon: '💧',
        type: ChallengeType.count,
        metric: 'water',
        targetValue: 8,
        durationDays: 3,
        tier: ChallengeTier.bronze,
        xpReward: 150,
        category: 'health',
      ),
      Challenge(
        id: 'water_silver',
        title: 'Hydration Pro',
        description: 'Drink 8 glasses of water for 7 days.',
        icon: '💧',
        type: ChallengeType.count,
        metric: 'water',
        targetValue: 8,
        durationDays: 7,
        tier: ChallengeTier.silver,
        xpReward: 400,
        category: 'health',
      ),

      // EXERCISE
      Challenge(
        id: 'exercise_bronze',
        title: 'Active Beginner',
        description: 'Exercise for 30 mins for 3 days.',
        icon: '🏋️',
        type: ChallengeType.count,
        metric: 'exercise',
        targetValue: 30,
        durationDays: 3,
        tier: ChallengeTier.bronze,
        xpReward: 250,
        category: 'fitness',
      ),
      Challenge(
        id: 'exercise_silver',
        title: 'Fitness Fanatic',
        description: 'Exercise for 30 mins for 7 days.',
        icon: '🏋️',
        type: ChallengeType.count,
        metric: 'exercise',
        targetValue: 30,
        durationDays: 7,
        tier: ChallengeTier.silver,
        xpReward: 600,
        category: 'fitness',
      ),
    ];

    for (var c in challenges) {
      await _firestore.collection('challenges').doc(c.id).set({
        'title': c.title,
        'description': c.description,
        'icon': c.icon,
        'type': c.type.toString().split('.').last,
        'tier': c.tier.toString().split('.').last,
        'metric': c.metric,
        'targetValue': c.targetValue,
        'durationDays': c.durationDays,
        'xpReward': c.xpReward,
        'category': c.category,
      });
    }
  }
}
