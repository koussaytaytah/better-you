import 'dart:io' show File;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import 'notifications_screen.dart';
import 'friends_screen.dart';
import 'user_profile_screen.dart';
import 'global_chat_screen.dart';
import 'leaderboard_screen.dart';
import 'post_detail_screen.dart';
import 'group_quests_screen.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() =>
      _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  final _postController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _postController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickPostImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _createPost() async {
    final postContent = _postController.text.trim();
    if (postContent.isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        AppLogger.e('User is null during post creation');
        return;
      }

      final postId = const Uuid().v4();
      String? imageUrl;

      if (_selectedImage != null) {
        AppLogger.i('Uploading image for post $postId...');
        imageUrl = await ref
            .read(postRepositoryProvider)
            .uploadPostImage(_selectedImage!, postId);

        if (imageUrl == null) {
          AppLogger.w('Image upload failed, proceeding without image');
        } else {
          AppLogger.i('Image uploaded successfully: $imageUrl');
        }
      }

      final newPost = Post(
        id: postId,
        userId: user.uid,
        userName: user.name,
        userRole: user.role.name.toUpperCase(),
        content: postContent,
        likes: [],
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      AppLogger.i('Saving post to Firestore: $postId');
      await ref.read(postRepositoryProvider).addPost(newPost);

      // Award XP for posting (10 XP)
      await ref.read(userRepositoryProvider).addXP(user.uid, 10);
      await ref.read(userRepositoryProvider).checkAndAwardBadges(user.uid);

      if (mounted) {
        _postController.clear();
        setState(() {
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
      }
    } catch (e, stack) {
      AppLogger.e('Error in _createPost', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showPostOptions(Post post) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.userId != currentUser.uid) ...[
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User?'),
                    content: Text(
                      'You will no longer see posts or messages from ${post.userName}.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Block',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(userRepositoryProvider)
                      .blockUser(currentUser.uid, post.userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${post.userName} blocked')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: const Text('Report Post'),
              onTap: () async {
                Navigator.pop(context);
                final reasonController = TextEditingController();
                final reported = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Report Content'),
                    content: TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: 'Reason for reporting...',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Report'),
                      ),
                    ],
                  ),
                );

                if (reported == true && reasonController.text.isNotEmpty) {
                  await ref
                      .read(userRepositoryProvider)
                      .reportUser(
                        reporterId: currentUser.uid,
                        reportedId: post.userId,
                        postId: post.id,
                        reason: reasonController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted')),
                    );
                  }
                }
              },
            ),
          ],
          if (post.userId == currentUser.uid ||
              currentUser.role == UserRole.doctor)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Post'),
              onTap: () {
                // Add delete logic if needed
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // ...
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              )
            : Text(
                'Community Feed',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                ref
                    .watch(notificationsProvider)
                    .when(
                      data: (notifs) {
                        final unreadCount = notifs
                            .where((n) => !(n['isRead'] ?? false))
                            .length;
                        if (unreadCount == 0) return const SizedBox();
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                    ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_motion_outlined),
            tooltip: 'Group Quests',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupQuestsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GlobalChatScreen()),
            ),
          ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : Column(
              children: [
                _buildCreatePostArea(isDark),
                Expanded(
                  child: postsAsync.when(
                    data: (posts) {
                      if (posts.isEmpty) {
                        return const Center(
                          child: Text('No posts yet. Be the first!'),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(postsProvider);
                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, idx) {
                            final postItem = posts[idx];
                            if (currentUser != null &&
                                currentUser.blockedUsers.contains(
                                  postItem.userId,
                                )) {
                              return const SizedBox.shrink();
                            }
                            return _buildPostCard(postItem, isDark);
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    final searchQ = _searchController.text.trim();
    return StreamBuilder<List<UserModel>>(
      stream: ref.read(userRepositoryProvider).searchUsers(searchQ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final usersList = snapshot.data!;
        if (usersList.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return ListView.builder(
          itemCount: usersList.length,
          itemBuilder: (context, idx) {
            final userItem = usersList[idx];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(
                  userItem.role,
                ).withValues(alpha: 0.1),
                child: Text(
                  userItem.name.isNotEmpty
                      ? userItem.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: _getRoleColor(userItem.role)),
                ),
              ),
              title: Text(
                userItem.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                userItem.role.name.toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(userItem.role),
                  fontSize: 12,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: userItem.uid),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return Colors.blue;
      case UserRole.coach:
        return Colors.orange;
      case UserRole.admin:
        return Colors.red;
      case UserRole.user:
        return AppColors.primary;
    }
  }

  Widget _buildCreatePostArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your progress...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textLight,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _pickPostImage,
                icon: Icon(
                  Icons.image_outlined,
                  color: _selectedImage != null
                      ? AppColors.primary
                      : (isDark ? Colors.white54 : AppColors.textLight),
                ),
              ),
              const SizedBox(width: 8),
              _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _createPost,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
            ],
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, bool isDark) {
    final currentU = ref.watch(currentUserProvider);
    final isLiked = currentU != null && post.likes.contains(currentU.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: post.userId),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      post.userName.isNotEmpty
                          ? post.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.text,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d').format(post.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: (isDark ? Colors.white : AppColors.text)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public,
                            size: 12,
                            color: (isDark ? Colors.white : AppColors.text)
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _showPostOptions(post),
                    color: (isDark ? Colors.white : AppColors.text).withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Text
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                post.content,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.text,
                ),
              ),
            ),

          // Content Image
          if (post.imageUrl != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: post.id),
                ),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.red.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (post.likes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : AppColors.text)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${post.likes.length} comments', // Placeholder for actual comment count
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.white : AppColors.text).withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Interaction Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      if (currentU != null) {
                        ref
                            .read(postRepositoryProvider).likePost(
                              post.id,
                              currentU.uid,
                              currentU.name,
                              post.userId,
                            );
                      }
                    },
                    icon: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 20,
                      color: isLiked
                          ? Colors.blue
                          : (isDark ? Colors.white : AppColors.text).withValues(
                              alpha: 0.6,
                            ),
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color: isLiked
                            ? Colors.blue
                            : (isDark ? Colors.white : AppColors.text)
                                  .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showComments(post.id, post.userId),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: (isDark ? Colors.white : AppColors.text)
                          .withValues(alpha: 0.6),
                    ),
                    label: Text(
                      'Comment',
                      style: TextStyle(
                        color: (isDark ? Colors.white : AppColors.text)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      final shareText =
                          '${post.userName} shared: ${post.content}\n\nJoin Better You to see more!';
                      Share.share(shareText);
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: (isDark ? Colors.white : AppColors.text)
                          .withValues(alpha: 0.6),
                    ),
                    label: Text(
                      'Share',
                      style: TextStyle(
                        color: (isDark ? Colors.white : AppColors.text)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(String postId, String postOwnerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Comments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ref
                      .read(postRepositoryProvider).getComments(postId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (c['userName'] as String).isNotEmpty
                                  ? (c['userName'] as String)[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            c['userName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            c['content'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCommentInput(postId, postOwnerId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(String postId, String postOwnerId) {
    final controller = TextEditingController();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref
                    .read(postRepositoryProvider)
                    .addCommentWithNotify(
                      postId: postId,
                      userId: user.uid,
                      userName: user.name,
                      content: controller.text.trim(),
                      postOwnerId: postOwnerId,
                    );
                controller.clear();
              }
            },
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
