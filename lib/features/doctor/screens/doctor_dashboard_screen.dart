import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/fcm_service.dart';
import '../../chat/screens/chat_room_screen.dart';

const _doctorBlue = Color(0xFF2563EB);
const _doctorBlueDark = Color(0xFF1D4ED8);
const _doctorBlueSoft = Color(0xFFEFF6FF);

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserAsyncProvider);
    return userAsync.when(
      data: (doctor) {
        if (doctor == null) return const Scaffold(body: Center(child: Text('Not logged in')));
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, doctor),
              SliverToBoxAdapter(child: _buildStatsRow(doctor)),
              SliverToBoxAdapter(child: _buildTabSection(context, doctor)),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildAppBar(BuildContext context, UserModel doctor) {
    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: _doctorBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_doctorBlue, _doctorBlueDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        backgroundImage: doctor.profileImageUrl != null
                            ? NetworkImage(doctor.profileImageUrl!) : null,
                        child: doctor.profileImageUrl == null
                            ? Text(doctor.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medical Dashboard',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                            Text('Dr. ${doctor.name}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(authServiceProvider).signOut();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeaderBadge(icon: Icons.local_hospital, label: 'Verified Physician'),
                      const SizedBox(width: 8),
                      _HeaderBadge(icon: Icons.shield, label: 'HIPAA Compliant'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: const [],
    );
  }

  Widget _buildStatsRow(UserModel doctor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('assignedProfessionals', arrayContains: doctor.uid)
            .snapshots(),
        builder: (context, patSnap) {
          final patientCount = patSnap.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('assignedProfessionals', arrayContains: doctor.uid)
                .snapshots(),
            builder: (context, snap2) {
              final todayCount = snap2.data?.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['lastActive'] as Timestamp?;
                if (ts == null) return false;
                final now = DateTime.now();
                final dt = ts.toDate();
                return dt.year == now.year && dt.month == now.month && dt.day == now.day;
              }).length ?? 0;
              return Row(
                children: [
                  _DoctorStatCard(label: 'Patients', value: '$patientCount', icon: Icons.people, color: _doctorBlue),
                  const SizedBox(width: 10),
                  _DoctorStatCard(label: 'Active Today', value: '$todayCount', icon: Icons.today, color: AppColors.success),
                  const SizedBox(width: 10),
                  _DoctorStatCard(label: 'Prescriptions', value: '—', icon: Icons.medication, color: AppColors.warning),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabSection(BuildContext context, UserModel doctor) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textLight,
              indicator: BoxDecoration(color: _doctorBlue, borderRadius: BorderRadius.circular(12)),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Patients'), Tab(text: 'Prescriptions')],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.58,
          child: TabBarView(
            controller: _tabController,
            children: [
              _PatientsTab(doctor: doctor),
              _PrescriptionsTab(doctor: doctor),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header Badge ────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
      ]),
    );
  }
}

// ─── Doctor Stat Card ─────────────────────────────────────────────────────────

class _DoctorStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DoctorStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ]),
      ),
    );
  }
}

// ─── Patients Tab ─────────────────────────────────────────────────────────────

class _PatientsTab extends ConsumerWidget {
  final UserModel doctor;
  const _PatientsTab({required this.doctor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('assignedProfessionals', arrayContains: doctor.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final patients = snapshot.data?.docs ?? [];
        if (patients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No patients yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text('Patients who link with you appear here', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: patients.length,
          itemBuilder: (context, i) {
            final data = patients[i].data() as Map<String, dynamic>;
            final patientId = patients[i].id;
            return _PatientCard(patientId: patientId, data: data, doctor: doctor, ref: ref)
                .animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.1);
          },
        );
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String patientId;
  final Map<String, dynamic> data;
  final UserModel doctor;
  final WidgetRef ref;

  const _PatientCard({required this.patientId, required this.data, required this.doctor, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final age = data['age'];
    final weight = data['weight'];
    final imageUrl = data['profileImageUrl'] as String?;
    final isPremium = data['isPremium'] == true;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _PatientDetailSheet(patientId: patientId, patientName: name, doctor: doctor, ref: ref),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _doctorBlueSoft,
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: _doctorBlue))
                      : null,
                ),
                if (isPremium)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.star, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (age != null) ...[
                      _InfoChip(label: 'Age $age', color: _doctorBlue),
                      const SizedBox(width: 6),
                    ],
                    if (weight != null)
                      _InfoChip(label: '${weight}kg', color: AppColors.success),
                  ]),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DoctorAction(icon: Icons.medication, color: AppColors.warning, tooltip: 'Prescribe',
                    onTap: () => _showPrescribeDialog(context)),
                const SizedBox(width: 6),
                _DoctorAction(icon: Icons.chat_bubble_outline, color: _doctorBlue, tooltip: 'Message',
                    onTap: () => _openChat(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrescribeDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    _showDoctorPrescribeDialog(context, ref, doctor, patientId, data['name'] ?? 'Patient');
  }

  Future<void> _openChat(BuildContext context) async {
    HapticFeedback.lightImpact();
    final participants = [doctor.uid, patientId]..sort();
    final roomId = participants.join('_');
    final roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'participants': participants,
        'name': '',
        'isGroup': false,
        'participantNames': {doctor.uid: doctor.name, patientId: data['name'] ?? 'Patient'},
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatRoomScreen(roomId: roomId, roomName: data['name'] ?? 'Patient'),
      ));
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _DoctorAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _DoctorAction({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Prescriptions Tab ───────────────────────────────────────────────────────

class _PrescriptionsTab extends ConsumerWidget {
  final UserModel doctor;
  const _PrescriptionsTab({required this.doctor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('assignedProfessionals', arrayContains: doctor.uid)
          .snapshots(),
      builder: (context, patSnap) {
        final patientDocs = patSnap.data?.docs ?? [];
        if (patientDocs.isEmpty) {
          return const Center(child: Text('No patients assigned'));
        }
        final patientIds = patientDocs.map((d) => d.id).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: patientIds.length,
          itemBuilder: (context, i) {
            final patData = patientDocs[i].data() as Map<String, dynamic>;
            final patientId = patientIds[i];
            final patientName = patData['name'] ?? 'Patient';
            return _PatientPrescriptionCard(
              patientId: patientId,
              patientName: patientName,
              doctor: doctor,
              ref: ref,
            ).animate().fadeIn(delay: (i * 60).ms);
          },
        );
      },
    );
  }
}

class _PatientPrescriptionCard extends StatelessWidget {
  final String patientId;
  final String patientName;
  final UserModel doctor;
  final WidgetRef ref;

  const _PatientPrescriptionCard({required this.patientId, required this.patientName, required this.doctor, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _doctorBlueSoft,
                child: Text(patientName[0].toUpperCase(), style: const TextStyle(color: _doctorBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(patientName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14))),
              TextButton.icon(
                onPressed: () => _showDoctorPrescribeDialog(context, ref, doctor, patientId, patientName),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: _doctorBlue),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users').doc(patientId).collection('prescriptions')
                .where('type', isEqualTo: 'doctor_prescription')
                .orderBy('assignedAt', descending: true).limit(3).snapshots(),
            builder: (ctx, snap) {
              final prx = snap.data?.docs ?? [];
              if (prx.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('No prescriptions yet', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                );
              }
              return Column(
                children: prx.map((p) {
                  final d = p.data() as Map<String, dynamic>;
                  final done = d['isCompleted'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16, color: done ? AppColors.success : AppColors.textLight),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d['title'] ?? '', style: GoogleFonts.inter(
                          fontSize: 12,
                          color: done ? AppColors.textLight : AppColors.text,
                          decoration: done ? TextDecoration.lineThrough : null))),
                      Text('+${d['xpReward'] ?? 0} XP', style: GoogleFonts.inter(fontSize: 11, color: _doctorBlue, fontWeight: FontWeight.w600)),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Patient Detail Sheet ─────────────────────────────────────────────────────

class _PatientDetailSheet extends StatelessWidget {
  final String patientId;
  final String patientName;
  final UserModel doctor;
  final WidgetRef ref;

  const _PatientDetailSheet({required this.patientId, required this.patientName, required this.doctor, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _doctorBlueSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person, color: _doctorBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(patientName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              labelColor: _doctorBlue,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: _doctorBlue,
              dividerColor: Colors.grey[200],
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Health Logs'), Tab(text: 'Prescribe'), Tab(text: 'Notes')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PatientLogsView(patientId: patientId),
                  _PrescribeView(patientId: patientId, patientName: patientName, doctor: doctor, ref: ref),
                  _DoctorNotesView(patientId: patientId, doctorId: doctor.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientLogsView extends StatelessWidget {
  final String patientId;
  const _PatientLogsView({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(patientId).collection('daily_logs')
          .orderBy('date', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data?.docs ?? [];
        if (logs.isEmpty) return const Center(child: Text('No health data yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _doctorBlueSoft, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.favorite, color: _doctorBlue, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(log['date']?.toString().substring(0, 10) ?? '',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _doctorBlue)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    _LogBadge(label: 'Mood: ${log['mood'] ?? 'N/A'}'),
                    _LogBadge(label: 'Sleep: ${log['sleepHours'] ?? 0}h'),
                    _LogBadge(label: 'Calories: ${log['caloriesIntake'] ?? 0} kcal'),
                    _LogBadge(label: 'Steps: ${log['steps'] ?? 0}'),
                    _LogBadge(label: 'Water: ${log['waterIntake'] ?? 0} ml'),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LogBadge extends StatelessWidget {
  final String label;
  const _LogBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
    );
  }
}

class _PrescribeView extends StatelessWidget {
  final String patientId;
  final String patientName;
  final UserModel doctor;
  final WidgetRef ref;

  const _PrescribeView({required this.patientId, required this.patientName, required this.doctor, required this.ref});

  static const _presets = [
    ('Drink 3L Water & Take Meds', Icons.medication, 500),
    ('No Cigarettes Today', Icons.smoke_free, 1000),
    ('Sleep 8 Hours', Icons.bedtime, 800),
    ('Morning Blood Pressure Check', Icons.monitor_heart, 300),
    ('30 min Walk', Icons.directions_walk, 250),
    ('Low Salt Diet Today', Icons.no_meals, 400),
    ('Take Vitamins', Icons.local_pharmacy, 200),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showDoctorPrescribeDialog(context, ref, doctor, patientId, patientName),
          icon: const Icon(Icons.edit),
          label: const Text('Custom Prescription'),
          style: ElevatedButton.styleFrom(backgroundColor: _doctorBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 16),
        Text('Quick Prescriptions', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ..._presets.map((p) {
          final (title, icon, xp) = p;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _doctorBlueSoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: _doctorBlue, size: 20),
              ),
              title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              trailing: Text('+$xp XP', style: GoogleFonts.inter(color: _doctorBlue, fontWeight: FontWeight.w700, fontSize: 12)),
              onTap: () => _prescribePreset(context, title, xp),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _prescribePreset(BuildContext context, String title, int xp) async {
    await FirebaseFirestore.instance.collection('users').doc(patientId).collection('prescriptions').add({
      'title': title, 'xpReward': xp, 'isCompleted': false,
      'assignedAt': FieldValue.serverTimestamp(), 'type': 'doctor_prescription',
      'prescribedBy': doctor.name,
    });
    FCMService().sendNotificationToUser(
      toUserId: patientId,
      fromUserId: doctor.uid,
      fromUserName: doctor.name,
      type: 'prescription',
      title: 'New Prescription 📊',
      body: 'Dr. ${doctor.name} prescribed: $title',
      data: {'screen': 'habits'},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescribed: $title'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _DoctorNotesView extends StatefulWidget {
  final String patientId;
  final String doctorId;
  const _DoctorNotesView({required this.patientId, required this.doctorId});

  @override
  State<_DoctorNotesView> createState() => _DoctorNotesViewState();
}

class _DoctorNotesViewState extends State<_DoctorNotesView> {
  final _ctrl = TextEditingController();

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('doctor_notes').add({
      'patientId': widget.patientId,
      'doctorId': widget.doctorId,
      'note': _ctrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Clinical note about this patient...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: _doctorBlue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
                child: const Icon(Icons.save),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('doctor_notes')
                .where('patientId', isEqualTo: widget.patientId)
                .where('doctorId', isEqualTo: widget.doctorId)
                .orderBy('createdAt', descending: true).snapshots(),
            builder: (ctx, snap) {
              final notes = snap.data?.docs ?? [];
              if (notes.isEmpty) return const Center(child: Text('No notes yet'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notes.length,
                itemBuilder: (ctx, i) {
                  final n = notes[i].data() as Map<String, dynamic>;
                  final ts = (n['createdAt'] as Timestamp?)?.toDate();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: _doctorBlue, width: 3)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['note'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                      if (ts != null) ...[
                        const SizedBox(height: 4),
                        Text('${ts.day}/${ts.month}/${ts.year}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Doctor Prescribe Dialog ──────────────────────────────────────────────────

void _showDoctorPrescribeDialog(BuildContext context, WidgetRef ref, UserModel doctor, String patientId, String patientName) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Prescribe to $patientName', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'e.g., Morning blood pressure check',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: AppColors.background,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            if (controller.text.trim().isEmpty) return;
            final title = controller.text.trim();
            await FirebaseFirestore.instance
                .collection('users').doc(patientId).collection('prescriptions').add({
              'title': title,
              'xpReward': 300,
              'isCompleted': false,
              'assignedAt': FieldValue.serverTimestamp(),
              'type': 'doctor_prescription',
              'prescribedBy': doctor.name,
            });
            FCMService().sendNotificationToUser(
              toUserId: patientId,
              fromUserId: doctor.uid,
              fromUserName: doctor.name,
              type: 'prescription',
              title: 'New Prescription \ud83d\udcca',
              body: 'Dr. ${doctor.name} prescribed: $title',
              data: {'screen': 'habits'},
            );
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription added!'), backgroundColor: AppColors.success),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _doctorBlue, foregroundColor: Colors.white),
          child: const Text('Prescribe'),
        ),
      ],
    ),
  );
}
