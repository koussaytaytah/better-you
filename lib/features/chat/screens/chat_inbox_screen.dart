import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/repositories/social_repository.dart';
import 'chat_room_screen.dart';
import 'package:intl/intl.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final socialRepo = ref.read(socialRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: socialRepo.getChatRooms(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final rooms = snapshot.data ?? [];
          
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hire a Professional to start chatting.',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final participantsInfo = room['participantNames'] as Map<String, dynamic>? ?? {};
              
              // Find the other person's name
              String otherPersonName = 'Unknown';
              participantsInfo.forEach((key, value) {
                if (key != user.uid) {
                  otherPersonName = value.toString();
                }
              });

              final lastMessage = room['lastMessage'] as String? ?? '';
              final time = room['lastMessageTime'];
              String timeStr = '';
              if (time != null) {
                final dt = time.toDate();
                timeStr = DateFormat('MMM d, h:mm a').format(dt);
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    otherPersonName.isNotEmpty ? otherPersonName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  otherPersonName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage.isEmpty ? 'Started a conversation' : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  timeStr,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        roomId: room['id'] as String,
                        roomName: otherPersonName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
