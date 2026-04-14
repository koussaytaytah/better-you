import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/quest_model.dart';
import '../utils/logger.dart';

class QuestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addQuest(Quest quest) async {
    await _firestore
        .collection('quests')
        .doc(quest.id)
        .set(quest.toFirestore());
  }

  Future<void> deleteQuest(String questId) async {
    await _firestore.collection('quests').doc(questId).delete();
  }

  Stream<List<Quest>> getUserQuests(String userId) {
    return _firestore
        .collection('quests')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final quests = snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList();
      // Sort: Professional suggestions first, then by date
      quests.sort((a, b) {
        if (a.isCoachSuggested && !b.isCoachSuggested) return -1;
        if (!a.isCoachSuggested && b.isCoachSuggested) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return quests;
    });
  }

  Future<void> suggestQuest(String userId, String professionalId, String professionalName, String questTitle) async {
    try {
      final docRef = _firestore.collection('quests').doc();
      final quest = Quest(
        id: docRef.id,
        title: questTitle,
        userId: userId,
        createdAt: DateTime.now(),
        assignedBy: professionalId,
        assignedByName: professionalName,
        isCoachSuggested: true,
      );
      await docRef.set(quest.toFirestore());
    } catch (e, stack) {
      AppLogger.e('Error suggesting quest', e, stack);
      rethrow;
    }
  }
}
