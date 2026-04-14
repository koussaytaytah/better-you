import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../core/repositories/social_repository.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (coach) {
          if (coach == null) return const Center(child: Text('Not logged in'));
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Coach ${coach.name.split(' ').first}!',
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here are your assigned clients.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('assignedProfessionals', arrayContains: coach.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final clients = snapshot.data!.docs;
                      if (clients.isEmpty) {
                        return const Center(
                          child: Text('You have no clients assigned yet. Users can request you from the app.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final clientData = clients[index].data() as Map<String, dynamic>;
                          final String clientId = clients[index].id;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(clientData['profileImageUrl'] ?? ''),
                                child: clientData['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(clientData['name'] ?? 'Unknown Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Level ${clientData['level'] ?? 1} • Goal: Fitness'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_task, color: AppColors.primary),
                                    onPressed: () => _showSuggestQuestDialog(context, ref, coach, clientId, clientData['name'] ?? 'Client'),
                                    tooltip: 'Suggest Quest',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.message, color: AppColors.primary),
                                    onPressed: () => _openChat(context, ref, coach, clientId, clientData['name'] ?? 'Client'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // show bottom sheet with specific fitness stats
                                _showClientStats(context, clientId, clientData['name'] ?? 'Client');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showSuggestQuestDialog(BuildContext context, WidgetRef ref, UserModel coach, String clientId, String clientName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suggest Quest to $clientName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Drink 2L water today',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await ref.read(questRepositoryProvider).suggestQuest(
                  clientId,
                  coach.uid,
                  coach.name,
                  controller.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quest suggested successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to suggest: $e')),
                  );
                }
              }
            },
            child: const Text('Suggest'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref, UserModel coach, String clientId, String clientName) async {
    final participants = [coach.uid, clientId]..sort();
    final roomId = participants.join('_');
    
    // Check if room exists, otherwise create it
    final roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'participants': participants,
        'name': '',
        'isGroup': false,
        'participantNames': {
          coach.uid: coach.name,
          clientId: clientName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: roomId, roomName: clientName)),
      );
    }
  }

  void _showClientStats(BuildContext context, String clientId, String clientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('$clientName\'s Stats', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Daily Logs'),
                    Tab(text: 'Assign Quest'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // View Daily logs
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(clientId)
                            .collection('daily_logs')
                            .orderBy('date', descending: true)
                            .limit(7)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          final logs = snapshot.data?.docs ?? [];
                          if (logs.isEmpty) return const Center(child: Text('No recent logs.'));
                          
                          return ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(Icons.directions_run),
                                title: Text('Steps: ${log['steps'] ?? 0}'),
                                subtitle: Text('Water: ${log['waterIntake'] ?? 0} ml'),
                                trailing: Text(log['date']?.toString().substring(0, 10) ?? ''),
                              );
                            },
                          );
                        },
                      ),
                      // Assign Quest
                      ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text('Quick Assign Quests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          _QuestAssignButton(clientId: clientId, title: 'Run 5km', xp: 500, icon: Icons.directions_run),
                          const SizedBox(height: 12),
                          _QuestAssignButton(clientId: clientId, title: '10,000 Steps', xp: 300, icon: Icons.nordic_walking),
                          const SizedBox(height: 12),
                          _QuestAssignButton(clientId: clientId, title: 'Gym Workout (1hr)', xp: 400, icon: Icons.fitness_center),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestAssignButton extends StatelessWidget {
  final String clientId;
  final String title;
  final int xp;
  final IconData icon;

  const _QuestAssignButton({
    required this.clientId,
    required this.title,
    required this.xp,
    required this.icon,
  });

  Future<void> _assign(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .collection('prescriptions')
          .add({
        'title': title,
        'xpReward': xp,
        'isCompleted': false,
        'assignedAt': FieldValue.serverTimestamp(),
        'type': 'coach_quest',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned: $title! It will appear on their gamified dash.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _assign(context),
      icon: Icon(icon),
      label: Text('Assign "$title" (+${xp}XP)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
