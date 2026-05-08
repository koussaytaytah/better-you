import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/models/message_model.dart';
import '../../shared/models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../utils/logger.dart';
import 'user_repository.dart';

class SocialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CloudinaryService _cloudinary = CloudinaryService();
  // ignore: unused_field
  final UserRepository _userRepository;

  SocialRepository(this._userRepository);

  /// Try Cloudinary first (free 25 GB tier). Fall back to Firebase Storage
  /// only if Cloudinary isn't configured (so the app still works either way).
  Future<String?> uploadVocalMessage(String filePath, String roomId) async {
    if (_cloudinary.isConfigured) {
      final url = await _cloudinary.uploadAudio(
        filePath,
        folder: 'vocal_messages/$roomId',
      );
      if (url != null) return url;
    }
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref().child('vocal_messages/$roomId/$fileName');
      final uploadTask = await ref.putFile(File(filePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      AppLogger.e('Error uploading vocal message', e);
      return null;
    }
  }

  Future<String?> uploadChatImage(String filePath, String roomId) async {
    if (_cloudinary.isConfigured) {
      final url = await _cloudinary.uploadImage(
        filePath,
        folder: 'chat_images/$roomId',
      );
      if (url != null) return url;
    }
    try {
      final ext = filePath.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = _storage.ref().child('chat_images/$roomId/$fileName');
      final uploadTask = await ref.putFile(File(filePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      AppLogger.e('Error uploading chat image', e);
      return null;
    }
  }

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
        .snapshots()
        .map((snap) {
      final rooms = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      // Sort in-memory to avoid needing a composite index
      rooms.sort((a, b) {
        final aTime = (a['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (b['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      return rooms;
    });
  }

  Future<void> sendMessage(Message message) async {
    final batch = _firestore.batch();
    final messageRef = _firestore.collection('messages').doc(message.id);
    batch.set(messageRef, message.toFirestore());
    
    final roomRef = _firestore.collection('chat_rooms').doc(message.roomId);
    final preview = message.type == 'audio'
        ? '🎤 Voice Message'
        : message.type == 'image'
            ? '📷 Photo'
            : message.message;
    
    batch.set(roomRef, {
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          final msgs = snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
          msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return msgs;
        });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          list.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
          return list;
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

  // ==================== TYPING INDICATORS ====================

  Future<void> setTyping(String roomId, String userId, String userName, bool isTyping) async {
    final ref = _firestore.collection('chat_rooms').doc(roomId).collection('typing').doc(userId);
    if (isTyping) {
      await ref.set({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Stream<List<String>> getTypingUsers(String roomId, String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('typing')
        .snapshots()
        .map((snap) {
          return snap.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) => doc.data()['userName'] as String? ?? 'Someone')
              .toList();
        });
  }

  // ==================== READ RECEIPTS ====================

  Future<void> markMessagesAsRead(String roomId, String userId) async {
    final unreadMessages = await _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        batch.update(doc.reference, {'readBy': readBy});
      }
    }
    await batch.commit();
  }

  // ==================== REACTIONS ====================

  Future<void> addReaction(String messageId, String userId, String emoji) async {
    await _firestore.collection('messages').doc(messageId).update({
      'reactions.$userId': emoji,
    });
  }

  Future<void> removeReaction(String messageId, String userId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'reactions.$userId': FieldValue.delete(),
    });
  }

  // ==================== UNREAD COUNT ====================

  Stream<int> getUnreadCount(String roomId, String userId) {
    return _firestore
        .collection('messages')
        .where('roomId', isEqualTo: roomId)
        .where('senderId', isNotEqualTo: userId)
        .snapshots()
        .map((snap) {
          return snap.docs.where((doc) {
            final readBy = List<String>.from(doc.data()['readBy'] ?? []);
            return !readBy.contains(userId);
          }).length;
        });
  }

  // ==================== USER PROFILE ====================

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  Stream<List<UserModel>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
}
