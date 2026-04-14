import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        title: Text(
          'Champions Leaderboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: topUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final podiumUsers = users.length >= 3 ? users.sublist(0, 3) : users;
          final otherUsers = users.length > 3 ? users.sublist(3) : [];

          // Find current user's rank if not in top list
          final myRankIndex = users.indexWhere((u) => u.uid == currentUser?.uid);
          final myRank = myRankIndex != -1 ? myRankIndex + 1 : null;

          return Stack(
            children: [
              Column(
                children: [
                  _buildPodium(context, podiumUsers),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                      itemCount: otherUsers.length,
                      itemBuilder: (context, index) {
                        final user = otherUsers[index];
                        final rank = index + 4;
                        final isMe = currentUser?.uid == user.uid;
                        return _buildLeaderboardTile(context, user, rank, isMe);
                      },
                    ),
                  ),
                ],
              ),
              if (myRank != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyMyRank(context, currentUser!, myRank),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<UserModel> podium) {
    if (podium.isEmpty) return const SizedBox();

    // Order: [2nd, 1st, 3rd] for display
    final Map<int, UserModel?> usersByRank = {
      1: podium.isNotEmpty ? podium[0] : null,
      2: podium.length > 1 ? podium[1] : null,
      3: podium.length > 2 ? podium[2] : null,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (usersByRank[2] != null) _buildPodiumPlace(context, usersByRank[2]!, 2),
          if (usersByRank[1] != null) _buildPodiumPlace(context, usersByRank[1]!, 1),
          if (usersByRank[3] != null) _buildPodiumPlace(context, usersByRank[3]!, 3),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(BuildContext context, UserModel user, int rank) {
    final double height = rank == 1 ? 160 : (rank == 2 ? 130 : 110);
    final Color color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 40 : 32,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                user.name[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: rank == 1 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '$rank',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 12),
        Text(
          user.name.split(' ').first,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text('${user.xp} XP', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: 70,
          height: height - 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Icon(Icons.workspace_premium, color: Colors.white.withValues(alpha: 0.5), size: 30),
          ),
        ).animate().slideY(begin: 1.0, duration: 800.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildStickyMyRank(BuildContext context, UserModel user, int rank) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Standing',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                ),
                Text(
                  user.name,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lvl ${user.level}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '${user.xp} XP',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0);
  }

  Widget _buildLeaderboardTile(BuildContext context, UserModel user, int rank, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isMe)
             BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: ListTile(
        onTap: () {
           if (!isMe) Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)));
        },
        leading: SizedBox(
          width: 40,
          child: Text(
            '#$rank',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        title: Text(user.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(user.getRankName(), style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Lvl ${user.level}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${user.xp} XP', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
