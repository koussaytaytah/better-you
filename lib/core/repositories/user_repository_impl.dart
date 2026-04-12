import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/user_model.dart';
import '../utils/logger.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRepositoryImpl();

  @override
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  @override
  Future<void> addXP(String userId, int amount) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        final data = userDoc.data()!;
        int currentXp = data['xp'] ?? 0;
        int currentLevel = data['level'] ?? 1;

        int newXp = currentXp + amount;
        int newLevel = currentLevel;

        bool leveledUp = false;
        while (newLevel < 100 && newXp >= newLevel * 1000) {
          newXp -= newLevel * 1000;
          newLevel++;
          leveledUp = true;
        }
        if (newLevel >= 100) {
          newLevel = 100;
          if (newXp > 100000) newXp = 100000; // Cap display XP
        }

        transaction.update(userRef, {'xp': newXp, 'level': newLevel});

        if (leveledUp) {
          await _firestore.collection('notifications').add({
            'userId': userId,
            'toUserId': userId,
            'title': 'Level Up! 🎉',
            'message': 'Congratulations! You reached level $newLevel!',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'level_up',
          });
        }
      }
    });
  }

  @override
  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
      AppLogger.i('User $blockedUserId blocked by $currentUserId');
    } catch (e, stack) {
      AppLogger.e('Error blocking user', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
      AppLogger.i('User $blockedUserId unblocked by $currentUserId');
    } catch (e, stack) {
      AppLogger.e('Error unblocking user', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? postId,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedId': reportedId,
        'reason': reason,
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      AppLogger.i('User $reportedId reported by $reporterId');
    } catch (e, stack) {
      AppLogger.e('Error reporting user', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> sendFriendRequest(String fromId, String toId) async {
    await _firestore.collection('users').doc(toId).update({
      'friendRequests': FieldValue.arrayUnion([fromId]),
    });
  }

  @override
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final friendRef = _firestore.collection('users').doc(friendId);

    batch.update(userRef, {
      'friends': FieldValue.arrayUnion([friendId]),
      'friendRequests': FieldValue.arrayRemove([friendId]),
    });
    batch.update(friendRef, {
      'friends': FieldValue.arrayUnion([userId]),
    });

    await batch.commit();

    await addXP(userId, 20);
    await addXP(friendId, 20);
  }

  @override
  Future<void> checkAndAwardBadges(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final user = UserModel.fromFirestore(userDoc);
    final currentBadges = List<String>.from(user.badges);
    final newBadges = <String>[];

    final results = await Future.wait([
      if (!currentBadges.contains('Early Bird'))
        _firestore
            .collection('daily_logs')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get()
      else
        Future.value(null),
      if (!currentBadges.contains('Step Master'))
        _firestore
            .collection('daily_logs')
            .where('userId', isEqualTo: userId)
            .get()
      else
        Future.value(null),
      if (!currentBadges.contains('Post Star'))
        _firestore
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .limit(5)
            .get()
      else
        Future.value(null),
      if (!currentBadges.contains('Aquaman') || !currentBadges.contains('Iron Will'))
        _firestore
            .collection('daily_logs')
            .where('userId', isEqualTo: userId)
            .get()
      else
        Future.value(null),
    ]);

    if (!currentBadges.contains('Early Bird')) {
      final logsSnap = results[0];
      if (logsSnap != null && (logsSnap as dynamic).docs.isNotEmpty) {
        newBadges.add('Early Bird');
      }
    }

    if (!currentBadges.contains('Social Butterfly')) {
      if (user.friends.length >= 5) newBadges.add('Social Butterfly');
    }

    if (!currentBadges.contains('Step Master')) {
      final logsSnap = results[1];
      if (logsSnap != null) {
        final hasStepMaster = (logsSnap as dynamic).docs.any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['steps'] ?? 0) >= 10000;
        });
        if (hasStepMaster) newBadges.add('Step Master');
      }
    }

    if (!currentBadges.contains('Post Star')) {
      final postsSnap = results[2];
      if (postsSnap != null && (postsSnap as dynamic).docs.length >= 5) {
        newBadges.add('Post Star');
      }
    }

    if (!currentBadges.contains('Aquaman') || !currentBadges.contains('Iron Will')) {
      final logsSnap = results.length > 3 ? results[3] : null;
      if (logsSnap != null) {
        final docs = (logsSnap as dynamic).docs;
        
        if (!currentBadges.contains('Aquaman')) {
           final hasAquaman = docs.any((doc) => ((doc.data() as Map<String, dynamic>)['waterGlasses'] ?? 0) >= 8);
           if (hasAquaman) newBadges.add('Aquaman');
        }

        if (!currentBadges.contains('Iron Will')) {
           int cleanDays = docs.where((doc) {
             final val = (doc.data() as Map<String, dynamic>)['cigarettes'];
             return val != null && val == 0;
           }).length;
           if (cleanDays >= 7) newBadges.add('Iron Will');
        }
      }
    }

    if (newBadges.isNotEmpty) {
      await userRef.update({'badges': FieldValue.arrayUnion(newBadges)});

      for (var badge in newBadges) {
        await _firestore.collection('notifications').add({
          'toUserId': userId,
          'fromUserId': 'system',
          'fromUserName': 'System',
          'type': 'badge_unlocked',
          'message': 'Congratulations! You unlocked the "$badge" badge!',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  @override
  Future<void> warnUser(String userId, String message) async {
    await _firestore.collection('users').doc(userId).update({
      'warningMessage': message,
    });
    await _firestore.collection('notifications').add({
      'toUserId': userId,
      'userId': userId,
      'title': 'Admin Warning ⚠️',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'warning',
    });
  }

  @override
  Future<void> banUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({'isBanned': true});
  }

  @override
  Future<void> unbanUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': false,
    });
  }

  @override
  Future<List<UserModel>> getTopUsersByXP({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
