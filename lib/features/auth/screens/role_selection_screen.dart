import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/models/user_model.dart';
import '../../onboarding/screens/coach_onboarding_screen.dart';
import '../../onboarding/screens/doctor_onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/theme/modern_theme.dart';
import '../../onboarding/screens/user_onboarding_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() {
    return _RoleSelectionScreenState();
  }
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _selectRole() async {
    if (_selectedRole == null) return;
    HapticFeedback.mediumImpact();

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(role: _selectedRole!);
    await ref.read(currentUserAsyncProvider.notifier).updateUser(updatedUser);

    if (!mounted) return;

    if (_selectedRole == UserRole.user) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserOnboardingScreen()),
      );
    } else if (_selectedRole == UserRole.coach) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CoachOnboardingScreen()),
      );
    } else if (_selectedRole == UserRole.doctor) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DoctorOnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              
              // Header
              Text(
                'Choose Your Path',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.text,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 8),
              
              Text(
                'Select how you want to use Better You to achieve your goals',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textLight,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
              
              const SizedBox(height: 48),
              
              // Role Cards
              _buildRoleCard(
                UserRole.user,
                'Health Enthusiast',
                'Track habits, get AI guidance, and connect with the community',
                Icons.person,
                const Color(0xFF00A86B),
                delay: 0,
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                UserRole.coach,
                'Coach',
                'Help users achieve their fitness and lifestyle goals',
                Icons.fitness_center,
                const Color(0xFF3B82F6),
                delay: 100,
              ),
              
              const SizedBox(height: 16),
              
              _buildRoleCard(
                UserRole.doctor,
                'Health Professional',
                'Provide medical advice and health consultations',
                Icons.local_hospital,
                const Color(0xFFF97316),
                delay: 200,
              ),
              
              const Spacer(),
              
              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: _selectedRole != null ? _selectRole : null,
                height: 58,
                icon: Icons.arrow_forward,
              ).animate().fadeIn(delay: 400.ms).scale(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    UserRole role,
    String title,
    String description,
    IconData icon,
    Color accentColor, {
    required int delay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: ModernTheme.microAnimationNormal,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.15 : 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: ModernTheme.microAnimationFast,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: ModernTheme.microAnimationFast,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey,
                        width: 2,
                      ),
              ),
              child: Icon(
                Icons.check,
                color: isSelected ? Colors.white : Colors.transparent,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay + 200)).moveX(begin: -30);
  }
}
