import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class UserOnboardingScreen extends ConsumerStatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  ConsumerState<UserOnboardingScreen> createState() =>
      _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends ConsumerState<UserOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Page 1 – Personal Info
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _gender;

  // Page 2 – Lifestyle Habits
  bool _drinksAlcohol = false;
  bool _smokes = false;
  final _weeklyBeersController = TextEditingController();
  final _dailyCigarettesController = TextEditingController();

  // Page 3 – Physical Activity
  final Map<String, bool> _activities = {
    'Gym': false,
    'Running': false,
    'Boxing': false,
    'Cardio': false,
    'Yoga': false,
    'Other': false,
  };
  final _weeklySessionsController = TextEditingController();

  // Page 4 – Diet Preferences
  String _dietType = 'Balanced';
  final Map<String, bool> _dislikedFoods = {
    'Fish': false,
    'Eggs': false,
    'Milk': false,
    'Meat': false,
    'Vegetables': false,
    'Gluten': false,
  };

  // Page 5 – Goals
  String? _goal;
  final _targetWeightController = TextEditingController();

  static const int _totalPages = 5;

  static const _pageData = [
    {'emoji': '👤', 'title': 'About You', 'subtitle': 'Tell us your basics so we can personalize everything'},
    {'emoji': '🍷', 'title': 'Lifestyle', 'subtitle': 'Understanding your habits helps us build smarter plans'},
    {'emoji': '🏋️', 'title': 'Activity Level', 'subtitle': 'What does your fitness routine look like?'},
    {'emoji': '🥗', 'title': 'Food Preferences', 'subtitle': 'We\'ll tailor your meal plans around what you enjoy'},
    {'emoji': '🎯', 'title': 'Your Goal', 'subtitle': 'Set your target so we can track your progress'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _weeklyBeersController.dispose();
    _dailyCigarettesController.dispose();
    _weeklySessionsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final habits = {
        'alcohol': {'drinks': _drinksAlcohol, 'weeklyBeers': double.tryParse(_weeklyBeersController.text)},
        'smoking': {'smokes': _smokes, 'dailyCigarettes': int.tryParse(_dailyCigarettesController.text)},
        'activities': Map<String, bool>.from(_activities),
        'weeklySessions': int.tryParse(_weeklySessionsController.text),
        'dietType': _dietType,
        'dislikedFoods': Map<String, bool>.from(_dislikedFoods),
        'goal': _goal,
      };

      final updatedUser = currentUser.copyWith(
        age: int.tryParse(_ageController.text),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        targetWeight: double.tryParse(_targetWeightController.text),
        habits: habits,
        hasCompletedOnboarding: true,
      );

      await ref.read(currentUserAsyncProvider.notifier).updateUser(updatedUser);

      // Persist onboarding completion to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed_${currentUser.uid}', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageInfo = _pageData[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text('${_currentPage + 1} of $_totalPages',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentPage + 1) / _totalPages,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Page header ──────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                key: ValueKey(_currentPage),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    Text(pageInfo['emoji']!, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(pageInfo['title']!,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(height: 6),
                    Text(pageInfo['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                  _buildPage4(),
                  _buildPage5(),
                ],
              ),
            ),

            // ── Bottom button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage ? AppColors.primary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: _currentPage == _totalPages - 1 ? 'Complete Setup ✓' : 'Continue',
                    onPressed: _isSaving ? null : _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Personal Info ─────────────────────────────────────────────────
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SectionLabel('Gender'),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final isSelected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey[50],
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(g, textAlign: TextAlign.center,
                        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: CustomTextField(controller: _ageController, label: 'Age', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(controller: _heightController, label: 'Height (cm)', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(controller: _weightController, label: 'Current Weight (kg)', keyboardType: TextInputType.number),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 2: Lifestyle ─────────────────────────────────────────────────────
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _ToggleCard(
            icon: '🍺',
            title: 'Do you drink alcohol?',
            value: _drinksAlcohol,
            onChanged: (v) => setState(() => _drinksAlcohol = v),
          ),
          if (_drinksAlcohol) ...[
            const SizedBox(height: 12),
            CustomTextField(controller: _weeklyBeersController, label: 'Drinks per week (avg)', keyboardType: TextInputType.number),
          ],
          const SizedBox(height: 16),
          _ToggleCard(
            icon: '🚬',
            title: 'Do you smoke?',
            value: _smokes,
            onChanged: (v) => setState(() => _smokes = v),
          ),
          if (_smokes) ...[
            const SizedBox(height: 12),
            CustomTextField(controller: _dailyCigarettesController, label: 'Cigarettes per day', keyboardType: TextInputType.number),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 3: Physical Activity ─────────────────────────────────────────────
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SectionLabel('Select all that apply'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _activities.keys.map((a) {
              final isSelected = _activities[a]!;
              return GestureDetector(
                onTap: () => setState(() => _activities[a] = !isSelected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[50],
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(a, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Sessions per week'),
          const SizedBox(height: 12),
          CustomTextField(controller: _weeklySessionsController, label: 'e.g. 3', keyboardType: TextInputType.number),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 4: Diet Preferences ──────────────────────────────────────────────
  Widget _buildPage4() {
    final dietTypes = ['Balanced', 'Vegan', 'Vegetarian', 'Keto', 'Paleo', 'High-Protein'];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SectionLabel('Diet type'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dietTypes.map((d) {
              final isSelected = _dietType == d;
              return GestureDetector(
                onTap: () => setState(() => _dietType = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[50],
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(d, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Foods you dislike'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dislikedFoods.keys.map((f) {
              final isSelected = _dislikedFoods[f]!;
              return GestureDetector(
                onTap: () => setState(() => _dislikedFoods[f] = !isSelected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.withValues(alpha: 0.1) : Colors.grey[50],
                    border: Border.all(color: isSelected ? Colors.red.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f, style: TextStyle(color: isSelected ? Colors.red[700] : Colors.grey[700], fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 5: Goals ─────────────────────────────────────────────────────────
  Widget _buildPage5() {
    final goals = [
      {'value': 'Lose weight', 'emoji': '⬇️', 'desc': 'Burn fat & slim down'},
      {'value': 'Gain muscle', 'emoji': '💪', 'desc': 'Build strength & size'},
      {'value': 'Maintain weight', 'emoji': '⚖️', 'desc': 'Stay fit & balanced'},
      {'value': 'Improve endurance', 'emoji': '🏃', 'desc': 'Run faster, go longer'},
      {'value': 'Improve flexibility', 'emoji': '🧘', 'desc': 'Stretch & mobility'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...goals.map((g) {
            final isSelected = _goal == g['value'];
            return GestureDetector(
              onTap: () => setState(() => _goal = g['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(g['emoji']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['value']!, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.text)),
                          Text(g['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          CustomTextField(controller: _targetWeightController, label: 'Target Weight (kg)', keyboardType: TextInputType.number),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text.withValues(alpha: 0.7)));
  }
}

class _ToggleCard extends StatelessWidget {
  final String icon;
  final String title;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleCard({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withValues(alpha: 0.06) : Colors.grey[50],
        border: Border.all(color: value ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }
}
