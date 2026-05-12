import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  StreamSubscription? _pendingUsersSub;

  @override
  void initState() {
    super.initState();
    _listenForPendingUsers();
  }

  void _listenForPendingUsers() {
    _pendingUsersSub = FirebaseFirestore.instance
        .collection('users')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final name = data['name'] ?? 'Someone';
              final role = data['role'] ?? 'professional';
              
              final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
              const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
                'admin_alerts',
                'Admin Alerts',
                importance: Importance.max,
                priority: Priority.high,
              );
              const NotificationDetails details = NotificationDetails(android: androidDetails);
              flutterLocalNotificationsPlugin.show(
                DateTime.now().millisecond,
                'New Verification Request',
                '$name wants to verify as a $role. Review their application now!',
                details,
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pendingUsersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF7C3AED),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Admin Panel',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                                    Text('Better You',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.launch, color: Colors.white),
                                tooltip: 'Switch to User Mode',
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/dashboard');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                tooltip: 'Logout',
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(authServiceProvider).signOut();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildQuickStats(context, ref),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Coaches'),
                  Tab(text: 'Doctors'),
                  Tab(text: 'Users'),
                  Tab(text: 'Reports'),
                  Tab(icon: Icon(Icons.upload_rounded, size: 16), text: 'Seed'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _PendingList(role: 'coach'),
              _PendingList(role: 'doctor'),
              _UserManagementTab(),
              _ReportsTab(),
              const _SeedDataTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final totalUsers = docs.length;
        final pending = docs.where((d) => (d.data() as Map)['verificationStatus'] == 'pending').length;
        final banned = docs.where((d) => (d.data() as Map)['isBanned'] == true).length;
        final premium = docs.where((d) => (d.data() as Map)['isPremium'] == true).length;
        return Row(
          children: [
            _MiniStatBadge(label: 'Users', value: '$totalUsers', icon: Icons.people),
            const SizedBox(width: 8),
            _MiniStatBadge(label: 'Pending', value: '$pending', icon: Icons.hourglass_top),
            const SizedBox(width: 8),
            _MiniStatBadge(label: 'Banned', value: '$banned', icon: Icons.block),
            const SizedBox(width: 8),
            _MiniStatBadge(label: 'Premium', value: '$premium', icon: Icons.star),
          ],
        );
      },
    );
  }
}

class _UserManagementTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends ConsumerState<_UserManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  Future<void> _exportUsersToCSV() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<List<dynamic>> rows = [];
      
      // Header
      rows.add(['UID', 'Name', 'Email', 'Role', 'Level', 'XP', 'Verification']);
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['name'] ?? '',
          data['email'] ?? '',
          data['role'] ?? '',
          data['level'] ?? 1,
          data['xp'] ?? 0,
          data['verificationStatus'] ?? 'none'
        ]);
      }

      String csvData = csv_pkg.Csv().encode(rows);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/better_you_users_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Better You User Export');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _awardBadge(String userId, String badgeName) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(userRepositoryProvider).awardBadge(userId, badgeName);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Awarded "$badgeName" trophy!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAwardBadgeDialog(String userId) {
    final badges = ['Elite Member', 'Super Coach', 'Health Guru', 'Community Hero', 'Early Adopter'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Trophy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badges.map((b) => ListTile(
            title: Text(b),
            onTap: () {
              Navigator.pop(context);
              _awardBadge(userId, b);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _performAction(String userId, String action) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      if (action == 'add_xp') {
        final xpValue = int.tryParse(_amountController.text.trim());
        if (xpValue == null) throw Exception("Enter a valid number for XP.");
        await ref.read(userRepositoryProvider).addXP(userId, xpValue);
        _amountController.clear();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $xpValue XP.')));
      } else if (action == 'ban') {
        await ref.read(userRepositoryProvider).banUser(userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Banned.')));
      } else if (action == 'unban') {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBanned': false, 'warningMessage': null});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Unbanned.')));
      } else if (action == 'delete') {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Deleted.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUserDialog(String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isBanned = data['isBanned'] == true;
          return AlertDialog(
            title: Text(data['name'] ?? 'User Management'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Email: ${data['email']}'),
                  Text('Level: ${data['level']} | XP: ${data['xp']}'),
                  Text('Role: ${data['role']}'),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'XP Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _performAction(userId, 'add_xp'),
                    child: const Text('Add XP'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAwardBadgeDialog(userId),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Grant Trophy'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(isBanned ? 'User is BANNED' : 'User is Active'),
                    trailing: Switch(
                      value: isBanned,
                      activeThumbColor: Colors.red,
                      onChanged: (val) {
                        Navigator.pop(context);
                        _performAction(userId, val ? 'ban' : 'unban');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('HARD DELETE?'),
                          content: const Text('This will wipe them from Firestore.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        Navigator.pop(context);
                        _performAction(userId, 'delete');
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Hard Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by Email or Name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export users to CSV',
                onPressed: _isLoading ? null : _exportUsersToCSV,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email = (data['email'] ?? '').toString().toLowerCase();
                final name = (data['name'] ?? '').toString().toLowerCase();
                return email.contains(_searchQuery) || name.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isBanned = data['isBanned'] == true;
                  final role = data['role'] ?? 'user';
                  final level = data['level'] ?? 1;
                  final name = data['name'] ?? 'No Name';
                  return GestureDetector(
                    onTap: () => _showUserDialog(doc.id, data),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isBanned ? Border.all(color: AppColors.danger.withValues(alpha: 0.4)) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isBanned
                                ? Colors.grey[200]
                                : const Color(0xFFEDE9FE),
                            child: Text(
                              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                              style: TextStyle(
                                color: isBanned ? Colors.grey : const Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(data['email'] ?? 'No Email', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _RoleBadge(role: role),
                              const SizedBox(height: 4),
                              if (isBanned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text('BANNED', style: GoogleFonts.inter(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w700)),
                                )
                              else
                                Text('Lvl $level', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStatBadge({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final String role;
  const _PendingList({required this.role});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allPending = snapshot.data!.docs;
        final docs = allPending.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == role;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(role == 'coach' ? Icons.sports : Icons.local_hospital, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No pending ${role}s', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text('All ${role}s are verified or none applied yet', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final imageUrl = data['profileImageUrl'] as String?;
            final name = data['name'] ?? 'No name';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFEDE9FE),
                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text('${data['specialty'] ?? 'Not specified'} • ${data['location'] ?? 'Unknown'}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Pending', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (data['bio'] != null && (data['bio'] as String).isNotEmpty) ...
                    [
                      const SizedBox(height: 8),
                      Text(data['bio'], maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                    ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCertificate(context, data['certificateImageUrl'] ?? ''),
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Certificate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectUser(docs[index].id),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveUser(docs[index].id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.2);
          },
        );
      },
    );
  }

  void _approveUser(String uid) {
    HapticFeedback.mediumImpact();
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'verificationStatus': 'approved',
      'isVerified': true,
    });
  }

  void _rejectUser(String uid) {
    HapticFeedback.heavyImpact();
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'verificationStatus': 'rejected',
      'isVerified': false,
    });
  }

  void _showCertificate(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Professional Certificate'),
        content: url.isEmpty 
          ? const Text('No certificate image uploaded.')
          : InteractiveViewer(child: Image.network(url)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'admin': const Color(0xFF7C3AED),
      'coach': AppColors.primary,
      'doctor': const Color(0xFF2563EB),
      'user': AppColors.textLight,
    };
    final c = colors[role] ?? AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(role.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: c, fontWeight: FontWeight.w700)),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Text('No reports yet'));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            final status = report['status'] ?? 'pending';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Reason: ${report['reason']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported: ${report['reportedId']}'),
                    Text('Status: $status'),
                  ],
                ),
                trailing: status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.warning_amber, color: Colors.orange),
                            onPressed: () => _showWarnDialog(context, ref, report['reportedId'], report['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.block, color: Colors.red),
                            onPressed: () => _showBanDialog(context, ref, report['reportedId'], report['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () => _resolveReport(context, ref, report['id'], 'dismissed'),
                          ),
                        ],
                      )
                    : Text(
                        status.toUpperCase(),
                        style: TextStyle(color: status == 'resolved' ? Colors.green : Colors.grey),
                      ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showWarnDialog(BuildContext context, WidgetRef ref, String userId, String reportId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warn User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter warning message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final msg = controller.text.trim();
              if (msg.isEmpty) return;
              await ref.read(userRepositoryProvider).warnUser(userId, msg);
              await ref.read(socialRepositoryProvider).resolveReport(reportId, 'warned');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, WidgetRef ref, String userId, String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: const Text('Are you sure you want to ban this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(userRepositoryProvider).banUser(userId);
              await ref.read(socialRepositoryProvider).resolveReport(reportId, 'banned');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ban User'),
          ),
        ],
      ),
    );
  }

  void _resolveReport(BuildContext context, WidgetRef ref, String reportId, String status) {
    ref.read(socialRepositoryProvider).resolveReport(reportId, status);
  }
}

// ─── SEED DATA TAB ────────────────────────────────────────────────────────────

class _SeedDataTab extends StatefulWidget {
  const _SeedDataTab();

  @override
  State<_SeedDataTab> createState() => _SeedDataTabState();
}

class _SeedDataTabState extends State<_SeedDataTab> {
  final _db = FirebaseFirestore.instance;
  final List<String> _log = [];
  bool _isRunning = false;
  int _done = 0;
  int _total = 0;

  void _addLog(String msg) {
    if (mounted) setState(() => _log.insert(0, '[${DateTime.now().toLocal().toString().substring(11, 19)}] $msg'));
  }

  Future<void> _seed(String label, String collection, List<Map<String, dynamic>> items) async {
    _addLog('Seeding $label (${items.length} items)...');
    int count = 0;
    for (final item in items) {
      try {
        final id = item['id'] as String;
        final data = Map<String, dynamic>.from(item)..remove('id');
        data['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection(collection).doc(id).set(data, SetOptions(merge: true));
        count++;
        if (mounted) setState(() => _done++);
      } catch (e) {
        _addLog('  ✗ ${item['id'] ?? '?'}: $e');
      }
    }
    _addLog('  ✓ $count/${items.length} $label seeded');
  }

  Future<void> _runAll() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _log.clear();
      _done = 0;
      _total = _recipes.length + _workouts.length + _tips.length + _coaches.length + _doctors.length;
    });
    _addLog('🌱 Starting full seed...');
    try {
      await _seed('Recipes', 'recipes', _recipes);
      await _seed('Workout Plans', 'workout_plans', _workouts);
      await _seed('Nutrition Tips', 'nutrition_tips', _tips);
      await _seed('Coaches', 'users', _coaches);
      await _seed('Doctors', 'users', _doctors);
      _addLog('✅ All done! $_done/$_total documents written.');
    } catch (e) {
      _addLog('❌ Fatal error: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  Future<void> _clearCollection(String collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear $collection?'),
        content: Text('This will delete ALL documents in "$collection". Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE ALL', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    _addLog('🗑 Clearing $collection...');
    final snap = await _db.collection(collection).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _addLog('  ✓ Cleared ${snap.docs.length} docs from $collection');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _isRunning ? null : _runAll,
                icon: _isRunning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(_isRunning ? 'Seeding... $_done/$_total' : 'Seed All Data (30 recipes + 20 workouts + tips + coaches + doctors)'),
                style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning ? null : () => _seed('Recipes', 'recipes', _recipes),
                      icon: const Icon(Icons.restaurant_menu, size: 16),
                      label: const Text('Recipes only'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning ? null : () => _seed('Workouts', 'workout_plans', _workouts),
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text('Workouts only'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning ? null : () => _seed('Coaches', 'users', _coaches),
                      icon: const Icon(Icons.sports, size: 16),
                      label: const Text('Coaches only'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning ? null : () => _seed('Doctors', 'users', _doctors),
                      icon: const Icon(Icons.medical_services, size: 16),
                      label: const Text('Doctors only'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isRunning ? null : () => _clearCollection('recipes'),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                label: const Text('Clear recipes', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ],
          ),
        ),
        if (_total > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: _total > 0 ? _done / _total : 0,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: Colors.green,
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Seed Log:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ),
        Expanded(
          child: _log.isEmpty
              ? const Center(child: Text('No activity yet. Press "Seed All Data" to start.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Text(
                    _log[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: _log[i].contains('✓') ? Colors.green[700]
                           : _log[i].contains('✗') || _log[i].contains('❌') ? Colors.red[700]
                           : _log[i].contains('🌱') || _log[i].contains('✅') ? Colors.blue[700]
                           : Colors.grey[700],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── SEED DATA DEFINITIONS ────────────────────────────────────────────────────

final _recipes = [
  {'id': 'r001', 'title': 'Greek Yogurt Parfait', 'description': 'Creamy Greek yogurt layered with fresh berries and granola.', 'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800', 'calories': 320, 'protein': 18.0, 'carbs': 42.0, 'fat': 6.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'Mediterranean', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['breakfast', 'high-protein', 'quick'], 'ingredients': ['200g Greek yogurt', '1/2 cup mixed berries', '1/4 cup granola', '1 tbsp honey'], 'instructions': ['Layer yogurt in bowl', 'Add berries', 'Sprinkle granola', 'Drizzle honey']},
  {'id': 'r002', 'title': 'Avocado Toast with Poached Eggs', 'description': 'Whole grain toast with smashed avocado and poached eggs.', 'imageUrl': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800', 'calories': 420, 'protein': 22.0, 'carbs': 35.0, 'fat': 22.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 10, 'servings': 1, 'difficulty': 'Medium', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': false, 'isDairyFree': true, 'tags': ['breakfast', 'high-protein'], 'ingredients': ['2 slices whole grain bread', '1 ripe avocado', '2 eggs', 'Salt & pepper', '1 tsp lemon juice'], 'instructions': ['Toast bread', 'Mash avocado with lemon', 'Poach eggs 3-4 min', 'Assemble and season']},
  {'id': 'r003', 'title': 'Overnight Oats', 'description': 'No-cook oats with almond milk, banana and peanut butter.', 'imageUrl': 'https://images.unsplash.com/photo-1571748982800-fa51082c2224?w=800', 'calories': 380, 'protein': 12.0, 'carbs': 58.0, 'fat': 10.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': false, 'isDairyFree': true, 'tags': ['breakfast', 'vegan', 'meal-prep'], 'ingredients': ['1/2 cup rolled oats', '1 cup almond milk', '1 banana', '2 tbsp peanut butter', '1 tbsp maple syrup'], 'instructions': ['Mix oats and almond milk', 'Add syrup', 'Refrigerate overnight', 'Top with banana and PB']},
  {'id': 'r004', 'title': 'Spinach Mushroom Omelette', 'description': 'Fluffy 3-egg omelette with sauteed spinach and mushrooms.', 'imageUrl': 'https://images.unsplash.com/photo-1510693206972-df098062cb71?w=800', 'calories': 290, 'protein': 26.0, 'carbs': 6.0, 'fat': 18.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 8, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'French', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['breakfast', 'high-protein', 'keto'], 'ingredients': ['3 eggs', '1 cup spinach', '1/2 cup mushrooms', '2 tbsp feta', '1 tbsp olive oil'], 'instructions': ['Saute mushrooms 3 min', 'Add spinach', 'Beat eggs, pour in pan', 'Add filling and fold']},
  {'id': 'r005', 'title': 'Banana Protein Pancakes', 'description': 'Fluffy high-protein pancakes with banana and protein powder.', 'imageUrl': 'https://images.unsplash.com/photo-1506459225024-1428097a7e18?w=800', 'calories': 350, 'protein': 30.0, 'carbs': 40.0, 'fat': 7.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 10, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['breakfast', 'high-protein', 'post-workout'], 'ingredients': ['2 bananas', '2 eggs', '1 scoop vanilla protein powder', '1/2 tsp baking powder'], 'instructions': ['Mash bananas', 'Mix in eggs and protein powder', 'Cook on non-stick pan 2 min per side']},
  {'id': 'r006', 'title': 'Chia Seed Pudding', 'description': 'Coconut milk chia pudding with mango and toasted coconut.', 'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800', 'calories': 280, 'protein': 8.0, 'carbs': 32.0, 'fat': 14.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'Tropical', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['breakfast', 'vegan', 'gluten-free'], 'ingredients': ['3 tbsp chia seeds', '1 cup coconut milk', '1 mango diced', '1 tbsp agave'], 'instructions': ['Mix chia and coconut milk', 'Refrigerate 4 hours', 'Top with mango']},
  {'id': 'r007', 'title': 'Smoothie Bowl', 'description': 'Thick acai smoothie bowl with fresh fruit and seeds.', 'imageUrl': 'https://images.unsplash.com/photo-1511690078903-71dc5a49f5e3?w=800', 'calories': 340, 'protein': 10.0, 'carbs': 62.0, 'fat': 8.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'Brazilian', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['breakfast', 'vegan', 'antioxidant'], 'ingredients': ['100g frozen acai', '1 frozen banana', '1/2 cup almond milk', 'Kiwi, blueberries, granola toppings'], 'instructions': ['Blend acai, banana, almond milk until thick', 'Pour into bowl', 'Arrange toppings']},
  {'id': 'r008', 'title': 'Turkish Menemen', 'description': 'Spiced tomato and pepper egg scramble.', 'imageUrl': 'https://images.unsplash.com/photo-1619740455993-9d622fc45b1b?w=800', 'calories': 260, 'protein': 18.0, 'carbs': 14.0, 'fat': 14.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 15, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'Turkish', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['breakfast', 'mediterranean'], 'ingredients': ['4 eggs', '2 tomatoes', '1 green pepper', '1 onion', '2 tbsp olive oil', '1 tsp cumin'], 'instructions': ['Saute onion and pepper', 'Add tomatoes and cumin', 'Crack eggs in and scramble']},
  {'id': 'r009', 'title': 'Peanut Butter Banana Toast', 'description': 'Power breakfast with natural peanut butter and banana.', 'imageUrl': 'https://images.unsplash.com/photo-1618090584176-7132b9911657?w=800', 'calories': 390, 'protein': 14.0, 'carbs': 52.0, 'fat': 16.0, 'prepTimeMinutes': 3, 'cookTimeMinutes': 2, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': false, 'isDairyFree': true, 'tags': ['breakfast', 'quick', 'energy'], 'ingredients': ['2 slices whole grain bread', '2 tbsp peanut butter', '1 banana', '1 tsp honey'], 'instructions': ['Toast bread', 'Spread PB', 'Layer banana', 'Drizzle honey']},
  {'id': 'r010', 'title': 'Cottage Cheese Bowl', 'description': 'High-protein cottage cheese with peaches and walnuts.', 'imageUrl': 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=800', 'calories': 300, 'protein': 24.0, 'carbs': 28.0, 'fat': 10.0, 'prepTimeMinutes': 3, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['breakfast', 'high-protein', 'low-carb'], 'ingredients': ['1 cup cottage cheese', '1 peach diced', '2 tbsp walnuts', '1 tsp honey'], 'instructions': ['Spoon cottage cheese into bowl', 'Top with peach and walnuts', 'Drizzle honey']},
  {'id': 'r011', 'title': 'Grilled Chicken Caesar Salad', 'description': 'Classic Caesar with grilled chicken, romaine and parmesan.', 'imageUrl': 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=800', 'calories': 420, 'protein': 40.0, 'carbs': 18.0, 'fat': 22.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 15, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': false, 'isDairyFree': false, 'tags': ['lunch', 'high-protein', 'salad'], 'ingredients': ['2 chicken breasts', '1 romaine head', '50g parmesan', '1 cup croutons', '3 tbsp Caesar dressing'], 'instructions': ['Grill chicken 6-7 min per side', 'Chop romaine', 'Slice chicken', 'Toss with dressing and toppings']},
  {'id': 'r012', 'title': 'Quinoa Buddha Bowl', 'description': 'Quinoa with roasted veggies, chickpeas and tahini.', 'imageUrl': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800', 'calories': 480, 'protein': 18.0, 'carbs': 62.0, 'fat': 16.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 25, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'Fusion', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['lunch', 'vegan', 'meal-prep'], 'ingredients': ['1 cup quinoa', '1 can chickpeas', '1 sweet potato', '3 tbsp tahini', '2 tbsp lemon juice'], 'instructions': ['Cook quinoa', 'Roast chickpeas and potato 20 min', 'Make tahini sauce', 'Assemble bowls']},
  {'id': 'r013', 'title': 'Lentil Soup', 'description': 'Hearty red lentil soup with cumin, turmeric and lemon.', 'imageUrl': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=800', 'calories': 320, 'protein': 18.0, 'carbs': 52.0, 'fat': 5.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 30, 'servings': 4, 'difficulty': 'Easy', 'cuisine': 'Middle Eastern', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['lunch', 'vegan', 'high-fiber', 'meal-prep'], 'ingredients': ['2 cups red lentils', '1 onion', '3 garlic cloves', '1 tsp cumin', '1 tsp turmeric', '1 lemon'], 'instructions': ['Saute onion and garlic', 'Add lentils, broth and spices', 'Simmer 25 min', 'Blend half, add lemon']},
  {'id': 'r014', 'title': 'Turkey Wrap', 'description': 'Whole grain wrap with turkey, hummus and fresh veggies.', 'imageUrl': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800', 'calories': 450, 'protein': 32.0, 'carbs': 42.0, 'fat': 16.0, 'prepTimeMinutes': 8, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': false, 'isDairyFree': true, 'tags': ['lunch', 'high-protein', 'quick'], 'ingredients': ['1 whole grain tortilla', '150g turkey slices', '2 tbsp hummus', '1/2 avocado', 'Lettuce, tomato, cucumber'], 'instructions': ['Spread hummus', 'Layer turkey, avocado, veggies', 'Roll and slice']},
  {'id': 'r015', 'title': 'Salmon Poke Bowl', 'description': 'Hawaiian bowl with fresh salmon, edamame and sesame rice.', 'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800', 'calories': 520, 'protein': 36.0, 'carbs': 58.0, 'fat': 14.0, 'prepTimeMinutes': 15, 'cookTimeMinutes': 20, 'servings': 2, 'difficulty': 'Medium', 'cuisine': 'Hawaiian', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['lunch', 'high-protein', 'omega-3'], 'ingredients': ['300g sushi-grade salmon', '1.5 cups sushi rice', '1 cup edamame', '1 avocado', '2 tbsp soy sauce'], 'instructions': ['Cook sushi rice', 'Dice salmon, marinate in soy and sesame', 'Assemble bowls', 'Sprinkle sesame seeds']},
  {'id': 'r016', 'title': 'Baked Salmon with Asparagus', 'description': 'Herb-crusted salmon with roasted asparagus and lemon butter.', 'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800', 'calories': 440, 'protein': 42.0, 'carbs': 8.0, 'fat': 26.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 20, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['dinner', 'high-protein', 'omega-3', 'keto'], 'ingredients': ['2 salmon fillets', '1 bunch asparagus', '2 tbsp butter', '2 garlic cloves', '1 lemon', 'Fresh dill'], 'instructions': ['Preheat oven 200C', 'Place salmon and asparagus on baking sheet', 'Spread garlic butter on salmon', 'Bake 18-20 min']},
  {'id': 'r017', 'title': 'Chicken Tikka Masala', 'description': 'Creamy tomato curry with marinated chicken.', 'imageUrl': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800', 'calories': 520, 'protein': 38.0, 'carbs': 32.0, 'fat': 24.0, 'prepTimeMinutes': 20, 'cookTimeMinutes': 30, 'servings': 4, 'difficulty': 'Medium', 'cuisine': 'Indian', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['dinner', 'high-protein', 'indian'], 'ingredients': ['700g chicken breast', '1 can crushed tomatoes', '1 cup cream', '1 onion', '4 garlic cloves', '1 tbsp garam masala', '1 tsp turmeric'], 'instructions': ['Marinate chicken', 'Saute onion, garlic, ginger', 'Add tomatoes and spices', 'Add chicken, cook through', 'Stir in cream']},
  {'id': 'r018', 'title': 'Spaghetti Bolognese', 'description': 'Classic Italian meat sauce slow-cooked with tomatoes.', 'imageUrl': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800', 'calories': 580, 'protein': 36.0, 'carbs': 64.0, 'fat': 18.0, 'prepTimeMinutes': 15, 'cookTimeMinutes': 45, 'servings': 4, 'difficulty': 'Easy', 'cuisine': 'Italian', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': false, 'isDairyFree': true, 'tags': ['dinner', 'italian', 'family'], 'ingredients': ['400g ground beef', '400g spaghetti', '1 can crushed tomatoes', '1 onion', '3 garlic cloves', 'Red wine', 'Italian herbs'], 'instructions': ['Brown beef with onion', 'Add tomatoes and wine', 'Simmer 40 min', 'Cook pasta and serve']},
  {'id': 'r019', 'title': 'Vegetable Curry', 'description': 'Coconut milk curry with chickpeas, sweet potato and spinach.', 'imageUrl': 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800', 'calories': 420, 'protein': 14.0, 'carbs': 58.0, 'fat': 16.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 25, 'servings': 4, 'difficulty': 'Easy', 'cuisine': 'Indian', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['dinner', 'vegan', 'meal-prep'], 'ingredients': ['1 can chickpeas', '1 sweet potato', '400ml coconut milk', '2 cups spinach', '2 tbsp curry powder'], 'instructions': ['Saute onion and garlic', 'Add curry powder', 'Add potato, tomatoes and coconut milk', 'Simmer 15 min', 'Add chickpeas and spinach']},
  {'id': 'r020', 'title': 'Shakshuka', 'description': 'Eggs poached in spiced tomato sauce with feta.', 'imageUrl': 'https://images.unsplash.com/photo-1590947132387-155cc02f3212?w=800', 'calories': 320, 'protein': 20.0, 'carbs': 22.0, 'fat': 16.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 20, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'Middle Eastern', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['dinner', 'vegetarian', 'one-pan'], 'ingredients': ['4 eggs', '1 can crushed tomatoes', '1 red pepper', '1 onion', '1 tsp cumin', '60g feta'], 'instructions': ['Saute onion and pepper', 'Add spices and tomatoes, simmer 10 min', 'Make wells, crack eggs in', 'Cover and cook 6 min', 'Top with feta']},
  {'id': 'r021', 'title': 'Green Power Smoothie', 'description': 'Spinach, banana and mango smoothie with protein.', 'imageUrl': 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=800', 'calories': 280, 'protein': 20.0, 'carbs': 42.0, 'fat': 4.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['smoothie', 'vegan', 'high-protein'], 'ingredients': ['2 cups spinach', '1 frozen banana', '1 cup frozen mango', '1 scoop vanilla protein', '1.5 cups almond milk'], 'instructions': ['Add all to blender', 'Blend until smooth']},
  {'id': 'r022', 'title': 'Berry Protein Smoothie', 'description': 'Mixed berry smoothie with Greek yogurt and oats.', 'imageUrl': 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800', 'calories': 320, 'protein': 22.0, 'carbs': 48.0, 'fat': 5.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['smoothie', 'high-protein', 'breakfast'], 'ingredients': ['1 cup frozen berries', '1/2 cup Greek yogurt', '1/4 cup oats', '1 cup milk', '1 tbsp honey'], 'instructions': ['Add all to blender', 'Blend until creamy']},
  {'id': 'r023', 'title': 'Chocolate PB Smoothie', 'description': 'Chocolate and peanut butter protein shake.', 'imageUrl': 'https://images.unsplash.com/photo-1572490122747-3e9b81b50b09?w=800', 'calories': 380, 'protein': 28.0, 'carbs': 38.0, 'fat': 14.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['smoothie', 'high-protein', 'post-workout'], 'ingredients': ['1 frozen banana', '2 tbsp peanut butter', '1 scoop chocolate protein', '1 tbsp cocoa powder', '1.5 cups milk'], 'instructions': ['Add all to blender', 'Blend until thick']},
  {'id': 'r024', 'title': 'Apple with Almond Butter', 'description': 'Simple snack with crisp apple and natural almond butter.', 'imageUrl': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=800', 'calories': 200, 'protein': 5.0, 'carbs': 28.0, 'fat': 9.0, 'prepTimeMinutes': 2, 'cookTimeMinutes': 0, 'servings': 1, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['snack', 'vegan', 'quick'], 'ingredients': ['1 apple', '2 tbsp almond butter'], 'instructions': ['Slice apple', 'Serve with almond butter']},
  {'id': 'r025', 'title': 'Protein Energy Balls', 'description': 'No-bake oat and peanut butter energy balls.', 'imageUrl': 'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=800', 'calories': 180, 'protein': 8.0, 'carbs': 22.0, 'fat': 8.0, 'prepTimeMinutes': 15, 'cookTimeMinutes': 0, 'servings': 12, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': false, 'isDairyFree': false, 'tags': ['snack', 'high-protein', 'meal-prep'], 'ingredients': ['1 cup rolled oats', '1/2 cup peanut butter', '1/3 cup honey', '1/2 cup dark chocolate chips', '2 tbsp flaxseed'], 'instructions': ['Mix all ingredients', 'Refrigerate 30 min', 'Roll into 12 balls']},
  {'id': 'r026', 'title': 'Hummus with Veggie Sticks', 'description': 'Creamy hummus with colorful raw vegetable dippers.', 'imageUrl': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=800', 'calories': 160, 'protein': 7.0, 'carbs': 18.0, 'fat': 7.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 0, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'Mediterranean', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['snack', 'vegan', 'no-cook'], 'ingredients': ['4 tbsp hummus', '1 carrot', '1 cucumber', '1 bell pepper', '4 celery stalks'], 'instructions': ['Arrange vegetables on plate', 'Serve with hummus']},
  {'id': 'r027', 'title': 'Grilled Chicken Sweet Potato', 'description': 'Grilled chicken thighs with roasted sweet potato.', 'imageUrl': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c7?w=800', 'calories': 480, 'protein': 38.0, 'carbs': 42.0, 'fat': 16.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 30, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['dinner', 'high-protein', 'meal-prep'], 'ingredients': ['4 chicken thighs', '2 sweet potatoes', '2 tbsp olive oil', '1 tsp paprika'], 'instructions': ['Preheat oven 200C', 'Roast sweet potatoes 20 min', 'Grill chicken 7 min per side', 'Serve together']},
  {'id': 'r028', 'title': 'Black Bean Tacos', 'description': 'Corn tortillas with spiced black beans and salsa.', 'imageUrl': 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=800', 'calories': 380, 'protein': 14.0, 'carbs': 58.0, 'fat': 10.0, 'prepTimeMinutes': 10, 'cookTimeMinutes': 10, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'Mexican', 'isVegetarian': true, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': false, 'tags': ['lunch', 'vegetarian', 'mexican'], 'ingredients': ['1 can black beans', '4 corn tortillas', '1 cup salsa', '1 avocado', '1 lime'], 'instructions': ['Season beans with cumin and lime', 'Warm tortillas', 'Fill with beans', 'Top with salsa and avocado']},
  {'id': 'r029', 'title': 'Tofu Stir-Fry', 'description': 'Crispy tofu with snap peas in ginger-miso sauce.', 'imageUrl': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800', 'calories': 360, 'protein': 22.0, 'carbs': 32.0, 'fat': 16.0, 'prepTimeMinutes': 15, 'cookTimeMinutes': 15, 'servings': 2, 'difficulty': 'Medium', 'cuisine': 'Japanese', 'isVegetarian': true, 'isVegan': true, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['dinner', 'vegan', 'asian'], 'ingredients': ['400g firm tofu', '1 cup snap peas', '1 bell pepper', '2 tbsp miso paste', '2 tbsp soy sauce', '1 tsp ginger'], 'instructions': ['Bake tofu cubes 200C 20 min', 'Stir-fry vegetables 5 min', 'Add tofu and sauce, toss']},
  {'id': 'r030', 'title': 'Lemon Herb Chicken', 'description': 'Pan-seared chicken with lemon, garlic and fresh herbs.', 'imageUrl': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c7?w=800', 'calories': 340, 'protein': 42.0, 'carbs': 4.0, 'fat': 16.0, 'prepTimeMinutes': 5, 'cookTimeMinutes': 20, 'servings': 2, 'difficulty': 'Easy', 'cuisine': 'American', 'isVegetarian': false, 'isVegan': false, 'isGlutenFree': true, 'isDairyFree': true, 'tags': ['dinner', 'high-protein', 'keto', 'quick'], 'ingredients': ['2 chicken breasts', '3 garlic cloves', '1 lemon', '2 tbsp olive oil', 'Fresh thyme'], 'instructions': ['Season chicken', 'Sear 6-7 min per side', 'Add garlic and herbs', 'Finish with lemon juice']},
];

final _workouts = [
  {'id': 'w001', 'name': '30-Day Beginner Fat Loss', 'goal': 'weight_loss', 'level': 'beginner', 'durationWeeks': 4, 'sessionsPerWeek': 3, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800', 'description': 'A progressive plan for beginners to build fitness and burn fat.', 'exercises': ['Walking 30 min', 'Bodyweight squats 3x15', 'Push-ups 3x10', 'Plank 30s x3']},
  {'id': 'w002', 'name': 'Muscle Builder 12-Week', 'goal': 'muscle_gain', 'level': 'intermediate', 'durationWeeks': 12, 'sessionsPerWeek': 4, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 'description': 'Progressive overload program to build lean muscle mass.', 'exercises': ['Bench Press 4x8', 'Squats 4x8', 'Deadlift 3x6', 'Pull-ups 3x10', 'Overhead Press 3x10']},
  {'id': 'w003', 'name': 'HIIT Cardio Blast', 'goal': 'endurance', 'level': 'intermediate', 'durationWeeks': 6, 'sessionsPerWeek': 4, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 'description': 'High-intensity intervals to torch calories and improve cardio.', 'exercises': ['Jump squats 40s', 'Burpees 40s', 'Mountain climbers 40s', 'High knees 40s', 'Rest 20s - repeat 6x']},
  {'id': 'w004', 'name': 'Yoga & Flexibility Flow', 'goal': 'flexibility', 'level': 'beginner', 'durationWeeks': 8, 'sessionsPerWeek': 5, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800', 'description': 'Daily yoga to improve flexibility, posture and reduce stress.', 'exercises': ['Sun Salutation 5x', 'Warrior sequence', 'Hip opener flow', 'Savasana 10 min']},
  {'id': 'w005', 'name': 'Home Bodyweight Shred', 'goal': 'weight_loss', 'level': 'intermediate', 'durationWeeks': 8, 'sessionsPerWeek': 5, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800', 'description': 'Zero equipment home workout for fat loss.', 'exercises': ['Push-ups 4x15', 'Jump squats 4x15', 'Tricep dips 3x12', 'Glute bridges 4x20']},
  {'id': 'w006', 'name': 'Powerlifting Foundation', 'goal': 'strength', 'level': 'advanced', 'durationWeeks': 16, 'sessionsPerWeek': 4, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800', 'description': 'Build maximal strength in squat, bench and deadlift.', 'exercises': ['Squat 5x5', 'Bench Press 5x5', 'Deadlift 3x3']},
  {'id': 'w007', 'name': 'Running for Beginners', 'goal': 'endurance', 'level': 'beginner', 'durationWeeks': 8, 'sessionsPerWeek': 3, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1461897104016-0b3b00cc81ee?w=800', 'description': 'Couch to 5K style program.', 'exercises': ['Week 1: Walk 2 min / Run 1 min x8', 'Week 8: Run 30 min continuously']},
  {'id': 'w008', 'name': 'Core & Abs Sculptor', 'goal': 'toning', 'level': 'beginner', 'durationWeeks': 6, 'sessionsPerWeek': 5, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 'description': 'Daily core routine to strengthen abs and lower back.', 'exercises': ['Plank 60s x3', 'Dead bug 3x12', 'Russian twists 3x20', 'Leg raises 3x15']},
  {'id': 'w009', 'name': 'Upper Body Strength', 'goal': 'muscle_gain', 'level': 'intermediate', 'durationWeeks': 8, 'sessionsPerWeek': 3, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800', 'description': 'Focused upper body targeting chest, back and arms.', 'exercises': ['Pull-ups 4x8', 'Dumbbell Press 4x10', 'Cable Rows 4x12', 'Bicep Curls 3x12']},
  {'id': 'w010', 'name': 'Glutes & Legs Builder', 'goal': 'muscle_gain', 'level': 'intermediate', 'durationWeeks': 8, 'sessionsPerWeek': 3, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800', 'description': 'Dedicated lower body for strong glutes and legs.', 'exercises': ['Barbell Squat 4x8', 'Romanian Deadlift 4x10', 'Hip Thrust 4x12', 'Leg Press 3x15']},
  {'id': 'w011', 'name': 'Pilates for Posture', 'goal': 'flexibility', 'level': 'beginner', 'durationWeeks': 6, 'sessionsPerWeek': 4, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800', 'description': 'Pilates to fix posture and relieve back pain.', 'exercises': ['Hundred exercise', 'Roll-ups 10x', 'Single leg circles', 'Swimming 30s']},
  {'id': 'w012', 'name': 'Athletic Performance', 'goal': 'performance', 'level': 'advanced', 'durationWeeks': 12, 'sessionsPerWeek': 5, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 'description': 'Sport-specific conditioning for speed and power.', 'exercises': ['Sprint intervals 8x100m', 'Box jumps 4x8', 'Agility ladder drills']},
  {'id': 'w013', 'name': 'Lean & Toned 8-Week', 'goal': 'toning', 'level': 'beginner', 'durationWeeks': 8, 'sessionsPerWeek': 4, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800', 'description': 'Strength and cardio combination for a lean physique.', 'exercises': ['Dumbbell circuits 30 min', 'Steady-state cardio 20 min', 'Full-body stretching']},
  {'id': 'w014', 'name': 'Senior Wellness Plan', 'goal': 'general_fitness', 'level': 'beginner', 'durationWeeks': 12, 'sessionsPerWeek': 3, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 'description': 'Low-impact exercise for adults over 50.', 'exercises': ['Chair squats 3x12', 'Wall push-ups 3x10', 'Balance exercises', 'Walking 20 min']},
  {'id': 'w015', 'name': 'Desk Worker De-Stress', 'goal': 'flexibility', 'level': 'beginner', 'durationWeeks': 4, 'sessionsPerWeek': 5, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800', 'description': 'Daily 20-minute routine to undo sitting damage.', 'exercises': ['Chest openers', 'Hip flexor stretch', 'Shoulder rolls', 'Spinal twists']},
  {'id': 'w016', 'name': '21-Day Habit Reset', 'goal': 'general_fitness', 'level': 'beginner', 'durationWeeks': 3, 'sessionsPerWeek': 7, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1461897104016-0b3b00cc81ee?w=800', 'description': 'Build sustainable habits with 20 min daily.', 'exercises': ['Day 1-7: Walking 20 min', 'Day 8-14: Walking + bodyweight', 'Day 15-21: Full workout']},
  {'id': 'w017', 'name': 'Postpartum Recovery', 'goal': 'rehabilitation', 'level': 'beginner', 'durationWeeks': 12, 'sessionsPerWeek': 3, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 'description': 'Gentle postpartum program to rebuild core safely.', 'exercises': ['Diaphragmatic breathing', 'Pelvic floor exercises', 'Gentle walking', 'Modified planks']},
  {'id': 'w018', 'name': 'CrossFit-Style WODs', 'goal': 'endurance', 'level': 'advanced', 'durationWeeks': 8, 'sessionsPerWeek': 5, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800', 'description': '30 different WODs to keep training fresh and intense.', 'exercises': ['Fran: Thrusters + Pull-ups 21-15-9', 'Cindy: AMRAP 20 min', 'Murph: Full hero workout']},
  {'id': 'w019', 'name': 'Swimmer Dryland Training', 'goal': 'performance', 'level': 'intermediate', 'durationWeeks': 8, 'sessionsPerWeek': 3, 'isPremium': true, 'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800', 'description': 'Strength training to improve swimming performance.', 'exercises': ['Lat pulldowns 4x10', 'Tricep dips 3x15', 'Rotator cuff exercises']},
  {'id': 'w020', 'name': '7-Day Detox Movement', 'goal': 'general_fitness', 'level': 'beginner', 'durationWeeks': 1, 'sessionsPerWeek': 7, 'isPremium': false, 'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800', 'description': 'Light daily movement to reset your body.', 'exercises': ['Morning walk 20 min', 'Gentle yoga 20 min', 'Evening stretching 15 min']},
];

final _tips = [
  {'id': 't001', 'title': 'Drink Water Before Meals', 'category': 'hydration', 'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800', 'content': 'Drinking 500ml of water 30 minutes before each meal can reduce calorie intake by up to 13% and aids digestion.'},
  {'id': 't002', 'title': 'Eat Protein First', 'category': 'protein', 'imageUrl': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=800', 'content': 'Starting your meal with protein signals fullness faster, stabilizes blood sugar, and reduces overall calorie consumption.'},
  {'id': 't003', 'title': 'The 80% Rule', 'category': 'mindful-eating', 'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800', 'content': 'Eat until 80% full. It takes 20 minutes for the stomach to signal fullness to the brain — stop before you feel stuffed.'},
  {'id': 't004', 'title': 'Color Your Plate', 'category': 'vegetables', 'imageUrl': 'https://images.unsplash.com/photo-1512003867696-6d5ce6835040?w=800', 'content': 'Aim for 5 different colored vegetables daily. Each color provides different phytonutrients and antioxidants.'},
  {'id': 't005', 'title': 'Meal Prep Sundays', 'category': 'meal-planning', 'imageUrl': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=800', 'content': 'Preparing meals in advance reduces fast food consumption and saves money and time throughout the week.'},
  {'id': 't006', 'title': 'Healthy Fats Are Essential', 'category': 'fats', 'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800', 'content': 'Avocados, olive oil, nuts and fatty fish support brain function, hormones and absorb fat-soluble vitamins A, D, E, K.'},
  {'id': 't007', 'title': 'Fiber Keeps You Full', 'category': 'fiber', 'imageUrl': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=800', 'content': 'Adults need 25-38g fiber daily. It slows digestion, feeds gut bacteria, and reduces risk of heart disease and diabetes.'},
  {'id': 't008', 'title': 'Post-Workout Protein Window', 'category': 'protein', 'imageUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800', 'content': 'Consume 20-40g of protein within 2 hours after training to maximize muscle synthesis and recovery.'},
  {'id': 't009', 'title': 'Limit Ultra-Processed Foods', 'category': 'education', 'imageUrl': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800', 'content': 'Ultra-processed foods override satiety signals. Cook whole foods 80% of the time.'},
  {'id': 't010', 'title': 'Sleep Affects Weight', 'category': 'lifestyle', 'imageUrl': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800', 'content': 'Poor sleep increases ghrelin (hunger hormone) by 15% and decreases leptin (fullness hormone). Aim for 7-9 hours.'},
  {'id': 't011', 'title': 'Protein at Every Meal', 'category': 'protein', 'imageUrl': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=800', 'content': 'Aim for 20-30g of protein per meal to maintain muscle, boost metabolism and stay full between meals.'},
  {'id': 't012', 'title': 'Track Your Food', 'category': 'education', 'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800', 'content': 'People who track food intake lose 50% more weight than those who do not. Awareness is the first step.'},
  {'id': 't013', 'title': 'Omega-3 for Brain Health', 'category': 'fats', 'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800', 'content': 'Eat fatty fish 2-3 times per week. Omega-3s reduce depression risk, improve memory and fight inflammation.'},
  {'id': 't014', 'title': 'Gut Health Matters', 'category': 'gut-health', 'imageUrl': 'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=800', 'content': 'Include fermented foods like yogurt, kefir and kimchi daily. A healthy gut improves immunity, mood and metabolism.'},
  {'id': 't015', 'title': 'Limit Liquid Calories', 'category': 'hydration', 'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800', 'content': 'Sodas and juices add hundreds of hidden calories without satisfying hunger. Replace with water or herbal tea.'},
  {'id': 't016', 'title': 'Chew Slowly', 'category': 'mindful-eating', 'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800', 'content': 'Chewing each bite 20-30 times improves digestion, reduces bloating and helps you eat less overall.'},
  {'id': 't017', 'title': 'Portion Plate Method', 'category': 'education', 'imageUrl': 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=800', 'content': 'Fill half your plate with vegetables, one quarter protein, one quarter complex carbs for every meal.'},
  {'id': 't018', 'title': 'Anti-Inflammatory Foods', 'category': 'immunity', 'imageUrl': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=800', 'content': 'Berries, fatty fish, broccoli, avocado and turmeric reduce chronic inflammation, the root cause of most diseases.'},
  {'id': 't019', 'title': 'Cook with Olive Oil', 'category': 'fats', 'imageUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800', 'content': 'Extra virgin olive oil is rich in oleocanthal, a natural anti-inflammatory compound as potent as ibuprofen.'},
  {'id': 't020', 'title': 'Never Eat in Front of Screens', 'category': 'mindful-eating', 'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800', 'content': 'Distracted eating leads to consuming 25% more calories. Mindful eating improves satisfaction and reduces overeating.'},
  {'id': 't021', 'title': 'Stress Raises Cortisol', 'category': 'lifestyle', 'imageUrl': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800', 'content': 'Chronic stress drives fat storage in the abdomen. Meditation, walking and breathing lower cortisol naturally.'},
  {'id': 't022', 'title': 'Magnesium for Recovery', 'category': 'micronutrients', 'imageUrl': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=800', 'content': 'Over 75% of people are magnesium deficient. Eat leafy greens, nuts and dark chocolate to support sleep and recovery.'},
  {'id': 't023', 'title': 'Time Your Carbs', 'category': 'carbohydrates', 'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 'content': 'Eat most carbs around your workout — before for energy, after for glycogen replenishment and recovery.'},
  {'id': 't024', 'title': 'Vitamin D from Sun and Food', 'category': 'micronutrients', 'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 'content': 'Over 1 billion people are vitamin D deficient. Get 15-20 min of sun daily and eat fatty fish and egg yolks.'},
  {'id': 't025', 'title': 'Intermittent Fasting Basics', 'category': 'meal-planning', 'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800', 'content': 'The 16:8 method can improve insulin sensitivity and support fat loss without strict calorie counting.'},
  {'id': 't026', 'title': 'Do Not Skip Breakfast', 'category': 'meal-planning', 'imageUrl': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800', 'content': 'A protein-rich breakfast reduces cravings, improves concentration and prevents overeating later.'},
  {'id': 't027', 'title': 'Plan Before You Shop', 'category': 'meal-planning', 'imageUrl': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=800', 'content': 'Shopping with a meal plan reduces impulse buying of unhealthy foods and cuts grocery costs by up to 30%.'},
  {'id': 't028', 'title': 'Snack Smart', 'category': 'meal-planning', 'imageUrl': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=800', 'content': 'Best snacks combine protein and fiber: apple with almond butter, Greek yogurt with berries, or hummus with vegetables.'},
  {'id': 't029', 'title': 'Hydration and Performance', 'category': 'hydration', 'imageUrl': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800', 'content': 'Even 2% dehydration reduces cognitive performance by 10% and physical performance by 20%. Drink 35ml per kg daily.'},
  {'id': 't030', 'title': 'Read Nutrition Labels', 'category': 'education', 'imageUrl': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800', 'content': 'Always check serving sizes. Many products list tiny serving sizes to appear low-calorie when a realistic portion is much larger.'},
];

final _coaches = [
  {'id': 'coach001', 'name': 'Sarah Martinez', 'role': 'coach', 'email': 'sarah.martinez@betteryou.app', 'specialization': 'Weight Loss & Nutrition', 'bio': 'Certified personal trainer and nutrition coach with 8 years experience. Specializes in sustainable lifestyle changes, not crash diets.', 'profileImageUrl': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 'rating': 4.9, 'reviewCount': 142, 'pricePerSession': 45.0, 'currency': 'USD', 'availableSlots': ['Monday 9am', 'Wednesday 10am', 'Friday 9am', 'Saturday 11am'], 'tags': ['weight-loss', 'nutrition', 'women-health'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': true, 'xp': 5000, 'level': 10, 'friends': [], 'friendRequests': [], 'badges': ['Top Coach', 'Early Adopter'], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
  {'id': 'coach002', 'name': 'Marcus Johnson', 'role': 'coach', 'email': 'marcus.johnson@betteryou.app', 'specialization': 'Muscle Gain & Strength', 'bio': 'Former competitive bodybuilder turned coach. Helped 200+ clients build muscle naturally. Expert in progressive overload.', 'profileImageUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', 'rating': 4.8, 'reviewCount': 98, 'pricePerSession': 55.0, 'currency': 'USD', 'availableSlots': ['Tuesday 8am', 'Thursday 8am', 'Saturday 9am'], 'tags': ['muscle-gain', 'strength', 'bodybuilding'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': true, 'xp': 4200, 'level': 9, 'friends': [], 'friendRequests': [], 'badges': ['Top Coach'], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
  {'id': 'coach003', 'name': 'Amina Benali', 'role': 'coach', 'email': 'amina.benali@betteryou.app', 'specialization': 'Yoga & Mindful Wellness', 'bio': 'RYT-500 certified yoga instructor integrating mindfulness, breathwork and movement to reduce stress.', 'profileImageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', 'rating': 4.95, 'reviewCount': 76, 'pricePerSession': 40.0, 'currency': 'USD', 'availableSlots': ['Monday 7am', 'Wednesday 7am', 'Sunday 9am'], 'tags': ['yoga', 'mindfulness', 'stress-relief'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': false, 'xp': 3800, 'level': 8, 'friends': [], 'friendRequests': [], 'badges': [], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
];

final _doctors = [
  {'id': 'doctor001', 'name': 'Dr. Karim Mansouri', 'role': 'doctor', 'email': 'dr.mansouri@betteryou.app', 'specialty': 'Sports Medicine & Nutrition', 'bio': 'Board-certified sports medicine physician with 12 years experience. Specializes in performance optimization and evidence-based nutrition therapy.', 'profileImageUrl': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400', 'rating': 4.9, 'reviewCount': 203, 'consultationPrice': 80.0, 'pricePerSession': 80.0, 'currency': 'USD', 'availableSlots': ['Tuesday 10am', 'Thursday 10am', 'Saturday 10am'], 'tags': ['sports-medicine', 'nutrition-therapy'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': true, 'xp': 6000, 'level': 12, 'friends': [], 'friendRequests': [], 'badges': ['Top Doctor', 'Elite Member'], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
  {'id': 'doctor002', 'name': 'Dr. Leila Cherif', 'role': 'doctor', 'email': 'dr.cherif@betteryou.app', 'specialty': 'Endocrinology & Metabolic Health', 'bio': 'Endocrinologist specializing in diabetes, thyroid disorders and metabolic syndrome. Uses a food-first approach.', 'profileImageUrl': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400', 'rating': 4.85, 'reviewCount': 167, 'consultationPrice': 90.0, 'pricePerSession': 90.0, 'currency': 'USD', 'availableSlots': ['Monday 11am', 'Wednesday 11am', 'Friday 3pm'], 'tags': ['diabetes', 'thyroid', 'metabolic-health'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': false, 'xp': 7000, 'level': 14, 'friends': [], 'friendRequests': [], 'badges': ['Top Doctor'], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
  {'id': 'doctor003', 'name': 'Dr. Omar Tabet', 'role': 'doctor', 'email': 'dr.tabet@betteryou.app', 'specialty': 'Gastroenterology & Gut Health', 'bio': 'Gastroenterologist and functional medicine doctor. Helps patients heal IBS and optimize gut microbiome through diet.', 'profileImageUrl': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400', 'rating': 4.88, 'reviewCount': 134, 'consultationPrice': 85.0, 'pricePerSession': 85.0, 'currency': 'USD', 'availableSlots': ['Monday 2pm', 'Wednesday 2pm', 'Saturday 11am'], 'tags': ['gut-health', 'ibs', 'microbiome'], 'isVerified': true, 'verificationStatus': 'approved', 'isFeatured': false, 'xp': 6500, 'level': 13, 'friends': [], 'friendRequests': [], 'badges': [], 'isBanned': false, 'isOnline': false, 'blockedUsers': [], 'isPremium': true, 'appLimits': {}, 'hasCompletedOnboarding': true},
];
