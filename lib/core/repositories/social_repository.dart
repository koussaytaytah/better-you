import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/user_model.dart';
import '../utils/logger.dart';
import 'user_repository.dart';

class SocialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  SocialRepository(this._userRepository);

  Future<String> createChatRoom(
    List<String> participants,
    String name, {
    bool isGroup = false,
    Map<String, String>? participantNames,
  }) async {
    final roomRef = await _firestore.collection('chat_rooms').add({
      'participants': participants,
      'name': name,
      'isGroup': isGroup,
      'participantNames': participantNames,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  Future<void> deleteChatRoom(String roomId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .get();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chat_rooms').doc(roomId));
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  Future<void> sendMessage(Message message) async {
    final batch = _firestore.batch();
    final messageRef = _firestore.collection('messages').doc(message.id);
    batch.set(messageRef, message.toFirestore());
    final roomRef = _firestore.collection('chat_rooms').doc(message.roomId);
    batch.update(roomRef, {
      'lastMessage': message.message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Stream<List<UserModel>> getFriendRequests(String userId) {
    return _firestore
        .collection('users')
        .where('friendRequests', arrayContains: userId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  Future<void> resolveReport(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
