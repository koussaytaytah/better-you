import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/firestore_service.dart';
import '../models/daily_log_model.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// Daily Logs Provider
final dailyLogsProvider = StreamProvider.family<List<DailyLog>, String>((
  ref,
  userId,
) {
  return ref.watch(firestoreServiceProvider).getUserDailyLogs(userId);
});

// Posts Provider
final postsProvider = StreamProvider<List<Post>>((ref) {
  return ref.watch(firestoreServiceProvider).getPosts();
});

// Messages Provider
final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  roomId,
) {
  return ref.watch(firestoreServiceProvider).getMessages(roomId);
});
