import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/notification_settings_model.dart';
import '../utils/logger.dart';

class NotificationSettingsRepository {
  final FirebaseFirestore _firestore;

  NotificationSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _settingsCollection =>
      _firestore.collection('notificationSettings');

  Future<NotificationSettings> getSettings(String userId) async {
    try {
      final doc = await _settingsCollection.doc(userId).get();
      if (doc.exists) {
        return NotificationSettings.fromFirestore(doc);
      }
      
      // Return default settings if not found
      final defaultSettings = NotificationSettings(userId: userId);
      await saveSettings(defaultSettings);
      return defaultSettings;
    } catch (e, stack) {
      AppLogger.e('Error fetching notification settings', e, stack);
      return NotificationSettings(userId: userId);
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _settingsCollection
          .doc(settings.userId)
          .set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      AppLogger.e('Error saving notification settings', e, stack);
      throw Exception('Failed to save notification settings');
    }
  }

  Future<void> updateSetting(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await _settingsCollection.doc(userId).update({
        field: value,
      });
    } catch (e, stack) {
      AppLogger.e('Error updating notification setting', e, stack);
      throw Exception('Failed to update notification setting');
    }
  }

  Stream<NotificationSettings> watchSettings(String userId) {
    return _settingsCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return NotificationSettings.fromFirestore(doc);
          }
          return NotificationSettings(userId: userId);
        });
  }

  Future<void> deleteSettings(String userId) async {
    try {
      await _settingsCollection.doc(userId).delete();
    } catch (e, stack) {
      AppLogger.e('Error deleting notification settings', e, stack);
      throw Exception('Failed to delete notification settings');
    }
  }
}
