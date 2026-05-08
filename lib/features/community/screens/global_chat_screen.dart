import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

class GlobalChatScreen extends ConsumerStatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _optimisticMessages = [];
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final message = Message(
      id: const Uuid().v4(),
      roomId: 'global',
      senderId: user.uid,
      senderName: user.name,
      senderRole: user.role.name,
      message: text,
      timestamp: DateTime.now(),
    );

    // Optimistic UI: add locally immediately
    setState(() {
      _optimisticMessages.add(message);
      _isSending = true;
    });
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await ref.read(socialRepositoryProvider).sendMessage(message);
      // Remove from optimistic list — Firestore stream will add it back
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == message.id);
        });
      }
    } catch (e) {
      // On failure: remove optimistic msg and show error
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == message.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message. Try again.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider('global'));
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarHeight = 94.0 + MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0F24),
                  const Color(0xFF1A112A),
                  const Color(0xFF0A0F24),
                ]
              : [
                  const Color(0xFFF4F7FF),
                  const Color(0xFFF3E8FF),
                  const Color(0xFFE0F7F4),
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Global Chat',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (firestoreMessages) {
                  // Merge Firestore messages with any pending optimistic ones
                  final firestoreIds = firestoreMessages.map((m) => m.id).toSet();
                  final pending = _optimisticMessages
                      .where((m) => !firestoreIds.contains(m.id))
                      .toList();
                  final allMessages = [...firestoreMessages, ...pending]
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (allMessages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 56,
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No messages yet. Say hi! 👋',
                              style: TextStyle(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.4))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: allMessages.length,
                    itemBuilder: (context, index) {
                      final message = allMessages[index];
                      final isMe = message.senderId == currentUser?.uid;
                      final isPending =
                          _optimisticMessages.any((m) => m.id == message.id);
                      return _buildMessage(message, isMe, isDark,
                          isPending: isPending);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text('Could not load messages',
                          style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(messagesProvider('global')),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Input area — sits above the nav bar
            _buildInputArea(context, isDark, bottomInset, navBarHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message message, bool isMe, bool isDark,
      {bool isPending = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isPending ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(message.senderRole),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getRoleColor(message.senderRole)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.senderRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(message.senderRole),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.text),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: (isDark ? Colors.white : AppColors.text)
                        .withValues(alpha: 0.4),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: (isDark ? Colors.white : AppColors.text)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'coach':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildInputArea(BuildContext context, bool isDark, double bottomInset,
      double navBarHeight) {
    final bottomPad = bottomInset > 0 ? bottomInset + 8.0 : navBarHeight;
    return Container(
      padding:
          EdgeInsets.only(left: 16, right: 8, top: 8, bottom: bottomPad),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.text, fontSize: 15),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message everyone...',
                hintStyle: TextStyle(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.35)),
                border: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 4),
          _isSending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
        ],
      ),
    );
  }
}
