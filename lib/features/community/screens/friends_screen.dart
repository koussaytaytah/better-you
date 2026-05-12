import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              'Friends',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Friends'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFriendsList(context, ref, user, isDark),
            _buildRequestsList(context, ref, requestsAsync, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    bool isDark,
  ) {
    if (user == null || user.friends.isEmpty) {
      return const Center(
        child: Text('No friends yet. Search for people in the feed!'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: user.friends.length,
        itemBuilder: (context, index) {
          final friendId = user.friends[index];
          final friendAsync = ref.watch(userProvider(friendId));

          return friendAsync.when(
            data: (friend) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                ),
              ),
              title: Text(
                friend.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                friend.role.name.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: AppColors.primary),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: friend.uid),
                  ),
                );
              },
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<UserModel>> requestsAsync,
    bool isDark,
  ) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(friendRequestsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requester = requests[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    requester.name.isNotEmpty
                        ? requester.name[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(
                  requester.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Sent you a friend request'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final currentUser = ref.read(currentUserProvider);
                        if (currentUser != null) {
                          await ref
                              .read(userRepositoryProvider).acceptFriendRequest(
                                currentUser.uid,
                                requester.uid,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Accepted ${requester.name}\'s request!',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
