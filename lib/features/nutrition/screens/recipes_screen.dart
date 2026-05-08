import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe_model.dart';
import '../providers/nutrition_providers.dart';
import '../../../core/constants/app_theme.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(recipeSearchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final recipesAsync = searchQuery.isNotEmpty
        ? ref.watch(recipeSearchProvider(searchQuery))
        : selectedCategory != null
            ? ref.watch(recipesByTagProvider(selectedCategory))
            : ref.watch(allRecipesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Recipes & Cooking',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: TextField(
                  onChanged: (value) => ref.read(recipeSearchQueryProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search recipes, ingredients...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryChips(ref, selectedCategory),
                  const SizedBox(height: 16),
                  _buildQuickFilters(ref),
                  const SizedBox(height: 24),
                  Text(
                    searchQuery.isNotEmpty ? 'Search Results' : 'All Recipes',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          recipesAsync.when(
            data: (recipes) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: recipes.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No recipes found'),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _RecipeCard(recipe: recipes[index]),
                        childCount: recipes.length,
                      ),
                    ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $error')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(WidgetRef ref, String? selected) {
    final categories = [
      ('All', null),
      ('Breakfast', 'breakfast'),
      ('Lunch', 'lunch'),
      ('Dinner', 'dinner'),
      ('Healthy', 'healthy'),
      ('Quick', 'quick'),
      ('High Protein', 'high-protein'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, value) = categories[index];
          final isSelected = selected == value || (selected == null && value == null);
          
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = value,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilters(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickFilterCard(
            icon: Icons.timer,
            title: 'Under 30 min',
            color: Colors.orange,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = 'quick',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickFilterCard(
            icon: Icons.fitness_center,
            title: 'High Protein',
            color: Colors.green,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = 'high-protein',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickFilterCard(
            icon: Icons.local_fire_department,
            title: 'Low Calorie',
            color: Colors.red,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = 'low-calorie',
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedRecipeProvider.notifier).state = recipe;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                recipe.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTimeMinutes} min',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.caloriesPerServing.round()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.tags.take(2).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
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

class _QuickFilterCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickFilterCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
