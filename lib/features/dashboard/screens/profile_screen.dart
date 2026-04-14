import 'package:better_you/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';
import '../../../shared/providers/language_provider.dart';
import '../../../shared/models/challenge_model.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/widgets/responsive_wrapper.dart';
import 'bmi_calculator_screen.dart';
import 'screen_time_management_screen.dart';
import 'progress_calendar_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);
    
    try {
      final file = File(pickedFile.path);
      final refPath = FirebaseStorage.instance.ref().child('profiles/${user.uid}.jpg');
      
      final uploadTask = refPath.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: ResponsiveWrapper(
          maxWidth: 800,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildGamificationSection(user),
                const SizedBox(height: 32),
                _buildSectionTitle('Health Tools'),
                const SizedBox(height: 16),
                _buildToolsSection(),
                const SizedBox(height: 32),
                _buildSectionTitle('Personal Settings'),
                const SizedBox(height: 16),
                _buildInfoCard([
                  _buildTextField(
                    'Full Name',
                    _nameController,
                    Icons.person_outline,
                  ),
                  _buildTextField(
                    'Target Weight (kg)',
                    _targetWeightController,
                    Icons.track_changes,
                    isNumber: true,
                  ),
                ]),
                const SizedBox(height: 32),
                _buildSectionTitle('Health Goal'),
                const SizedBox(height: 16),
                _buildGoalSelector(),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    if (user == null) return const SizedBox.shrink();
    return Row(
      children: [
        GestureDetector(
          onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user.profileImageUrl != null 
                      ? NetworkImage(user.profileImageUrl!) 
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              if (_isUploadingPhoto)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                user.email,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildToolsSection() {
    return Column(
      children: [
        _buildToolTile(
          'Statistics',
          'Detailed health insights',
          Icons.bar_chart_rounded,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
        _buildToolTile(
          'BMI Calculator',
          'Track your body index',
          Icons.monitor_weight_rounded,
          Colors.teal,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BMICalculatorScreen()),
          ),
        ),
        _buildToolTile(
          'Screen Time',
          'Manage app limits',
          Icons.screen_lock_portrait_rounded,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScreenTimeManagementScreen(),
            ),
          ),
        ),
        _buildToolTile(
          'History Calendar',
          'View your progress',
          Icons.calendar_month_rounded,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressCalendarScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildToolTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
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
              color: Colors.grey[600],
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
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.white.withValues(alpha: 0.05),
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
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white,
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

  Widget _buildGamificationSection(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    final nextLevelXp = user.level * 1000;
    final progress = user.xp / nextLevelXp;
    final rank = user.getRankName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level & Rank Card
        GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Level ${user.level}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: _getRankGradient(rank),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rank.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.military_tech, size: 48, color: _getRankColor(rank)),
                ],
              ),
              const SizedBox(height: 16),
              Text('${user.xp} / $nextLevelXp XP', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(_getRankColor(rank)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (user.badges.isNotEmpty) ...[
          Text('Trophy Case', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: user.badges.length,
            itemBuilder: (context, index) {
              final badge = user.badges[index];
              final config = _getBadgeConfig(badge);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [config.color.withValues(alpha: 0.2), config.color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: config.color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(config.icon, color: config.color, size: 24),
                    const Spacer(),
                    Text(
                      badge,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
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

  LinearGradient _getRankGradient(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8C5622)]);
      case 'silver': return const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]);
      case 'gold': return const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)]);
      case 'platinum': return const LinearGradient(colors: [Color(0xFFE5E4E2), Color(0xFF9E9E9E)]);
      case 'diamond': return const LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFF007FFF)]);
      case 'master': return const LinearGradient(colors: [Color(0xFFFF4081), Color(0xFFE040FB)]);
      default: return const LinearGradient(colors: [AppColors.primary, Colors.teal]);
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
