import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

import 'package:intl/intl.dart';
import '../../chat/screens/chat_room_screen.dart';
import 'post_detail_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          if (currentUser != null && currentUser.uid != userId)
            IconButton(
              icon: const Icon(Icons.report_outlined),
              onPressed: () =>
                  _showReportDialog(context, ref, currentUser.uid, userId),
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) =>
            _buildProfileContent(context, ref, user, currentUser, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    UserModel? currentUser,
    bool isDark,
  ) {
    final isFriend = currentUser?.friends.contains(user.uid) ?? false;
    final hasSentRequest =
        currentUser != null && user.friendRequests.contains(currentUser.uid);
    final isMe = currentUser?.uid == user.uid;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProvider(user.uid));
        ref.invalidate(userPostsProvider(user.uid));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 40,
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: _getRankGradient(user.getRankName()),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _getRankColor(user.getRankName()).withValues(alpha: 0.4), blurRadius: 8),
                ],
              ),
              child: Text(
                user.getRankName().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isMe)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isFriend && !hasSentRequest)
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (currentUser != null) {
                          try {
                            // Update other user's friendRequests
                            await ref
                                .read(userRepositoryProvider)
                                .sendFriendRequest(currentUser.uid, user.uid);

                            // Also update current user's locally or trigger a reload
                            // In a real app, we might want a 'sentRequests' field in UserModel

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Friend request sent!'),
                                ),
                              );
                            }
                            ref.invalidate(userProvider(user.uid));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                    )
                  else if (hasSentRequest)
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('Request Sent'),
                    )
                  else if (isFriend)
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Friends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (user.role == UserRole.doctor ||
                      user.role == UserRole.coach ||
                      currentUser?.role == UserRole.doctor ||
                      currentUser?.role == UserRole.coach)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (user.role == UserRole.doctor ||
                            user.role == UserRole.coach) {
                          if (currentUser != null && !currentUser.isPremium) {
                            _showPremiumUpgradeDialog(context, ref);
                            return;
                          }
                        }
                        _createPrivateRoom(context, ref, currentUser!, user);
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Consult'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 32),
            _buildInfoSection(context, user, isDark),
            const SizedBox(height: 24),
            _buildBadgesSection(context, user, isDark),
            const SizedBox(height: 32),
            _buildUserPosts(context, ref, user.uid, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, UserModel user, bool isDark) {
    if (user.badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Trophy Case',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: user.badges.length,
          itemBuilder: (context, index) {
            final badge = user.badges[index];
            final iconData = _getBadgeConfig(badge);
            
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconData.color.withValues(alpha: 0.2),
                    iconData.color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: iconData.color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconData.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData.icon, color: iconData.color, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    badge,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserPosts(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool isDark,
  ) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) return const Center(child: Text('No posts yet'));
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post.id),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).cardColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                post.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM d, HH:mm').format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading posts: $err'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, UserModel user, bool isDark) {
    final nextLevelXp = user.level * 1000;
    final progress = user.xp / nextLevelXp;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level ${user.level}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${user.xp} / $nextLevelXp XP', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
              Icon(Icons.military_tech, size: 48, color: _getRankColor(user.getRankName())),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(_getRankColor(user.getRankName())),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined Better You', DateFormat('MMMM yyyy').format(user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return Colors.blue;
      case UserRole.coach:
        return Colors.orange;
      case UserRole.admin:
        return Colors.red;
      case UserRole.user:
      case UserRole.initial:
        return AppColors.primary;
    }
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFB4B4B4);
      case 'gold': return const Color(0xFFFFD700);
      case 'platinum': return const Color(0xFFE5E4E2);
      case 'diamond': return const Color(0xFFb9f2ff);
      case 'master': return const Color(0xFFFF4081);
      default: return AppColors.primary;
    }
  }

  LinearGradient _getRankGradient(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8C5622)]);
      case 'silver': return const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]);
      case 'gold': return const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)]);
      case 'platinum': return const LinearGradient(colors: [Color(0xFFE5E4E2), Color(0xFF9E9E9E)]);
      case 'diamond': return const LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFF007FFF)]);
      case 'master': return const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFE040FB)]);
      default: return const LinearGradient(colors: [AppColors.primary, Colors.teal]);
    }
  }

  _BadgeConfig _getBadgeConfig(String badge) {
    if (badge.contains('Aquaman')) return _BadgeConfig(Icons.water_drop, Colors.blue);
    if (badge.contains('Iron Will')) return _BadgeConfig(Icons.smoke_free, Colors.redAccent);
    if (badge.contains('Step Master')) return _BadgeConfig(Icons.directions_walk, Colors.green);
    if (badge.contains('Early Bird')) return _BadgeConfig(Icons.wb_sunny, Colors.orange);
    if (badge.contains('Post Star')) return _BadgeConfig(Icons.star, Colors.amber);
    return _BadgeConfig(Icons.emoji_events, AppColors.primary);
  }

  void _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    String reporterId,
    String reportedId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              await ref
                  .read(userRepositoryProvider).reportUser(
                    reporterId: reporterId,
                    reportedId: reportedId,
                    reason: reason,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text('Premium Feature'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Consultations with Doctors and Coaches are available to Premium members.',
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.restaurant, color: AppColors.primary),
              title: Text('AI Food & Nutrients Detection'),
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: AppColors.primary),
              title: Text('Direct Doctor Consultation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(userRepositoryProvider).updateUserProfile(
                  user.uid,
                  {'isPremium': true},
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Welcome to Premium! 🚀'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPrivateRoom(
    BuildContext context,
    WidgetRef ref,
    UserModel currentUser,
    UserModel otherUser,
  ) async {
    final roomId = await ref
        .read(socialRepositoryProvider)
        .createChatRoom(
          [currentUser.uid, otherUser.uid],
          'Private Consultation',
          isGroup: false,
          participantNames: {
            currentUser.uid: currentUser.name,
            otherUser.uid: otherUser.name,
          },
        );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatRoomScreen(roomId: roomId, roomName: otherUser.name),
        ),
      );
    }
  }
}

class _BadgeConfig {
  final IconData icon;
  final Color color;
  _BadgeConfig(this.icon, this.color);
}
