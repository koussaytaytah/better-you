class AppConstants {
  static const String appName = 'Better You';
  static const String huggingFaceApiUrl =
      'https://api-inference.huggingface.co/models/';
  static const String huggingFaceModel = 'microsoft/DialoGPT-medium';
  static const String huggingFaceToken =
      'YOUR_HUGGING_FACE_TOKEN'; // Replace with actual token

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
}
