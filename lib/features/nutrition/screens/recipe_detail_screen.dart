import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe_model.dart';
import '../../../core/constants/app_theme.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCookingMode = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    if (_isCookingMode) {
      return _buildCookingMode(recipe);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                recipe.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickInfo(recipe),
                _buildMacrosCard(recipe),
                _buildDietaryTags(recipe),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Ingredients'),
                    Tab(text: 'Instructions'),
                    Tab(text: 'Nutrition'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildIngredientsTab(recipe),
                      _buildInstructionsTab(recipe),
                      _buildNutritionTab(recipe),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _isCookingMode = true),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.restaurant_menu, color: Colors.white),
        label: const Text('Start Cooking', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildQuickInfo(Recipe recipe) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(Icons.timer, '${recipe.totalTimeMinutes} min', 'Total Time'),
          _buildInfoItem(Icons.local_dining, '${recipe.servings}', 'Servings'),
          _buildInfoItem(Icons.trending_up, recipe.difficulty, 'Difficulty'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMacrosCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Per Serving',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('${recipe.caloriesPerServing.round()}', 'Calories', Colors.orange),
              _buildMacroItem('${recipe.proteinPerServing.round()}g', 'Protein', Colors.blue),
              _buildMacroItem('${recipe.carbsPerServing.round()}g', 'Carbs', Colors.green),
              _buildMacroItem('${recipe.fatPerServing.round()}g', 'Fat', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, color: color, size: 12),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryTags(Recipe recipe) {
    final tags = <String>[];
    if (recipe.isVegetarian) tags.add('Vegetarian');
    if (recipe.isVegan) tags.add('Vegan');
    if (recipe.isGlutenFree) tags.add('Gluten Free');
    if (recipe.isDairyFree) tags.add('Dairy Free');

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => Chip(
          label: Text(tag),
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
        )).toList(),
      ),
    );
  }

  Widget _buildIngredientsTab(Recipe recipe) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipe.ingredients.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(recipe.ingredients[index]),
          trailing: Checkbox(
            value: false,
            onChanged: (_) {},
            activeColor: AppColors.primary,
          ),
        );
      },
    );
  }

  Widget _buildInstructionsTab(Recipe recipe) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipe.instructions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  recipe.instructions[index],
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab(Recipe recipe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Nutrition Facts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNutritionRow('Calories', '${recipe.caloriesPerServing.round()} kcal'),
          _buildNutritionRow('Protein', '${recipe.proteinPerServing.round()}g'),
          _buildNutritionRow('Carbohydrates', '${recipe.carbsPerServing.round()}g'),
          _buildNutritionRow('Fat', '${recipe.fatPerServing.round()}g'),
          const Divider(height: 32),
          Text(
            'Macronutrient Ratio',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroChart(recipe),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChart(Recipe recipe) {
    final total = recipe.protein + recipe.carbs + recipe.fat;
    final proteinPct = total > 0 ? (recipe.protein * 4) / (recipe.calories) : 0;
    final carbsPct = total > 0 ? (recipe.carbs * 4) / (recipe.calories) : 0;
    final fatPct = total > 0 ? (recipe.fat * 9) / (recipe.calories) : 0;

    return Row(
      children: [
        Expanded(
          flex: (proteinPct * 100).round(),
          child: Container(
            height: 24,
            color: Colors.blue,
          ),
        ),
        Expanded(
          flex: (carbsPct * 100).round(),
          child: Container(
            height: 24,
            color: Colors.green,
          ),
        ),
        Expanded(
          flex: (fatPct * 100).round(),
          child: Container(
            height: 24,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildCookingMode(Recipe recipe) {
    final instructions = recipe.instructions;
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == instructions.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _isCookingMode = false),
                  ),
                  Text(
                    'Step ${_currentStep + 1} of ${instructions.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_currentStep + 1}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      instructions[_currentStep],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFirstStep
                          ? null
                          : () => setState(() => _currentStep--),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLastStep
                          ? () {
                              setState(() {
                                _isCookingMode = false;
                                _currentStep = 0;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enjoy your meal! 🎉'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : () => setState(() => _currentStep++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isLastStep ? 'Finish' : 'Next Step',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
