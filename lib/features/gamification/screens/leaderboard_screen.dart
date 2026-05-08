import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';

final leaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .orderBy('xp', descending: true)
      .limit(50)
      .get();
  return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF00BCD4)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text('🏆', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Top 50 Players',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          leaderboardAsync.when(
            data: (users) {
              // Find current user rank
              final myRank = users.indexWhere((u) => u.uid == currentUser?.uid);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Top 3 podium
                    if (index == 0 && users.length >= 3) {
                      return _buildPodium(users, isDark).animate().fadeIn(duration: 600.ms);
                    }

                    // My rank banner
                    if (index == 1 && myRank > 3) {
                      return _buildMyRankBanner(currentUser!, myRank + 1, isDark)
                          .animate()
                          .fadeIn(delay: 200.ms);
                    }

                    // List items (skip top 3 already shown in podium)
                    final listIndex = (myRank > 3) ? index - 2 + 3 : index - 1 + 3;
                    if (listIndex >= users.length) return null;

                    return _buildRankTile(
                      context,
                      users[listIndex],
                      listIndex + 1,
                      users[listIndex].uid == currentUser?.uid,
                      isDark,
                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
                  },
                  childCount: (users.length - 3) + (myRank > 3 ? 2 : 1),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<UserModel> users, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _buildPodiumItem(users[1], 2, 80, const Color(0xFFC0C0C0)),
          // 1st place
          _buildPodiumItem(users[0], 1, 110, const Color(0xFFFFD700)),
          // 3rd place
          _buildPodiumItem(users[2], 3, 60, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(UserModel user, int rank, double height, Color medalColor) {
    final emojis = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 32 : 26,
          backgroundColor: medalColor.withValues(alpha: 0.2),
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: rank == 1 ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: medalColor,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          user.name.split(' ').first,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user.xp} XP',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: rank == 1 ? 80 : 65,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(emojis[rank]!, style: const TextStyle(fontSize: 24)),
        ),
      ],
    );
  }

  Widget _buildMyRankBanner(UserModel user, int rank, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00BCD4)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            'Your Rank: #$rank',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            '${user.xp} XP',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTile(
    BuildContext context,
    UserModel user,
    int rank,
    bool isMe,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: rank <= 10 ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isMe ? '${user.name} (You)' : user.name,
                style: GoogleFonts.poppins(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildRankBadge(user.getRankName()),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              'Level ${user.level}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(width: 8),
            if (user.badges.isNotEmpty)
              Text(
                '${user.badges.length} badges',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${user.xp}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
            Text(
              'XP',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String rankName) {
    final colors = {
      'Bronze': const Color(0xFFCD7F32),
      'Silver': const Color(0xFFC0C0C0),
      'Gold': const Color(0xFFFFD700),
      'Platinum': const Color(0xFF00BCD4),
      'Diamond': const Color(0xFF6C63FF),
      'Master': const Color(0xFFFF6B6B),
    };

    final color = colors[rankName] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        rankName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
