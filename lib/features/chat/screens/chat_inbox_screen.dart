import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/empty_state.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final roomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Haptic.tap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
        },
        child: const Icon(Icons.edit_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Messages', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                            roomsAsync.when(
                              data: (rooms) => Text('${rooms.length} conversation${rooms.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                              loading: () => const SizedBox.shrink(),
                              error: (e, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          roomsAsync.when(
            data: (rooms) {
              if (rooms.isEmpty) {
                return SliverFillRemaining(child: _buildEmpty(context));
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _RoomCard(room: rooms[index], currentUserId: user.uid, index: index),
                  childCount: rooms.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 12), child: ChatRoomSkeleton())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No conversations yet',
      message: 'Tap the pencil button to start a chat with a friend or create a group.',
      actionLabel: 'New chat',
      onAction: () {
        Haptic.tap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewChatScreen()),
        );
      },
    );
  }
}

class _RoomCard extends ConsumerWidget {
  final Map<String, dynamic> room;
  final String currentUserId;
  final int index;

  const _RoomCard({required this.room, required this.currentUserId, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = room['id'] as String;
    final participantNames = room['participantNames'] as Map<String, dynamic>? ?? {};
    final participantIds = List<String>.from(room['participants'] ?? []);
    final isGroup = room['isGroup'] == true;

    // Resolve display name
    String displayName = room['name'] ?? 'Chat';
    String? otherId;
    if (!isGroup) {
      otherId = participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
      displayName = participantNames[otherId] ?? displayName;
    }

    // Last message preview
    final lastMsg = room['lastMessage'] as String? ?? '';
    final lastTime = (room['lastMessageTime'] as Timestamp?)?.toDate();

    // Unread count
    final unreadAsync = ref.watch(unreadCountProvider((roomId, currentUserId)));
    final unread = unreadAsync.value ?? 0;

    // Online status for 1-1 chats
    final otherUserAsync = otherId != null && otherId.isNotEmpty
        ? ref.watch(userProvider(otherId))
        : null;
    final isOnline = otherUserAsync?.value?.isOnline ?? false;

    // Avatar initials + color
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final avatarColor = _colorFromName(displayName);

    return Dismissible(
      key: Key(roomId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.danger,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete chat?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            content: Text('This will remove the conversation for everyone.', style: GoogleFonts.inter()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(socialRepositoryProvider).deleteChatRoom(roomId);
      },
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatRoomScreen(roomId: roomId, roomName: displayName),
        )),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread > 0 ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            border: unread > 0 ? Border.all(color: AppColors.primary.withValues(alpha: 0.15)) : null,
          ),
          child: Row(
            children: [
              // Avatar with online dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: avatarColor.withValues(alpha: 0.15),
                    child: Text(initials, style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700, color: avatarColor)),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 1, right: 1,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Name + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.text,
                        )),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (lastMsg.startsWith('🎤'))
                        Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.mic, size: 13, color: Colors.grey[500]))
                      else if (lastMsg.startsWith('📷'))
                        Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.photo_camera, size: 13, color: Colors.grey[500]))
                      else if (lastMsg.isEmpty)
                        const SizedBox.shrink(),
                      Expanded(
                        child: Text(
                          lastMsg.isEmpty ? 'Started a conversation' : lastMsg,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: unread > 0 ? AppColors.text : AppColors.textLight,
                            fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Time + unread badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastTime != null)
                    Text(_formatTime(lastTime),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: unread > 0 ? AppColors.primary : Colors.grey[400],
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        )),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text('$unread',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    if (now.difference(date).inDays < 7) return DateFormat('EEE').format(date);
    return DateFormat('MMM d').format(date);
  }

  Color _colorFromName(String name) {
    final colors = [
      AppColors.primary, AppColors.secondary, AppColors.success,
      Colors.orange, Colors.purple, Colors.teal, Colors.indigo,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
