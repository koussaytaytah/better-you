import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/repositories/user_repository.dart';

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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.launch),
              tooltip: 'Switch to User Mode',
              onPressed: () => context.push('/dashboard'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending Coaches'),
              Tab(text: 'Pending Doctors'),
              Tab(text: 'User Management'),
              Tab(text: 'Reports & Bans'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildQuickStats(context, ref),
            Expanded(
              child: TabBarView(
                children: [
                  _PendingList(role: 'coach'),
                  _PendingList(role: 'doctor'),
                  _UserManagementTab(),
                  _ReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        final totalUsers = snapshot.data?.docs.length ?? 0;
        final pendingVerifications = snapshot.data?.docs.where((d) => (d.data() as Map)['verificationStatus'] == 'pending').length ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _statCard(context, 'Total Users', totalUsers.toString(), Icons.people, Colors.blue),
              const SizedBox(width: 12),
              _statCard(context, 'Pending', pendingVerifications.toString(), Icons.verified_user, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
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
                      activeColor: Colors.red,
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
                      if (confirm == true) {
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
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isBanned = data['isBanned'] == true;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBanned ? Colors.grey : Colors.blue,
                      child: Text(data['name']?[0] ?? '?', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(data['name'] ?? 'No Name'),
                    subtitle: Text(data['email'] ?? 'No Email'),
                    trailing: isBanned ? const Icon(Icons.block, color: Colors.red) : null,
                    onTap: () => _showUserDialog(doc.id, data),
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

        if (docs.isEmpty) return Center(child: Text('No pending ${role}s.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['profileImageUrl'] ?? ''),
              ),
              title: Text(data['name'] ?? 'No name'),
              subtitle: Text('${data['specialty'] ?? ''} • ${data['location'] ?? ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.description, color: Colors.blue),
                    onPressed: () => _showCertificate(context, data['certificateImageUrl'] ?? ''),
                    tooltip: 'View Certificate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveUser(docs[index].id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectUser(docs[index].id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _approveUser(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'verificationStatus': 'approved',
      'isVerified': true,
    });
  }

  void _rejectUser(String uid) {
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
