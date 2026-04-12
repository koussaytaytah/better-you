import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topUsersAsync = ref.watch(topUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Global Leaderboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: topUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = currentUser?.uid == user.uid;
              
              return _buildLeaderboardTile(context, user, index + 1, isMe);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading leaderboard: $err')),
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, UserModel user, int rank, bool isMe) {
    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
    else if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    else if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze
    else rankColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: () {
        if (!isMe) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rank <= 3 ? rankColor : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: rank <= 3 ? rankColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '${user.name} (You)' : user.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.getRankName(),
                    style: TextStyle(color: _getRankColor(user.getRankName()), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Lvl ${user.level}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  '${user.xp} XP',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFB4B4B4);
      case 'gold': return const Color(0xFFFFD700);
      case 'platinum': return const Color(0xFFE5E4E2);
      case 'diamond': return const Color(0xFFb9f2ff);
      case 'master': return const Color(0xFFFF4081);
      default: return AppColors.primary;
    }
  }
}
