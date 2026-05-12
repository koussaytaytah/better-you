import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'chat_room_screen.dart';

/// Pick one or more friends and start a 1-on-1 or group chat.
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _selected = <String, UserModel>{};
  final _groupNameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<List<UserModel>> _loadFriends(UserModel currentUser) async {
    if (currentUser.friends.isEmpty) return [];
    // Firestore `whereIn` is capped at 30; chunk if needed.
    final ids = currentUser.friends.toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 30) {
      chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
    }
    final results = <UserModel>[];
    for (final chunk in chunks) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(snap.docs.map(UserModel.fromFirestore));
    }
    // Filter out blocked users
    final blocked = currentUser.blockedUsers.toSet();
    return results.where((u) => !blocked.contains(u.uid)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _create(UserModel currentUser) async {
    HapticFeedback.mediumImpact();
    if (_selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final isGroup = _selected.length > 1;
      final participantIds = [currentUser.uid, ..._selected.keys];
      final participantNames = <String, String>{
        currentUser.uid: currentUser.name,
        for (final u in _selected.values) u.uid: u.name,
      };

      String roomName;
      if (isGroup) {
        roomName = _groupNameController.text.trim().isEmpty
            ? _selected.values.map((u) => u.name.split(' ').first).join(', ')
            : _groupNameController.text.trim();
      } else {
        roomName = _selected.values.first.name;
      }

      final repo = ref.read(socialRepositoryProvider);
      final roomId = await repo.createChatRoom(
        participantIds,
        roomName,
        isGroup: isGroup,
        participantNames: participantNames,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(roomId: roomId, roomName: roomName),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isGroup = _selected.length > 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
            _selected.isEmpty ? 'New Chat' : '${_selected.length} selected',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isGroup)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group name (optional)',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _selected.length,
                itemBuilder: (_, i) {
                  final u = _selected.values.elementAt(i);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary,
                              backgroundImage: u.profileImageUrl != null && u.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(u.profileImageUrl!)
                                  : null,
                              child: (u.profileImageUrl == null || u.profileImageUrl!.isEmpty)
                                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(u.name.split(' ').first,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                        Positioned(
                          top: -4, right: -4,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selected.remove(u.uid));
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('Friends',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Text('${currentUser.friends.length} total',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _loadFriends(currentUser),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friends = snap.data ?? const <UserModel>[];
                if (friends.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No friends yet',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Add friends to start group chats',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: friends.length,
                  separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final f = friends[i];
                    final selected = _selected.containsKey(f.uid);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (v == true) {
                            _selected[f.uid] = f;
                          } else {
                            _selected.remove(f.uid);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppColors.primary,
                      secondary: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: f.profileImageUrl != null && f.profileImageUrl!.isNotEmpty
                            ? NetworkImage(f.profileImageUrl!)
                            : null,
                        child: (f.profileImageUrl == null || f.profileImageUrl!.isEmpty)
                            ? Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                            : null,
                      ),
                      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(f.role.name.toUpperCase(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _creating ? null : () => _create(currentUser),
              icon: _creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(isGroup ? 'Create group' : 'Start chat'),
            ),
    );
  }
}
