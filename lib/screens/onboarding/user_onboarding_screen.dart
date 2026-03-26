import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main/dashboard_screen.dart';

class UserOnboardingScreen extends ConsumerStatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  ConsumerState<UserOnboardingScreen> createState() =>
      _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends ConsumerState<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Personal Info
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  String? _gender;

  // Alcohol Habit
  bool _drinksAlcohol = false;
  final _alcoholStartYearController = TextEditingController();
  final _weeklyBeersController = TextEditingController();

  // Smoking Habit
  bool _smokes = false;
  final _smokingStartYearController = TextEditingController();
  final _dailyCigarettesController = TextEditingController();

  // Physical Activity
  final Map<String, bool> _activities = {
    'Gym': false,
    'Running': false,
    'Boxing': false,
    'Cardio': false,
    'Other': false,
  };
  final _weeklySessionsController = TextEditingController();

  // Diet Preferences
  final Map<String, bool> _dislikedFoods = {
    'Fish': false,
    'Eggs': false,
    'Milk': false,
    'Meat': false,
    'Vegetables': false,
  };

  // Goal
  String? _goal;

  final List<String> _steps = [
    'Personal Information',
    'Alcohol Habits',
    'Smoking Habits',
    'Physical Activity',
    'Diet Preferences',
    'Goals',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _alcoholStartYearController.dispose();
    _weeklyBeersController.dispose();
    _smokingStartYearController.dispose();
    _dailyCigarettesController.dispose();
    _weeklySessionsController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final habits = {
      'alcohol': {
        'drinks': _drinksAlcohol,
        'startYear': int.tryParse(_alcoholStartYearController.text),
        'weeklyBeers': double.tryParse(_weeklyBeersController.text),
      },
      'smoking': {
        'smokes': _smokes,
        'startYear': int.tryParse(_smokingStartYearController.text),
        'dailyCigarettes': int.tryParse(_dailyCigarettesController.text),
      },
      'activities': _activities,
      'weeklySessions': int.tryParse(_weeklySessionsController.text),
      'dislikedFoods': _dislikedFoods,
      'goal': _goal,
    };

    final updatedUser = currentUser.copyWith(
      age: int.tryParse(_ageController.text),
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      targetWeight: double.tryParse(_targetWeightController.text),
      habits: habits,
    );

    await ref.read(currentUserProvider.notifier).updateUser(updatedUser);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Setup Your Profile',
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _steps[_currentStep],
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(key: _formKey, child: _buildCurrentStep()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                text: _currentStep == _steps.length - 1
                    ? 'Complete Setup'
                    : 'Next',
                onPressed: _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAlcoholHabitStep();
      case 2:
        return _buildSmokingHabitStep();
      case 3:
        return _buildPhysicalActivityStep();
      case 4:
        return _buildDietPreferencesStep();
      case 5:
        return _buildGoalStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about yourself',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppColors.text.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
          ),
          items: ['Male', 'Female', 'Other'].map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) => setState(() => _gender = value),
          validator: (value) =>
              value == null ? 'Please select your gender' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _ageController,
          label: 'Age',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your age';
            final age = int.tryParse(value!);
            if (age == null || age < 13 || age > 120) {
              return 'Please enter a valid age';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _heightController,
          label: 'Height (cm)',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your height';
            final height = double.tryParse(value!);
            if (height == null || height < 50 || height > 250) {
              return 'Please enter a valid height in cm';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _weightController,
          label: 'Current Weight (kg)',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your weight';
            final weight = double.tryParse(value!);
            if (weight == null || weight < 20 || weight > 300) {
              return 'Please enter a valid weight in kg';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAlcoholHabitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you drink alcohol?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes'),
                value: true,
                groupValue: _drinksAlcohol,
                onChanged: (value) => setState(() => _drinksAlcohol = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No'),
                value: false,
                groupValue: _drinksAlcohol,
                onChanged: (value) => setState(() => _drinksAlcohol = value!),
              ),
            ),
          ],
        ),
        if (_drinksAlcohol) ...[
          const SizedBox(height: 24),
          CustomTextField(
            controller: _alcoholStartYearController,
            label: 'When did you start drinking? (Year)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _weeklyBeersController,
            label: 'Average beers per week',
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildSmokingHabitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do you smoke?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Yes'),
                value: true,
                groupValue: _smokes,
                onChanged: (value) => setState(() => _smokes = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No'),
                value: false,
                groupValue: _smokes,
                onChanged: (value) => setState(() => _smokes = value!),
              ),
            ),
          ],
        ),
        if (_smokes) ...[
          const SizedBox(height: 24),
          CustomTextField(
            controller: _smokingStartYearController,
            label: 'When did you start smoking? (Year)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _dailyCigarettesController,
            label: 'Cigarettes per day',
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }

  Widget _buildPhysicalActivityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What physical activities do you practice?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ..._activities.keys.map(
          (activity) => CheckboxListTile(
            title: Text(activity),
            value: _activities[activity],
            onChanged: (value) =>
                setState(() => _activities[activity] = value ?? false),
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _weeklySessionsController,
          label: 'How many times per week?',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDietPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which foods do you dislike?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ..._dislikedFoods.keys.map(
          (food) => CheckboxListTile(
            title: Text(food),
            value: _dislikedFoods[food],
            onChanged: (value) =>
                setState(() => _dislikedFoods[food] = value ?? false),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your main goal?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ...['Lose weight', 'Gain weight', 'Maintain weight'].map(
          (goal) => RadioListTile<String>(
            title: Text(goal),
            value: goal,
            groupValue: _goal,
            onChanged: (value) => setState(() => _goal = value),
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _targetWeightController,
          label: 'Target Weight (kg)',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
