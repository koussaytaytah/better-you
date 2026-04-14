import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

class ProfessionalsDirectoryScreen extends ConsumerWidget {
  const ProfessionalsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hire a Professional'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Verified Coaches'),
              Tab(text: 'Verified Doctors'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerLow,
              ],
            ),
          ),
          child: const TabBarView(
            children: [
              _ProfessionalsList(role: 'coach'),
              _ProfessionalsList(role: 'doctor'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalsList extends ConsumerWidget {
  final String role;
  const _ProfessionalsList({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .where('isVerified', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No verified ${role}s are available at the moment.\nPlease check back later!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final proId = docs[index].id;
            
            final bool isAlreadyHired = currentUser.assignedProfessionals.contains(proId);

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(data['profileImageUrl'] ?? ''),
                      backgroundColor: Colors.grey.shade200,
                      child: data['profileImageUrl'] == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Professional',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Specialty: ${data['specialty'] ?? 'General'}',
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary),
                          ),
                          Text(
                            'Location: ${data['location'] ?? 'Remote'}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAlreadyHired ? Colors.grey : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isAlreadyHired ? null : () => _hireProfessional(context, ref, currentUser.uid, proId, role),
                      child: Text(isAlreadyHired ? 'Hired' : 'Hire', style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _hireProfessional(BuildContext context, WidgetRef ref, String userId, String proId, String role) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'assignedProfessionals': FieldValue.arrayUnion([proId]),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully hired $role! They will now see your health stats.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to hire: $e')));
      }
    }
  }
}
