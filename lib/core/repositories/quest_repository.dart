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
          return snapshot.docs
              .map((doc) => Quest.fromFirestore(doc))
              .toList();
        });
  }
}
