import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/daily_log_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daily Logs
  Future<void> addDailyLog(DailyLog log) async {
    await _firestore
        .collection('daily_logs')
        .doc(log.id)
        .set(log.toFirestore());
  }

  Stream<List<DailyLog>> getUserDailyLogs(String userId) {
    return _firestore
        .collection('daily_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DailyLog.fromFirestore(doc)).toList(),
        );
  }

  // Posts
  Future<void> addPost(Post post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toFirestore());
  }

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (postDoc.exists) {
        final post = Post.fromFirestore(postDoc);
        final likes = List<String>.from(post.likes);
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        transaction.update(postRef, {'likes': likes});
      }
    });
  }

  // Messages
  Future<void> sendMessage(Message message) async {
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toFirestore());
  }

  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }
}
