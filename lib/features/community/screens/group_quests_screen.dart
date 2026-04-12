import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/group_quest_model.dart';
import '../../../shared/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final groupQuestsProvider = StreamProvider<List<GroupQuest>>((ref) {
  return FirebaseFirestore.instance
      .collection('group_quests')
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((doc) => GroupQuest.fromFirestore(doc)).toList(),
      );
});

class GroupQuestsScreen extends ConsumerWidget {
  const GroupQuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupQuestsAsync = ref.watch(groupQuestsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Group Quests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGroupQuestDialog(context, ref),
          ),
        ],
      ),
      body: groupQuestsAsync.when(
        data: (quests) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            final isJoined =
                currentUser != null &&
                quest.participantIds.contains(currentUser.uid);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            quest.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quest.description,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${quest.participantIds.length} participants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Goal: ${quest.goalDays} days',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleJoinLeaveQuest(
                          context,
                          ref,
                          quest,
                          isJoined,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isJoined
                              ? Colors.grey
                              : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isJoined ? 'Leave Group' : 'Join Group'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showCreateGroupQuestDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final goalController = TextEditingController(text: '30');
    String category = 'diet';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group Quest'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Quest Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: goalController,
                decoration: const InputDecoration(labelText: 'Goal (Days)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: ['diet', 'exercise', 'smoking', 'alcohol']
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => category = val!,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null && titleController.text.isNotEmpty) {
                final newQuest = GroupQuest(
                  id: FirebaseFirestore.instance
                      .collection('group_quests')
                      .doc()
                      .id,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  category: category,
                  goalDays: int.tryParse(goalController.text) ?? 30,
                  startDate: DateTime.now(),
                  creatorId: user.uid,
                  participantIds: [user.uid],
                  participantProgress: {user.uid: 0},
                );
                await FirebaseFirestore.instance
                    .collection('group_quests')
                    .doc(newQuest.id)
                    .set(newQuest.toFirestore());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleJoinLeaveQuest(
    BuildContext context,
    WidgetRef ref,
    GroupQuest quest,
    bool isJoined,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final questRef = FirebaseFirestore.instance
        .collection('group_quests')
        .doc(quest.id);

    if (isJoined) {
      await questRef.update({
        'participantIds': FieldValue.arrayRemove([user.uid]),
        'participantProgress.${user.uid}': FieldValue.delete(),
      });
    } else {
      await questRef.update({
        'participantIds': FieldValue.arrayUnion([user.uid]),
        'participantProgress.${user.uid}': 0,
      });
    }
  }
}
