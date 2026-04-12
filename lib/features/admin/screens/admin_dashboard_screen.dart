import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/data_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending Coaches'),
              Tab(text: 'Pending Doctors'),
              Tab(text: 'User XP Management'),
              Tab(text: 'Reports & Bans'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PendingList(role: 'coach'),
            _PendingList(role: 'doctor'),
            _UserXPManagement(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

class _UserXPManagement extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UserXPManagement> createState() => _UserXPManagementState();
}

class _UserXPManagementState extends ConsumerState<_UserXPManagement> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _xpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updateXP() async {
    final email = _emailController.text.trim();
    final xpStr = _xpController.text.trim();

    if (email.isEmpty || xpStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and XP')),
      );
      return;
    }

    final xp = int.tryParse(xpStr);
    if (xp == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid XP amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
        }
      } else {
        final userId = userQuery.docs.first.id;
        await ref.read(userRepositoryProvider).addXP(userId, xp);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully added $xp XP to $email')),
          );
          _xpController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'User Email',
              hintText: 'e.g. koussay@gmail.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _xpController,
            decoration: const InputDecoration(
              labelText: 'XP Amount to Add',
              hintText: 'e.g. 10000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateXP,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Add XP'),
            ),
          ),
        ],
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
          .where('role', isEqualTo: role)
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['profileImageUrl'] ?? ''),
              ),
              title: Text(data['name'] ?? 'No name'),
              subtitle: Text(
                '${data['specialty'] ?? ''} • ${data['location'] ?? ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            icon: const Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                            ),
                            onPressed: () => _showWarnDialog(
                              context,
                              ref,
                              report['reportedId'],
                              report['id'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.block, color: Colors.red),
                            onPressed: () => _showBanDialog(
                              context,
                              ref,
                              report['reportedId'],
                              report['id'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () => _resolveReport(
                              context,
                              ref,
                              report['id'],
                              'dismissed',
                            ),
                          ),
                        ],
                      )
                    : Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'resolved'
                              ? Colors.green
                              : Colors.grey,
                        ),
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

  void _showWarnDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String reportId,
  ) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final msg = controller.text.trim();
              if (msg.isEmpty) return;
              await ref.read(userRepositoryProvider).warnUser(userId, msg);
              await ref
                  .read(socialRepositoryProvider).resolveReport(reportId, 'warned');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String reportId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: const Text('Are you sure you want to ban this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(userRepositoryProvider).banUser(userId);
              await ref
                  .read(socialRepositoryProvider).resolveReport(reportId, 'banned');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ban User'),
          ),
        ],
      ),
    );
  }

  void _resolveReport(
    BuildContext context,
    WidgetRef ref,
    String reportId,
    String status,
  ) {
    ref.read(socialRepositoryProvider).resolveReport(reportId, status);
  }
}
