import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/post_model.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';
import 'user_repository.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository;

  PostRepository(this._userRepository);

  Future<void> addPost(Post post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toFirestore());
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      AppLogger.i('Post $postId deleted');
    } catch (e, stack) {
      AppLogger.e('Error deleting post', e, stack);
      rethrow;
    }
  }

  Future<String?> uploadPostImage(XFile imageFile, String postId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child('$postId.jpg');

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final uploadTask = ref.putFile(File(imageFile.path));
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e, stack) {
      AppLogger.e('Error uploading post image', e, stack);
      return null;
    }
  }

  Stream<List<Post>> getPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Post>> getUserPosts(String userId, {int limit = 20}) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  Future<void> addCommentWithNotify({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    required String postOwnerId,
  }) async {
    final batch = _firestore.batch();
    final commentRef = _firestore.collection('comments').doc();
    batch.set(commentRef, {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();

    if (userId != postOwnerId) {
      await _firestore.collection('notifications').add({
        'toUserId': postOwnerId,
        'fromUserId': userId,
        'fromUserName': userName,
        'type': 'comment',
        'postId': postId,
        'message': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  Future<void> likePost(
    String postId,
    String userId,
    String userName,
    String postOwnerId,
  ) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final doc = await postRef.get();
    final likes = List<String>.from(doc.data()?['likes'] ?? []);

    if (likes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
      
      await _userRepository.addXP(userId, 5);
      await _userRepository.checkAndAwardBadges(userId);

      if (userId != postOwnerId) {
        await _firestore.collection('notifications').add({
          'toUserId': postOwnerId,
          'fromUserId': userId,
          'fromUserName': userName,
          'type': 'like',
          'postId': postId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }
}
