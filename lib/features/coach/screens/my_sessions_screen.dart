import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';

class MySessionsScreen extends StatelessWidget {
  final String userId;

  const MySessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Sessions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SessionsList(userId: userId, status: 'pending'),
            _SessionsList(userId: userId, status: 'completed'),
            _SessionsList(userId: userId, status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  final String userId;
  final String status;

  const _SessionsList({required this.userId, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No $status sessions', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                const SizedBox(height: 8),
                if (status == 'pending')
                  const Text('Book a session with a coach to get started!', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final bookingId = docs[index].id;
            return _SessionCard(data: data, bookingId: bookingId, status: status);
          },
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final String status;

  const _SessionCard({required this.data, required this.bookingId, required this.status});

  Color get _statusColor {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'completed': return Icons.check_circle_outline;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['coachImageUrl'] as String? ?? '';
    final date = (data['date'] as Timestamp?)?.toDate();
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : 'TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['coachName'] ?? 'Coach', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(data['coachSpecialization'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _InfoChip(icon: Icons.calendar_today, label: dateStr),
                const SizedBox(width: 10),
                _InfoChip(icon: Icons.access_time, label: data['slot'] ?? 'TBD'),
                const SizedBox(width: 10),
                _InfoChip(icon: Icons.attach_money, label: '\$${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}'),
              ],
            ),
            if ((data['note'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(data['note'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(context),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message_outlined, size: 16),
                      label: const Text('Message'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'completed') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewDialog(context),
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text('Leave a Review'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('Are you sure you want to cancel this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session cancelled.')));
      }
    }
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate your session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey[300]),
                  onPressed: () => setDialogState(() => rating = i + 1),
                )),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                  'review': {'rating': rating, 'comment': controller.text.trim()},
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted! Thank you.')));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }
}
