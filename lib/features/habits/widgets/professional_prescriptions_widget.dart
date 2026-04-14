import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

class ProfessionalPrescriptionsWidget extends ConsumerWidget {
  const ProfessionalPrescriptionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('prescriptions')
          .where('isCompleted', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Don't show if nothing assigned
        }

        final prescriptions = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Quests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...prescriptions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isMedical = data['type'] == 'doctor_prescription';
              final color = isMedical ? Colors.blueAccent : AppColors.primary;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: Icon(
                    isMedical ? Icons.medical_services : Icons.fitness_center,
                    color: color,
                  ),
                  title: Text(
                    data['title'] ?? 'Mandatory Quest',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Reward: +${data['xpReward'] ?? 0} XP'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _completeQuest(context, ref, user.uid, doc.id, data['xpReward'] ?? 0),
                    child: const Text('Complete'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Future<void> _completeQuest(BuildContext context, WidgetRef ref, String userId, String prescriptionId, int xpReward) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('prescriptions')
          .doc(prescriptionId)
          .update({'isCompleted': true, 'completedAt': FieldValue.serverTimestamp()});
      
      await ref.read(userRepositoryProvider).addXP(userId, xpReward);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Quest Completed! +$xpReward XP earned!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
