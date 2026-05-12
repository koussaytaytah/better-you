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
import 'chat_room_screen.dart';

class MessagesInboxScreen extends ConsumerWidget {
  const MessagesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);
    final currentUser = ref.watch(currentUserProvider);
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
            'Messages',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: chatRoomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final sortedRooms = List<Map<String, dynamic>>.from(rooms)
            ..sort((a, b) {
              final t1 = (a['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
              final t2 = (b['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime(0);
              return t2.compareTo(t1);
            });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(chatRoomsProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedRooms.length,
              itemBuilder: (context, index) {
                final room = sortedRooms[index];
                return _buildChatCard(context, room, currentUser, isDark)
                    .animate()
                    .fadeIn(delay: (index * 40).ms)
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
              Icons.chat_bubble_outline,
              size: 48,
              color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with friends\nor your health professionals.',
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
            'Could not load messages',
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

  Widget _buildChatCard(
    BuildContext context,
    Map<String, dynamic> room,
    dynamic currentUser,
    bool isDark,
  ) {
    final lastTime = (room['lastMessageTime'] as Timestamp?)?.toDate();
    final isGroup = room['isGroup'] ?? false;
    final participants = List<String>.from(room['participants'] ?? []);
    final unreadCount = room['unreadCount'] ?? 0;

    String displayName = room['name'] ?? 'Chat';
    if (!isGroup && currentUser != null) {
      final otherId = participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );
      if (room['participantNames'] != null) {
        final names = Map<String, dynamic>.from(room['participantNames']);
        displayName = names[otherId] ?? displayName;
      }
    }

    final hasUnread = unreadCount > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: room['id'],
              roomName: displayName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.2)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isGroup
                        ? const LinearGradient(
                            colors: [Color(0xFF00A86B), Color(0xFF00D68A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isGroup
                        ? const Icon(Icons.group, color: Colors.white, size: 24)
                        : Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.text,
                          ),
                        ),
                      ),
                      if (lastTime != null)
                        Text(
                          _formatTime(lastTime),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: hasUnread
                                ? AppColors.primary
                                : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[500]),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room['lastMessage']?.isEmpty ?? true
                        ? 'No messages yet'
                        : room['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: hasUnread
                          ? (isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.text)
                          : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600]),
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date);
    }
    return DateFormat('MMM d').format(date);
  }
}
