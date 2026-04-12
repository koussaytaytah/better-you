import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../onboarding/screens/coach_onboarding_screen.dart';
import '../../onboarding/screens/doctor_onboarding_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/constants/app_theme.dart';
import '../../onboarding/screens/user_onboarding_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _selectRole() async {
    if (_selectedRole == null) return;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'Choose Your Role',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to use Better You',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                UserRole.user,
                'Simple User',
                'Track habits, get AI advice, connect with community',
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                UserRole.coach,
                'Coach',
                'Help users with fitness and lifestyle guidance',
                Icons.fitness_center,
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                UserRole.doctor,
                'Doctor',
                'Provide medical advice and health consultations',
                Icons.local_hospital,
              ),
              const Spacer(),
              CustomButton(
                text: 'Continue',
                onPressed: _selectedRole != null ? _selectRole : null,
              ),
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
  ) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
