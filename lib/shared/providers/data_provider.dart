import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/local_database_service.dart';
import '../../core/services/challenge_service.dart';

import '../../core/repositories/user_repository.dart';
import '../../core/repositories/user_repository_impl.dart';
import '../../core/repositories/post_repository.dart';
import '../../core/repositories/daily_log_repository.dart';
import '../../core/repositories/social_repository.dart';
import '../../core/repositories/quest_repository.dart';

import '../models/daily_log_model.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';
import '../models/quest_model.dart';
import '../models/user_model.dart';

final aiServiceProvider = Provider((ref) => AIService());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(userRepositoryProvider));
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository(ChallengeService(), LocalDatabaseService());
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(userRepositoryProvider));
});

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  return QuestRepository();
});

// Quests Provider
final questsProvider = StreamProvider<List<Quest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(questRepositoryProvider).getUserQuests(user.uid);
});

// Daily Log for specific day Provider
final dailyLogForDateProvider = StreamProvider.family<DailyLog?, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  return ref.watch(dailyLogRepositoryProvider).getDailyLog(user.uid, normalizedDate);
});

// Today's Log Provider
final todayLogProvider = StreamProvider<DailyLog?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(dailyLogRepositoryProvider).getDailyLog(user.uid, today);
});

// Daily Logs Provider
final dailyLogsProvider = StreamProvider.family<List<DailyLog>, String>((ref, userId) {
  return ref.watch(dailyLogRepositoryProvider).getUserDailyLogs(userId);
});

// Posts Provider
final postsProvider = StreamProvider<List<Post>>((ref) {
  return ref.watch(postRepositoryProvider).getPosts();
});

// Messages Provider
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  return ref.watch(socialRepositoryProvider).getMessages(roomId);
});

// Comments Provider
final commentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).getComments(postId);
});

// User Provider
final userProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => UserModel.fromFirestore(doc));
});

// Last 7 Days Logs
final last7DaysLogsProvider = StreamProvider<List<DailyLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  
  return FirebaseFirestore.instance
      .collection('daily_logs')
      .where('userId', isEqualTo: user.uid)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) {
        return snap.docs
            .map((doc) => DailyLog.fromFirestore(doc))
            .toList();
      });
});

final dailyAIInsightProvider = FutureProvider<String>((ref) async {
  final log = await ref.watch(todayLogProvider.future);
  final user = ref.read(currentUserProvider);
  final aiService = ref.read(aiServiceProvider);

  if (log == null || user == null) return "Start logging to get AI insights!";

  return aiService.getAIResponse(
    "Analyze my today's health stats and provide a single, encouraging sentence or tip.",
    user: user,
    todayLog: log,
  );
});

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialRepositoryProvider).getNotifications(user.uid);
});

final friendRequestsProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialRepositoryProvider).getFriendRequests(user.uid);
});

final postProvider = StreamProvider.family<Post?, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? Post.fromFirestore(doc) : null);
});

final userPostsProvider = StreamProvider.family<List<Post>, String>((ref, userId) {
  return ref.watch(postRepositoryProvider).getUserPosts(userId);
});

final chatRoomsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(socialRepositoryProvider).getChatRooms(user.uid);
});

final reportsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(socialRepositoryProvider).getReports();
});

final allUsersAsyncProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(userRepositoryProvider).searchUsers('');
});

final topUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(userRepositoryProvider).getTopUsersByXP(limit: 50);
});
