import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../core/services/fcm_service.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      data: (coach) {
        if (coach == null) return const Scaffold(body: Center(child: Text('Not logged in')));
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, coach),
              SliverToBoxAdapter(child: _buildStatsRow(coach)),
              SliverToBoxAdapter(child: _buildTabSection(context, coach)),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel coach) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF007A4D)],
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
                        backgroundImage: coach.profileImageUrl != null
                            ? NetworkImage(coach.profileImageUrl!)
                            : null,
                        child: coach.profileImageUrl == null
                            ? Text(coach.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coach Dashboard',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, color: Colors.white70)),
                            Text(coach.name,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => ref.read(authServiceProvider).signOut(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Certified Fitness Coach',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                      ],
                    ),
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

  Widget _buildStatsRow(UserModel coach) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('assignedProfessionals', arrayContains: coach.uid)
            .snapshots(),
        builder: (context, clientSnap) {
          final clientCount = clientSnap.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('coachId', isEqualTo: coach.uid)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, bookingSnap) {
              final pendingCount = bookingSnap.data?.docs.length ?? 0;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('coachId', isEqualTo: coach.uid)
                    .where('status', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, completedSnap) {
                  final completedCount = completedSnap.data?.docs.length ?? 0;
                  return Row(
                    children: [
                      _StatCard(
                        label: 'Clients',
                        value: '$clientCount',
                        icon: Icons.people,
                        color: AppColors.primary,
                      ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.3),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Pending',
                        value: '$pendingCount',
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Sessions',
                        value: '$completedCount',
                        icon: Icons.check_circle,
                        color: AppColors.secondary,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabSection(BuildContext context, UserModel coach) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textLight,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Clients'),
                Tab(text: 'Sessions'),
                Tab(text: 'Requests'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: TabBarView(
            controller: _tabController,
            children: [
              _ClientsTab(coach: coach),
              _SessionsTab(coach: coach),
              _BookingRequestsTab(coach: coach),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

// ─── Clients Tab ─────────────────────────────────────────────────────────────

class _ClientsTab extends ConsumerWidget {
  final UserModel coach;
  const _ClientsTab({required this.coach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('assignedProfessionals', arrayContains: coach.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final clients = snapshot.data?.docs ?? [];
        if (clients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No clients yet', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text('Clients who pick you will appear here', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: clients.length,
          itemBuilder: (context, i) {
            final data = clients[i].data() as Map<String, dynamic>;
            final clientId = clients[i].id;
            return _ClientCard(
              clientId: clientId,
              data: data,
              coach: coach,
              ref: ref,
            ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.1);
          },
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String clientId;
  final Map<String, dynamic> data;
  final UserModel coach;
  final WidgetRef ref;

  const _ClientCard({required this.clientId, required this.data, required this.coach, required this.ref});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unknown';
    final level = data['level'] ?? 1;
    final xp = data['xp'] ?? 0;
    final imageUrl = data['profileImageUrl'] as String?;

    return GestureDetector(
      onTap: () => _showClientSheet(context),
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
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
              child: (imageUrl == null || imageUrl.isEmpty)
                  ? Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('Lvl $level', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text('$xp XP', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIcon(icon: Icons.add_task, color: AppColors.primary, tooltip: 'Assign Quest',
                    onTap: () => _showQuestDialog(context)),
                const SizedBox(width: 4),
                _ActionIcon(icon: Icons.chat_bubble_outline, color: AppColors.secondary, tooltip: 'Message',
                    onTap: () => _openChat(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClientDetailSheet(clientId: clientId, clientName: data['name'] ?? 'Client', coach: coach, ref: ref),
    );
  }

  void _showQuestDialog(BuildContext context) {
    _showAssignQuestDialog(context, ref, coach, clientId, data['name'] ?? 'Client');
  }

  Future<void> _openChat(BuildContext context) async {
    final participants = [coach.uid, clientId]..sort();
    final roomId = participants.join('_');
    final roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'participants': participants,
        'name': '',
        'isGroup': false,
        'participantNames': {coach.uid: coach.name, clientId: data['name'] ?? 'Client'},
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatRoomScreen(roomId: roomId, roomName: data['name'] ?? 'Client'),
      ));
    }
  }
}

// ─── Sessions Tab ─────────────────────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  final UserModel coach;
  const _SessionsTab({required this.coach});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.grey[200],
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed'), Tab(text: 'Cancelled')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CoachSessionList(coachId: coach.uid, status: 'pending'),
                _CoachSessionList(coachId: coach.uid, status: 'completed'),
                _CoachSessionList(coachId: coach.uid, status: 'cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachSessionList extends StatelessWidget {
  final String coachId;
  final String status;
  const _CoachSessionList({required this.coachId, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: status)
          .orderBy('scheduledAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No $status sessions', style: GoogleFonts.inter(color: AppColors.textLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final bookingId = docs[i].id;
            final dt = (d['scheduledAt'] as Timestamp?)?.toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(status), color: _statusColor(status), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['userName'] ?? 'Client', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(d['sessionType'] ?? 'Training Session', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                        if (dt != null) ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.schedule, size: 12, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text('${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  if (status == 'pending')
                    _SessionActions(bookingId: bookingId),
                ],
              ),
            ).animate().fadeIn(delay: (i * 50).ms);
          },
        );
      },
    );
  }

  Color _statusColor(String s) {
    return s == 'pending' ? AppColors.warning : s == 'completed' ? AppColors.success : AppColors.danger;
  }

  IconData _statusIcon(String s) {
    return s == 'pending' ? Icons.pending_actions : s == 'completed' ? Icons.check_circle : Icons.cancel;
  }
}

class _SessionActions extends StatelessWidget {
  final String bookingId;
  const _SessionActions({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _update('completed'),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _update('cancelled'),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close, color: AppColors.danger, size: 18),
          ),
        ),
      ],
    );
  }

  Future<void> _update(String status) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': status});
  }
}

// ─── Booking Requests Tab ─────────────────────────────────────────────────────

class _BookingRequestsTab extends StatelessWidget {
  final UserModel coach;
  const _BookingRequestsTab({required this.coach});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('coachId', isEqualTo: coach.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No pending requests', style: GoogleFonts.inter(color: AppColors.textLight)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final bookingId = docs[i].id;
            final dt = (d['scheduledAt'] as Timestamp?)?.toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                        child: Text((d['userName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['userName'] ?? 'Unknown', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                            Text(d['sessionType'] ?? 'Session request', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('Pending', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (dt != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.calendar_today, size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                    ]),
                  ],
                  if (d['notes'] != null && (d['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('"${d['notes']}"', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
                            await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
                            final userId = doc.data()?['userId'] as String?;
                            if (userId != null) {
                              FCMService().sendNotificationToUser(
                                toUserId: userId, fromUserId: coach.uid, fromUserName: coach.name,
                                type: 'booking', title: 'Session Update',
                                body: '${coach.name} declined your session request.',
                                data: {'bookingId': bookingId, 'screen': 'my_sessions'},
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
                            await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'confirmed'});
                            final userId = doc.data()?['userId'] as String?;
                            if (userId != null) {
                              FCMService().sendNotificationToUser(
                                toUserId: userId, fromUserId: coach.uid, fromUserName: coach.name,
                                type: 'booking', title: 'Session Confirmed! 🎉',
                                body: '${coach.name} accepted your session request.',
                                data: {'bookingId': bookingId, 'screen': 'my_sessions'},
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.2);
          },
        );
      },
    );
  }
}

// ─── Client Detail Sheet ─────────────────────────────────────────────────────

class _ClientDetailSheet extends StatelessWidget {
  final String clientId;
  final String clientName;
  final UserModel coach;
  final WidgetRef ref;

  const _ClientDetailSheet({required this.clientId, required this.clientName, required this.coach, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(clientName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 10),
                  Text(clientName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.grey[200],
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [Tab(text: 'Logs'), Tab(text: 'Assign Quest'), Tab(text: 'Notes')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ClientLogsView(clientId: clientId),
                  _AssignQuestView(clientId: clientId, clientName: clientName, coach: coach, ref: ref),
                  _CoachNotesView(clientId: clientId, coachId: coach.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientLogsView extends StatelessWidget {
  final String clientId;
  const _ClientLogsView({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(clientId).collection('daily_logs')
          .orderBy('date', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final logs = snapshot.data?.docs ?? [];
        if (logs.isEmpty) return const Center(child: Text('No logs yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.directions_run, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Steps: ${log['steps'] ?? 0}  •  Water: ${log['waterIntake'] ?? 0}ml',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Sleep: ${log['sleepHours'] ?? 0}h  •  Mood: ${log['mood'] ?? 'N/A'}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                  ])),
                  Text(log['date']?.toString().substring(0, 10) ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignQuestView extends StatelessWidget {
  final String clientId;
  final String clientName;
  final UserModel coach;
  final WidgetRef ref;

  const _AssignQuestView({required this.clientId, required this.clientName, required this.coach, required this.ref});

  static const _presets = [
    ('Run 5km', Icons.directions_run, 500),
    ('10,000 Steps', Icons.nordic_walking, 300),
    ('Gym Workout (1hr)', Icons.fitness_center, 400),
    ('Drink 2L Water', Icons.water_drop, 150),
    ('No Junk Food Today', Icons.no_food, 250),
    ('30 min Stretch', Icons.self_improvement, 200),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAssignQuestDialog(context, ref, coach, clientId, clientName),
          icon: const Icon(Icons.edit),
          label: const Text('Custom Quest'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 16),
        Text('Quick Assign', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ..._presets.map((p) {
          final (title, icon, xp) = p;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppColors.primary, size: 20)),
              title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              trailing: Text('+$xp XP', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              onTap: () => _assignPreset(context, title, xp),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _assignPreset(BuildContext context, String title, int xp) async {
    await FirebaseFirestore.instance.collection('users').doc(clientId).collection('prescriptions').add({
      'title': title, 'xpReward': xp, 'isCompleted': false,
      'assignedAt': FieldValue.serverTimestamp(), 'type': 'coach_quest',
      'assignedBy': coach.name,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned: $title'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _CoachNotesView extends StatefulWidget {
  final String clientId;
  final String coachId;
  const _CoachNotesView({required this.clientId, required this.coachId});

  @override
  State<_CoachNotesView> createState() => _CoachNotesViewState();
}

class _CoachNotesViewState extends State<_CoachNotesView> {
  final _ctrl = TextEditingController();

  Future<void> _saveNote() async {
    if (_ctrl.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('coach_notes').add({
      'clientId': widget.clientId,
      'coachId': widget.coachId,
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
                    hintText: 'Add a private note about this client...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
                child: const Icon(Icons.save),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('coach_notes')
                .where('clientId', isEqualTo: widget.clientId)
                .where('coachId', isEqualTo: widget.coachId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
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
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
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

// ─── Action Icon ─────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.color, required this.tooltip, required this.onTap});

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

// ─── Helpers ─────────────────────────────────────────────────────────────────

void _showAssignQuestDialog(BuildContext context, WidgetRef ref, UserModel professional, String clientId, String clientName) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Assign Quest to $clientName', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'e.g., Drink 2L water today',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: AppColors.background,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            await ref.read(questRepositoryProvider).suggestQuest(clientId, professional.uid, professional.name, controller.text.trim());
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quest assigned!'), backgroundColor: AppColors.success),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Assign'),
        ),
      ],
    ),
  );
}
