import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

/// Watches the `/notifications` collection for the signed-in user and fires
/// a system notification (with sound) whenever a NEW unread doc arrives.
///
/// Free, requires no Cloud Functions or paid Firebase plan. Works while the
/// app is open or backgrounded but alive in memory.
class InAppNotificationListener {
  static final InAppNotificationListener _instance =
      InAppNotificationListener._internal();
  factory InAppNotificationListener() => _instance;
  InAppNotificationListener._internal();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _currentUserId;
  DateTime? _startedAt;
  final Set<String> _seenIds = <String>{};

  /// Start listening for notifications addressed to [userId]. Safe to call
  /// multiple times — re-subscribes if the user changed.
  Future<void> start(String userId) async {
    if (_currentUserId == userId && _sub != null) return;
    await stop();

    _currentUserId = userId;
    _startedAt = DateTime.now();
    _seenIds.clear();

    try {
      _sub = FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .snapshots()
          .listen(_onSnapshot, onError: (e) {
        AppLogger.e('InAppNotificationListener stream error', e);
      });
      AppLogger.i('InAppNotificationListener started for $userId');
    } catch (e) {
      AppLogger.e('Failed to start InAppNotificationListener', e);
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _currentUserId = null;
    _seenIds.clear();
  }

  Future<void> _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) async {
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final doc = change.doc;
      final id = doc.id;

      // Dedupe: skip if we've already processed this doc.
      if (_seenIds.contains(id)) continue;
      _seenIds.add(id);

      final data = doc.data();
      if (data == null) continue;

      // Skip already-read notifications (e.g., on initial connection).
      if (data['isRead'] == true) continue;

      // Skip historical docs that existed before listener started.
      final ts = (data['timestamp'] ?? data['createdAt']) as Timestamp?;
      if (ts != null && _startedAt != null && ts.toDate().isBefore(_startedAt!)) {
        continue;
      }

      // Don't notify the user about their own actions.
      final fromUserId = data['fromUserId'] as String?;
      if (fromUserId != null && fromUserId == _currentUserId) continue;

      final title = (data['title'] as String?) ?? 'New notification';
      final body = (data['body'] ?? data['message'] ?? '') as String;
      final type = (data['type'] as String?) ?? 'general';

      try {
        await NotificationService().showCustomNotification(
          id: id.hashCode,
          title: title,
          body: body,
          channelId: type,
          channelName: _channelNameFor(type),
        );
      } catch (e) {
        AppLogger.e('Failed to show local notification', e);
      }
    }
  }

  String _channelNameFor(String type) {
    switch (type) {
      case 'chat':
        return 'Messages';
      case 'friend_request':
        return 'Friend Requests';
      case 'booking':
        return 'Bookings';
      case 'prescription':
        return 'Prescriptions';
      case 'badge':
      case 'achievement':
        return 'Achievements';
      case 'level_up':
        return 'Level Up';
      case 'streak':
        return 'Streak Reminders';
      default:
        return 'General Notifications';
    }
  }
}
