import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import 'coach_profile_screen.dart';

final _coachFilterProvider = StateProvider<String>((ref) => 'all');

class BrowseCoachesScreen extends ConsumerWidget {
  const BrowseCoachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_coachFilterProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              width: 1,
            ),
          ),
          child: Text(
            'Find a Coach',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _SearchHeader(filter: filter, ref: ref),
          Expanded(child: _CoachList(filter: filter)),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final String filter;
  final WidgetRef ref;

  const _SearchHeader({required this.filter, required this.ref});

  static const _tags = ['all', 'weight-loss', 'muscle-gain', 'yoga', 'strength', 'nutrition'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.sports, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expert Coaches', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Verified professionals ready to guide you', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _tags.length,
            separatorBuilder: (_, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tag = _tags[i];
              final isSelected = filter == tag;
              return FilterChip(
                label: Text(tag == 'all' ? 'All' : tag.replaceAll('-', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.lightImpact();
                  ref.read(_coachFilterProvider.notifier).state = tag;
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CoachList extends StatelessWidget {
  final String filter;

  const _CoachList({required this.filter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('verificationStatus', isEqualTo: 'approved');

    if (filter != 'all') {
      query = query.where('tags', arrayContains: filter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
                Icon(Icons.sports_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No coaches found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final coachId = docs[index].id;
            return _CoachCard(coachId: coachId, data: data)
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                .slideX(begin: 0.1);
          },
        );
      },
    );
  }
}

class _CoachCard extends StatelessWidget {
  final String coachId;
  final Map<String, dynamic> data;

  const _CoachCard({required this.coachId, required this.data});

  @override
  Widget build(BuildContext context) {
    final rating = (data['rating'] as num?)?.toDouble() ?? 4.5;
    final reviews = data['reviewCount'] ?? 0;
    final price = (data['pricePerSession'] as num?)?.toDouble() ?? 0;
    final imageUrl = data['profileImageUrl'] as String? ?? '';
    final tags = List<String>.from(data['tags'] ?? []);
    final isFeatured = data['isFeatured'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CoachProfileScreen(coachId: coachId, data: data)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.person, size: 64)))
                    : Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.person, size: 64)),
                if (isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Featured', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(data['name'] ?? 'Coach', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
                      ),
                      Icon(Icons.verified, color: AppColors.primary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['specialization'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('($reviews reviews)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const Spacer(),
                      Text('\$$price/session', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.take(3).map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CoachProfileScreen(coachId: coachId, data: data)),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('View Profile & Book'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
