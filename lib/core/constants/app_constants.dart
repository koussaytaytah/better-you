import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Better You';
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.3-70b-versatile';
  static String get groqToken => dotenv.env['GROQ_TOKEN'] ?? '';
  static String get geminiToken => dotenv.env['GEMINI_TOKEN'] ?? '';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String dailyLogsCollection = 'daily_logs';
  static const String weeklyProgressCollection = 'weekly_progress';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String messagesCollection = 'messages';
  static const String chatRoomsCollection = 'chat_rooms';
  static const String notificationsCollection = 'notifications';
  static const String badgesCollection = 'badges';

  // User roles
  static const String roleUser = 'user';
  static const String roleCoach = 'coach';
  static const String roleDoctor = 'doctor';

  // Quests for Screen Time Lock
  static const List<String> defaultQuests = [
    '10 Pushups',
    '20 Sit-ups',
    'Drink 2 Glasses of Water',
    '1 Minute Plank',
    'Walk 500 Steps',
    'Read 5 Pages of a Book',
  ];
}
