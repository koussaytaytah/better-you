import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final n = notifs[index];
                return _buildNotificationTile(context, ref, n, isDark);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> n,
    bool isDark,
  ) {
    final timestamp =
        (n['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isRead = n['isRead'] ?? false;

    return Container(
      color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(_getIcon(n['type']), color: AppColors.primary, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.text,
              fontSize: 14,
            ),
            children: [
              TextSpan(
                text: n['fromUserName'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: _getMessage(n)),
            ],
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, HH:mm').format(timestamp),
          style: const TextStyle(fontSize: 10),
        ),
        onTap: () {
          ref.read(socialRepositoryProvider).markNotificationRead(n['id']);
          if (n['type'] == 'friend_request') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: n['fromUserId']),
              ),
            );
          } else if (n['postId'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: n['postId']),
              ),
            );
          } else if (n['type'] == 'badge_unlocked') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(
                  userId: ref.read(currentUserProvider)!.uid,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'friend_request':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _getMessage(Map<String, dynamic> n) {
    switch (n['type']) {
      case 'like':
        return ' liked your post.';
      case 'comment':
        return ' commented: "${n['message']}"';
      case 'friend_request':
        return ' sent you a friend request.';
      default:
        return ' sent you a notification.';
    }
  }
}
