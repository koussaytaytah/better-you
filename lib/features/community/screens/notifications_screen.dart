import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              width: 1,
            ),
          ),
          child: Text(
            'Notifications',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: const [],
      ),
      body: notificationsAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                final n = notifs[index];
                return _buildNotificationCard(context, ref, n, isDark)
                    .animate()
                    .fadeIn(delay: (index * 50).ms)
                    .moveY(begin: 10);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(err, isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone likes, comments, or follows you,\nit will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic err, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Could not load notifications',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> n,
    bool isDark,
  ) {
    final timestamp = (n['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isRead = n['isRead'] ?? false;
    final type = n['type'] ?? 'default';
    final iconColor = _getIconColor(type);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(socialRepositoryProvider).markNotificationRead(n['id']);
        _handleNotificationTap(context, ref, n);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
              : iconColor.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1))
                : iconColor.withValues(alpha: 0.2),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(type), color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.text,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: n['fromUserName'] ?? 'Someone',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: _getMessage(n)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[500],
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, Map<String, dynamic> n) {
    final type = n['type'];
    if (type == 'friend_request') {
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
    } else if (type == 'badge_unlocked') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: ref.read(currentUserProvider)!.uid,
          ),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return 'm ago';
    if (diff.inDays < 1) return 'h ago';
    if (diff.inDays < 7) return 'd ago';
    return DateFormat('MMM d').format(time);
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'like': return const Color(0xFFE91E63);
      case 'comment': return const Color(0xFF2196F3);
      case 'friend_request': return const Color(0xFF4CAF50);
      case 'badge_unlocked': return const Color(0xFFFF9800);
      default: return AppColors.primary;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite_rounded;
      case 'comment': return Icons.chat_bubble_rounded;
      case 'friend_request': return Icons.person_add_rounded;
      case 'badge_unlocked': return Icons.emoji_events_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _getMessage(Map<String, dynamic> n) {
    switch (n['type']) {
      case 'like':
        return ' liked your post.';
      case 'comment':
        return ' commented: ""';
      case 'friend_request':
        return ' sent you a friend request.';
      case 'badge_unlocked':
        return ' You earned a new badge!';
      default:
        return ' sent you a notification.';
    }
  }
}
