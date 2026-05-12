import 'package:better_you/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/language_provider.dart';
import 'bmi_calculator_screen.dart';
import 'screen_time_management_screen.dart';
import 'progress_calendar_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetWeightController;
  String _goal = 'Maintain Weight';
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final List<String> _goals = [
    'Lose Weight',
    'Maintain Weight',
    'Gain Muscle',
    'Improve Fitness',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _targetWeightController = TextEditingController(
      text: user?.targetWeight?.toString() ?? '',
    );
    _goal = user?.habits?['mainGoal'] ?? 'Maintain Weight';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    HapticFeedback.mediumImpact();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final habits = Map<String, dynamic>.from(user.habits ?? {});
      habits['mainGoal'] = _goal;

      await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
        'name': _nameController.text.trim(),
        'targetWeight': double.tryParse(_targetWeightController.text),
        'habits': habits,
      });

      await ref.read(currentUserAsyncProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadProfilePhoto() async {
    HapticFeedback.lightImpact();
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final file = File(pickedFile.path);
      String? downloadUrl;

      // Try Cloudinary first (free 25 GB tier).
      final cloud = CloudinaryService();
      if (cloud.isConfigured) {
        downloadUrl = await cloud.uploadImage(
          file.path,
          folder: 'profiles/${user.uid}',
        );
      }

      // Fallback to Firebase Storage if Cloudinary is unavailable.
      if (downloadUrl == null) {
        final refPath = FirebaseStorage.instance.ref().child('profiles/${user.uid}.jpg');
        final uploadTask = refPath.putFile(file);
        final snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
        'profileImageUrl': downloadUrl,
      });

      await ref.read(currentUserAsyncProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final logsAsync = ref.watch(dailyLogsProvider(user.uid));
    final nextLevelXp = user.level * 1000;
    final xpProgress = (user.xp / nextLevelXp).clamp(0.0, 1.0);
    final rank = user.getRankName();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getRankColor(rank), _getRankColor(rank).withValues(alpha: 0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar + name
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 38,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                                      child: user.profileImageUrl == null
                                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white))
                                          : null,
                                    ),
                                  ),
                                  if (_isUploadingPhoto)
                                    const Positioned.fill(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  else
                                    Positioned(bottom: 0, right: 0, child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(Icons.camera_alt, size: 13, color: _getRankColor(rank)),
                                    )),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(user.name, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                  child: Text(rank.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                                ),
                                if (user.isPremium) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                                    child: Text('PRO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFFF8F00))),
                                  ),
                                ],
                              ]),
                            ])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // XP bar
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Level ${user.level}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('${user.xp} / $nextLevelXp XP', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: xpProgress, minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats Row ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsRow(user, logsAsync)),

          // ── Badges ────────────────────────────────────────────────────────
          if (user.badges.isNotEmpty) ...[
            SliverToBoxAdapter(child: _buildSectionHeader('Trophy Case', Icons.emoji_events, Colors.amber)),
            SliverToBoxAdapter(child: _buildBadgesGrid(user, isDark: isDark)),
          ],

          // ── Activity Feed ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Recent Activity', Icons.timeline, AppColors.primary)),
          SliverToBoxAdapter(child: _buildActivityFeed(logsAsync, isDark: isDark)),

          // ── Tools ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Health Tools', Icons.health_and_safety, AppColors.success)),
          SliverToBoxAdapter(child: _buildToolsSection(isDark: isDark)),

          // ── Edit Profile ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader('Edit Profile', Icons.edit, AppColors.secondary)),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _buildTextField('Full Name', _nameController, Icons.person_outline, isDark: isDark),
              _buildTextField('Target Weight (kg)', _targetWeightController, Icons.track_changes, isNumber: true, isDark: isDark),
              _buildGoalSelector(),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
              )),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(authServiceProvider).signOut();
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: Text('Logout', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              )),
            ]),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel user, AsyncValue logsAsync) {
    final logCount = logsAsync.when(data: (l) => (l as List).length, loading: () => 0, error: (e, _) => 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _StatChip(label: 'Friends', value: '${user.friends.length}', icon: Icons.people, color: AppColors.primary),
          const SizedBox(width: 10),
          _StatChip(label: 'Days Logged', value: '$logCount', icon: Icons.calendar_today, color: AppColors.success),
          const SizedBox(width: 10),
          _StatChip(label: 'Badges', value: '${user.badges.length}', icon: Icons.military_tech, color: Colors.amber),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildActivityFeed(AsyncValue logsAsync, {required bool isDark}) {
    return logsAsync.when(
      data: (allLogs) {
        final logs = (allLogs as List).take(7).toList();
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
              child: Center(child: Text('No logs yet — start tracking!', style: GoogleFonts.inter(color: AppColors.textLight))),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: logs.asMap().entries.map((e) {
              final log = e.value;
              final score = log.calculateHealthScore();
              final scoreColor = score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.danger;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('$score', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('EEEE, MMM d').format(log.date),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (log.steps != null) _ActivityChip('${_fmtNum(log.steps!.toDouble())} steps', Icons.directions_walk, Colors.orange),
                      if (log.calories != null) _ActivityChip('${log.calories} kcal', Icons.local_fire_department, AppColors.accent),
                      if (log.mood != null) _ActivityChip(_moodEmoji(log.mood!), Icons.mood, const Color(0xFF8B5CF6)),
                    ]),
                  ])),
                  Text('Health\nScore', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight, height: 1.3), textAlign: TextAlign.right),
                ]),
              ).animate().fadeIn(delay: (e.key * 50).ms);
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
      ]),
    );
  }

  Widget _buildBadgesGrid(UserModel user, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
        itemCount: user.badges.length,
        itemBuilder: (context, index) {
          final badge = user.badges[index];
          final config = _getBadgeConfig(badge);
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border.all(color: config.color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: config.color.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(config.icon, color: config.color, size: 26),
              const SizedBox(height: 4),
              Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ).animate().fadeIn(delay: (index * 60).ms).scale(begin: const Offset(0.8, 0.8));
        },
      ),
    );
  }

  String _moodEmoji(String mood) {
    const map = {'happy': '😁', 'good': '😊', 'neutral': '😐', 'sad': '😢', 'angry': '😠'};
    return map[mood] ?? mood;
  }

  String _fmtNum(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toInt().toString();

  Widget _buildToolsSection({required bool isDark}) {
    return Column(
      children: [
        _buildToolTile(
          'Statistics',
          'Detailed health insights',
          Icons.bar_chart_rounded,
          Colors.blue,
          () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
          },
          isDark: isDark,
        ),
        _buildToolTile(
          'BMI Calculator',
          'Track your body index',
          Icons.monitor_weight_rounded,
          Colors.teal,
          () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BMICalculatorScreen()),
            );
          },
          isDark: isDark,
        ),
        _buildToolTile(
          'Screen Time',
          'Manage app limits',
          Icons.screen_lock_portrait_rounded,
          Colors.purple,
          () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ScreenTimeManagementScreen(),
              ),
            );
          },
          isDark: isDark,
        ),
        _buildToolTile(
          'History Calendar',
          'View your progress',
          Icons.calendar_month_rounded,
          Colors.green,
          () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressCalendarScreen()),
            );
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildToolTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isDark,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 24,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 12, color: isDark ? AppColors.darkTextLight : Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: isDark ? AppColors.darkTextLight : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextLight : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      borderRadius: 24,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _goal,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.poppins(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          items: _goals
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (val) => setState(() => _goal = val!),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLanguageSelector() {
    final currentLocale = ref.watch(languageProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: AppColors.primary),
          const SizedBox(width: 16),
          const Text('Language', style: TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          TextButton(
            onPressed: () {
              final next = currentLocale.languageCode == 'en' ? 'fr' : 'en';
              ref.read(languageProvider.notifier).setLanguage(next);
            },
            child: Text(
              currentLocale.languageCode == 'en' ? 'English' : 'Français',
            ),
          ),
        ],
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

  _BadgeConfig _getBadgeConfig(String badge) {
    if (badge.contains('Aquaman')) return _BadgeConfig(Icons.water_drop, Colors.blue);
    if (badge.contains('Iron Will')) return _BadgeConfig(Icons.smoke_free, Colors.redAccent);
    if (badge.contains('Step Master')) return _BadgeConfig(Icons.directions_walk, Colors.green);
    if (badge.contains('Early Bird')) return _BadgeConfig(Icons.wb_sunny, Colors.orange);
    if (badge.contains('Post Star')) return _BadgeConfig(Icons.star, Colors.amber);
    return _BadgeConfig(Icons.emoji_events, AppColors.primary);
  }
}

class _BadgeConfig {
  final IconData icon;
  final Color color;
  _BadgeConfig(this.icon, this.color);
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
        ]),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ActivityChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
