import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import 'book_session_screen.dart';

class CoachProfileScreen extends ConsumerWidget {
  final String coachId;
  final Map<String, dynamic> data;

  const CoachProfileScreen({super.key, required this.coachId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = (data['rating'] as num?)?.toDouble() ?? 4.5;
    final reviews = data['reviewCount'] ?? 0;
    final price = (data['pricePerSession'] as num?)?.toDouble() ?? 0;
    final imageUrl = data['profileImageUrl'] as String? ?? '';
    final tags = List<String>.from(data['tags'] ?? []);
    final slots = List<String>.from(data['availableSlots'] ?? []);
    final bio = data['bio'] as String? ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(color: AppColors.primary.withValues(alpha: 0.2)))
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)]),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(data['name'] ?? 'Coach', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24)),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: AppColors.primary, size: 22),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['specialization'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$$price', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('per session', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatBadge(icon: Icons.star_rounded, value: '$rating', label: 'Rating', color: Colors.amber),
                      const SizedBox(width: 12),
                      _StatBadge(icon: Icons.reviews_outlined, value: '$reviews', label: 'Reviews', color: AppColors.primary),
                      const SizedBox(width: 12),
                      _StatBadge(icon: Icons.calendar_month, value: '${slots.length}', label: 'Slots/wk', color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('About', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(bio, style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14)),
                  const SizedBox(height: 20),
                  if (tags.isNotEmpty) ...[
                    Text('Specialties', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((t) => Chip(
                        label: Text(t.replaceAll('-', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                        labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (slots.isNotEmpty) ...[
                    Text('Available Times', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(s, style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _ReviewsSection(coachId: coachId),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Consumer(
            builder: (context, ref, _) {
              return FilledButton.icon(
                onPressed: () {
                  final userAsync = ref.read(currentUserAsyncProvider);
                  final user = userAsync.value;
                  if (user == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookSessionScreen(coachId: coachId, coachData: data, userId: user.uid),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Book a Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String coachId;

  const _ReviewsSection({required this.coachId});

  Stream<List<Map<String, dynamic>>> get _stream {
    return Stream.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Reviews', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text('No reviews yet. Be the first to book!', style: TextStyle(color: Colors.grey))),
              );
            }
            return Column(
              children: reviews.map((r) => _ReviewTile(review: r)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withValues(alpha: 0.2), child: Text(review['userName']?[0] ?? '?')),
              const SizedBox(width: 10),
              Expanded(child: Text(review['userName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold))),
              Row(
                children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (review['rating'] ?? 5) ? Colors.amber : Colors.grey[300])),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }
}
