import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/data_provider.dart';

class BMICalculatorScreen extends ConsumerStatefulWidget {
  final double? initialWeight;
  final double? initialHeight;

  const BMICalculatorScreen({
    super.key,
    this.initialWeight,
    this.initialHeight,
  });

  @override
  ConsumerState<BMICalculatorScreen> createState() =>
      _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends ConsumerState<BMICalculatorScreen> {
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  String _gender = 'Male';
  String _activityLevel = 'No Exercise (Sedentary)';
  double? _bmi;
  double? _dailyCalories;
  String _bmiStatus = '';
  Color _statusColor = AppColors.text;

  final Map<String, double> _activityFactors = {
    'No Exercise (Sedentary)': 1.2,
    '1-3 times per week (Lightly Active)': 1.375,
    '3-5 times per week (Moderately Active)': 1.55,
    '6-7 times per week (Very Active)': 1.725,
    'Every day + physical work (Extra Active)': 1.9,
  };

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.initialHeight?.toString() ?? '',
    );
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _calculate() {
    final double? weight = double.tryParse(_weightController.text);
    final double? height = double.tryParse(_heightController.text);
    final int? age = int.tryParse(_ageController.text);

    if (weight != null && height != null && height > 0) {
      // BMI = weight(kg) / height(m)^2
      // Assuming height is in cm
      final heightInMeters = height / 100;
      setState(() {
        _bmi = weight / (heightInMeters * heightInMeters);

        if (_bmi! < 18.5) {
          _bmiStatus = 'Underweight';
          _statusColor = Colors.orange;
        } else if (_bmi! < 25) {
          _bmiStatus = 'Normal';
          _statusColor = AppColors.success;
        } else if (_bmi! < 30) {
          _bmiStatus = 'Overweight';
          _statusColor = Colors.orange;
        } else {
          _bmiStatus = 'Obese';
          _statusColor = AppColors.danger;
        }

        // BMR Calculation (Mifflin-St Jeor Equation)
        if (age != null) {
          if (_gender == 'Male') {
            _dailyCalories = (10 * weight) + (6.25 * height) - (5 * age) + 5;
          } else {
            _dailyCalories = (10 * weight) + (6.25 * height) - (5 * age) - 161;
          }
          // Multiply by activity factor
          final factor = _activityFactors[_activityLevel] ?? 1.2;
          _dailyCalories = _dailyCalories! * factor;
        }
      });
    }
  }

  Future<void> _saveToProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final double? weight = double.tryParse(_weightController.text);
      final double? height = double.tryParse(_heightController.text);
      final int? age = int.tryParse(_ageController.text);

      final Map<String, dynamic> habits = Map<String, dynamic>.from(
        user.habits ?? {},
      );
      if (_dailyCalories != null) {
        habits['targetCalories'] = _dailyCalories!.toInt();
      }

      await ref.read(userRepositoryProvider).updateUserProfile(user.uid, {
        'weight': weight,
        'height': height,
        'age': age,
        'habits': habits,
      });

      // Refresh the local user state
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
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'BMI & Calorie Calculator',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate your body mass index and daily calorie needs.',
              style: TextStyle(color: AppColors.textLight),
            ).animate().fadeIn(),
            const SizedBox(height: 32),
            _buildInputCard(),
            const SizedBox(height: 32),
            if (_bmi != null) _buildResultCard().animate().fadeIn().scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _weightController,
                  'Weight',
                  'kg',
                  Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _heightController,
                  'Height',
                  'cm',
                  Icons.height,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _ageController,
                  'Age',
                  'years',
                  Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          items: ['Male', 'Female']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _gender = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityDropdown(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String suffix,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            suffixText: suffix,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How many times do you exercise?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activityLevel,
              isExpanded: true,
              icon: const Icon(Icons.fitness_center_outlined, size: 20),
              items: _activityFactors.keys
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _activityLevel = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Your BMI Score',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          Text(
            _bmi!.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _bmiStatus,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
          ),
          if (_dailyCalories != null) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              'Recommended Daily Intake',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '${_dailyCalories!.toStringAsFixed(0)} kcal',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To maintain your current weight',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveToProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'Save to Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
