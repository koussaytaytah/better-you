import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../../shared/providers/data_provider.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
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
        data: (doctor) {
          if (doctor == null) return const Center(child: Text('Not logged in'));
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services, size: 40, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dr. ${doctor.name.split(' ').first}',
                        style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your registered patients and their health logs.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('assignedProfessionals', arrayContains: doctor.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final patients = snapshot.data!.docs;
                      if (patients.isEmpty) {
                        return const Center(
                          child: Text('No patients assigned. Users can connect with you from the professional directory.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patientData = patients[index].data() as Map<String, dynamic>;
                          final String patientId = patients[index].id;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(patientData['profileImageUrl'] ?? ''),
                                child: patientData['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(patientData['name'] ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Age: ${patientData['age'] ?? 'N/A'} • Weight: ${patientData['weight'] ?? 'N/A'} kg'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_task, color: Colors.blueAccent),
                                    onPressed: () => _showSuggestQuestDialog(context, ref, doctor, patientId, patientData['name'] ?? 'Patient'),
                                    tooltip: 'Suggest Patient Quest',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.medical_services, color: Colors.blueAccent),
                                    onPressed: () => _openChat(context, ref, doctor, patientId, patientData['name'] ?? 'Patient'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showPatientStats(context, patientId, patientData['name'] ?? 'Patient');
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

  void _showSuggestQuestDialog(BuildContext context, WidgetRef ref, UserModel doctor, String patientId, String patientName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suggest Health Task to $patientName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Morning blood pressure check',
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
                      patientId,
                      doctor.uid,
                      doctor.name,
                      controller.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task suggested successfully!'),
                      backgroundColor: AppColors.success,
                    ),
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

  Future<void> _openChat(BuildContext context, WidgetRef ref, UserModel doctor, String patientId, String patientName) async {
    final participants = [doctor.uid, patientId]..sort();
    final roomId = participants.join('_');
    
    final roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'participants': participants,
        'name': '',
        'isGroup': false,
        'participantNames': {
          doctor.uid: doctor.name,
          patientId: patientName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: roomId, roomName: patientName)),
      );
    }
  }

  void _showPatientStats(BuildContext context, String patientId, String patientName) {
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
                  child: Text('$patientName\'s Health File', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                const TabBar(
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Medical Logs'),
                    Tab(text: 'Prescribe Action'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // View Daily logs
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(patientId)
                            .collection('daily_logs')
                            .orderBy('date', descending: true)
                            .limit(7)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          final logs = snapshot.data?.docs ?? [];
                          if (logs.isEmpty) return const Center(child: Text('No health data available.'));
                          
                          return ListView.builder(
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index].data() as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                                title: Text('Mood: ${log['mood'] ?? 'Neutral'} | Sleep: ${log['sleepHours'] ?? 0} hrs'),
                                subtitle: Text('Diet: ${log['dietType'] ?? 'Normal'} | Calories: ${log['caloriesIntake'] ?? 0} kcal'),
                                trailing: Text(log['date']?.toString().substring(0, 10) ?? ''),
                              );
                            },
                          );
                        },
                      ),
                      // Prescribe Quest
                      ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text('Medical Prescriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          _PrescribeButton(patientId: patientId, title: 'Drink 3L Water & Take Meds', xp: 500, icon: Icons.medication),
                          const SizedBox(height: 12),
                          _PrescribeButton(patientId: patientId, title: 'No Cigarettes Today', xp: 1000, icon: Icons.smoke_free),
                          const SizedBox(height: 12),
                          _PrescribeButton(patientId: patientId, title: 'Sleep 8 Hours', xp: 800, icon: Icons.bedtime),
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

class _PrescribeButton extends StatelessWidget {
  final String patientId;
  final String title;
  final int xp;
  final IconData icon;

  const _PrescribeButton({
    required this.patientId,
    required this.title,
    required this.xp,
    required this.icon,
  });

  Future<void> _prescribe(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('prescriptions')
          .add({
        'title': title,
        'xpReward': xp,
        'isCompleted': false,
        'assignedAt': FieldValue.serverTimestamp(),
        'type': 'doctor_prescription',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescribed: $title! Action pushed to gamified tracker.')),
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
      onPressed: () => _prescribe(context),
      icon: Icon(icon),
      label: Text('Prescribe "$title" (+${xp}XP)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
