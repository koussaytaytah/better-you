import '../../shared/models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUser(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);
  Future<void> addXP(String userId, int amount);
  Stream<List<UserModel>> searchUsers(String query);
  Future<void> blockUser(String currentUserId, String blockedUserId);
  Future<void> unblockUser(String currentUserId, String blockedUserId);
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? postId,
  });
  Future<void> sendFriendRequest(String fromId, String toId);
  Future<void> acceptFriendRequest(String userId, String friendId);
  Future<void> checkAndAwardBadges(String userId);
  Future<void> warnUser(String userId, String message);
  Future<List<UserModel>> getTopUsersByXP({int limit = 50});
  Future<void> banUser(String userId);
  Future<void> unbanUser(String userId);
  Future<void> awardBadge(String userId, String badgeName);
}
