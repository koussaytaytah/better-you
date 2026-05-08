import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/haptic_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/audio_message_bubble.dart';

final typingUsersProvider = StreamProvider.family<List<String>, (String, String)>((ref, params) {
  final (roomId, userId) = params;
  return ref.read(socialRepositoryProvider)
      .getTypingUsers(roomId, userId);
});

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastRecordingPath;
  bool _isTyping = false;
  Message? _replyToMessage;
  String? _lastSeenMessageId;
  bool _initialMessagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTypingChanged);
    // Mark messages as read when opening the room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(socialRepositoryProvider).markMessagesAsRead(widget.roomId, user.uid);
      }
    });
  }

  void _maybePlayReceiveSound(List<Message> messages, String currentUserId) {
    if (messages.isEmpty) return;
    final latest = messages.last;
    // Skip the first batch on screen open; only react to truly new arrivals.
    if (!_initialMessagesLoaded) {
      _initialMessagesLoaded = true;
      _lastSeenMessageId = latest.id;
      return;
    }
    if (latest.id != _lastSeenMessageId && latest.senderId != currentUserId) {
      _lastSeenMessageId = latest.id;
      SoundService().play(AppSound.messageReceived);
      // Auto-mark new messages as read since the room is open
      ref.read(socialRepositoryProvider).markMessagesAsRead(widget.roomId, currentUserId);
    } else {
      _lastSeenMessageId = latest.id;
    }
  }

  void _onTypingChanged() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final isNowTyping = _messageController.text.trim().isNotEmpty;
    if (isNowTyping != _isTyping) {
      _isTyping = isNowTyping;
      ref.read(socialRepositoryProvider).setTyping(widget.roomId, user.uid, user.name, _isTyping);
    }
  }

  @override
  void dispose() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(socialRepositoryProvider).setTyping(widget.roomId, user.uid, user.name, false);
    }
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        _lastRecordingPath = '${directory.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';
        const config = RecordConfig();
        await _audioRecorder.start(config, path: _lastRecordingPath!);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendVocalMessage(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _sendVocalMessage(String path) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final url = await ref.read(socialRepositoryProvider).uploadVocalMessage(path, widget.roomId);
    if (url == null) return;

    final message = Message(
      id: const Uuid().v4(),
      roomId: widget.roomId,
      senderId: user.uid,
      senderName: user.name,
      senderRole: user.role.name,
      message: 'Voice Message',
      timestamp: DateTime.now(),
      type: 'audio',
      mediaUrl: url,
    );

    await ref.read(socialRepositoryProvider).sendMessage(message);
    // Cleanup local file
    try {
      File(path).delete();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final message = Message(
      id: const Uuid().v4(),
      roomId: widget.roomId,
      senderId: user.uid,
      senderName: user.name,
      senderRole: user.role.name,
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
      replyToId: _replyToMessage?.id,
      replyToText: _replyToMessage?.message,
    );

    await ref.read(socialRepositoryProvider).sendMessage(message);
    _messageController.clear();
    setState(() => _replyToMessage = null);
    SoundService().play(AppSound.messageSent);
    Haptic.tap();

    _notifyOtherParticipants(user.uid, user.name, message.message);
  }

  Future<void> _sendImage() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take photo', style: GoogleFonts.inter()),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
                if (ctx.mounted) Navigator.pop(ctx, f);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from gallery', style: GoogleFonts.inter()),
              onTap: () async {
                final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
                if (ctx.mounted) Navigator.pop(ctx, f);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null) return;

    // Show optimistic snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo…'), duration: Duration(seconds: 2)),
      );
    }

    final url = await ref.read(socialRepositoryProvider).uploadChatImage(picked.path, widget.roomId);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final message = Message(
      id: const Uuid().v4(),
      roomId: widget.roomId,
      senderId: user.uid,
      senderName: user.name,
      senderRole: user.role.name,
      message: '',
      timestamp: DateTime.now(),
      type: 'image',
      mediaUrl: url,
      replyToId: _replyToMessage?.id,
      replyToText: _replyToMessage?.message,
    );

    await ref.read(socialRepositoryProvider).sendMessage(message);
    if (mounted) setState(() => _replyToMessage = null);
    SoundService().play(AppSound.messageSent);
    Haptic.success();
    _notifyOtherParticipants(user.uid, user.name, '📷 Photo');
  }

  void _openImageViewer(String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  Future<void> _notifyOtherParticipants(String senderId, String senderName, String preview) async {
    try {
      final roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).get();
      final participants = List<String>.from(roomDoc.data()?['participants'] ?? []);
      for (final participantId in participants) {
        if (participantId != senderId) {
          FCMService().sendNotificationToUser(
            toUserId: participantId,
            fromUserId: senderId,
            fromUserName: senderName,
            type: 'chat',
            title: senderName,
            body: preview.length > 80 ? '${preview.substring(0, 80)}…' : preview,
            data: {'roomId': widget.roomId, 'roomName': widget.roomName, 'screen': 'chat'},
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch typing users
    final typingUsersAsync = ref.watch(typingUsersProvider((widget.roomId, user?.uid ?? '')));
    final typingUsers = typingUsersAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Text(
                    widget.roomName.isNotEmpty ? widget.roomName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                // Online presence — re-uses typingUsers as proxy for activity
                if (typingUsers.isNotEmpty)
                  const Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(radius: 5, backgroundColor: Colors.greenAccent),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.roomName, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (typingUsers.isNotEmpty)
                    Text(
                      '${typingUsers.join(', ')} typing...',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms)
                  else
                    Text('tap to view info', style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (user?.role == UserRole.doctor || user?.role == UserRole.coach)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDeleteRoom(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final chronological = List<Message>.from(messages)
                  ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                if (user != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _maybePlayReceiveSound(chronological, user.uid);
                  });
                }
                final sortedMessages = List<Message>.from(messages)
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: sortedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = sortedMessages[index];
                    return _buildMessage(
                      msg,
                      msg.senderId == user?.uid,
                      isDark,
                      user?.uid ?? '',
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          if (_replyToMessage != null)
            _buildReplyBar(isDark),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildReplyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Row(
        children: [
          Container(width: 3, height: 36, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.senderName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                Text(
                  _replyToMessage!.type == 'audio' ? '🎤 Voice Message' : _replyToMessage!.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyToMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message, bool isMe, bool isDark, String currentUserId) {
    final isRead = message.readBy.isNotEmpty && !message.readBy.every((id) => id == message.senderId);
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isMe, currentUserId),
      onDoubleTap: () => _quickReact(message, currentUserId, '❤️'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(message.senderRole),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getRoleColor(message.senderRole).withValues(alpha: 0.1),
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
            if (message.replyToText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                ),
                child: Text(
                  message.replyToText!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.type == 'audio' && message.mediaUrl != null
                  ? AudioMessageBubble(url: message.mediaUrl!, isMe: isMe)
                  : (message.type == 'image' && message.mediaUrl != null)
                      ? GestureDetector(
                          onTap: () => _openImageViewer(message.mediaUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
                              child: Image.network(
                                message.mediaUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (c, child, p) => p == null
                                    ? child
                                    : const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                errorBuilder: (_, e, s) => const SizedBox(width: 100, height: 100, child: Icon(Icons.broken_image, color: Colors.white)),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.text),
                          ),
                        ),
            ),
            // Reactions
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: _buildReactionChips(message, currentUserId),
                ),
              ),
            // Read receipt + timestamp
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  if (isMe) ...([
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: isRead ? AppColors.primary : Colors.grey[400],
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactionChips(Message message, String currentUserId) {
    final grouped = <String, int>{};
    for (final emoji in message.reactions.values) {
      grouped[emoji] = (grouped[emoji] ?? 0) + 1;
    }
    return grouped.entries.map((entry) {
      final myReaction = message.reactions[currentUserId] == entry.key;
      return GestureDetector(
        onTap: () {
          if (myReaction) {
            ref.read(socialRepositoryProvider).removeReaction(message.id, currentUserId);
          } else {
            ref.read(socialRepositoryProvider).addReaction(message.id, currentUserId, entry.key);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: myReaction
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: myReaction ? Border.all(color: AppColors.primary) : null,
          ),
          child: Text('${entry.key} ${entry.value}', style: const TextStyle(fontSize: 12)),
        ),
      );
    }).toList();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(Message message, bool isMe, String currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '👍', '😮', '😢', '🔥'].map((emoji) {
                  final isSelected = message.reactions[currentUserId] == emoji;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (isSelected) {
                        ref.read(socialRepositoryProvider).removeReaction(message.id, currentUserId);
                      } else {
                        ref.read(socialRepositoryProvider).addReaction(message.id, currentUserId, emoji);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyToMessage = message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _quickReact(Message message, String currentUserId, String emoji) {
    final existing = message.reactions[currentUserId];
    if (existing == emoji) {
      ref.read(socialRepositoryProvider).removeReaction(message.id, currentUserId);
    } else {
      ref.read(socialRepositoryProvider).addReaction(message.id, currentUserId, emoji);
    }
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

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                   if (_isRecording)
                    ...[1, 2, 3].map((i) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(
                        duration: 1200.ms,
                        delay: (400 * i).ms,
                        begin: const Offset(1, 1),
                        end: const Offset(2.5, 2.5),
                        curve: Curves.easeOut,
                      ).fadeOut()),
                  GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressUp: _stopRecording,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        color: _isRecording ? Colors.white : AppColors.primary,
                      ),
                    ).animate(target: _isRecording ? 1 : 0).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: 300.ms,
                        ),
                  ),
                ],
              ),
              if (!_isRecording)
                IconButton(
                  onPressed: _sendImage,
                  icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                  tooltip: 'Send photo',
                ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_isRecording,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.text),
                  decoration: InputDecoration(
                    hintText: _isRecording ? 'Recording...' : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? Colors.white.withValues(alpha: 0.05) 
                        : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              if (!_isRecording && _messageController.text.trim().isNotEmpty)
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
            ],
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   ...[0.4, 0.7, 1.0, 0.7, 0.4].map((h) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 20 * h,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(
                    begin: 0.5,
                    end: 1.5,
                    duration: 400.ms,
                    curve: Curves.easeInOut,
                  )),
                  const SizedBox(width: 12),
                  Text(
                    'Recording... Release to send',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Room?'),
        content: const Text('This will delete the conversation for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await ref
                  .read(socialRepositoryProvider)
                  .deleteChatRoom(widget.roomId);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (navigator.context.mounted) {
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
