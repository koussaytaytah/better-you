import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/meal_plan_model.dart';
import '../providers/nutrition_providers.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/providers/auth_provider.dart';

typedef Meal = PlannedMeal;

class MealPlanningScreen extends ConsumerWidget {
  const MealPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final userAsync = ref.watch(currentUserAsyncProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            title: Text(
              'Meal Planner',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showGeneratePlanDialog(context, ref),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(140),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    _buildWeekNavigator(context, ref, weekStart),
                    _buildDaySelector(ref, selectedDay),
                  ],
                ),
              ),
            ),
          ),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Please sign in to use meal planning')),
                );
              }
              
              final mealPlanAsync = ref.watch(currentMealPlanProvider(weekStart));
              
              return mealPlanAsync.when(
                data: (mealPlan) {
                  if (mealPlan == null) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(context, ref, user.uid, weekStart),
                    );
                  }
                  
                  final dayPlan = mealPlan.getDayPlan(selectedDay);
                  return _buildDayPlanContent(context, ref, dayPlan, mealPlan.id, selectedDay);
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $error')),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator(BuildContext context, WidgetRef ref, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekText = '${DateFormat.MMMd().format(weekStart)} - ${DateFormat.MMMd().format(weekEnd)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.subtract(const Duration(days: 7));
            },
          ),
          Text(
            weekText,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.add(const Duration(days: 7));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(WidgetRef ref, String selectedDay) {
    final days = [
      ('Mon', 'monday'),
      ('Tue', 'tuesday'),
      ('Wed', 'wednesday'),
      ('Thu', 'thursday'),
      ('Fri', 'friday'),
      ('Sat', 'saturday'),
      ('Sun', 'sunday'),
    ];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, key) = days[index];
          final isSelected = selectedDay == key;
          
          return GestureDetector(
            onTap: () => ref.read(selectedDayProvider.notifier).state = key,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String userId, DateTime weekStart) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No meal plan yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a meal plan to get started with healthy eating',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showGeneratePlanDialog(context, ref),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Meal Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPlanContent(
    BuildContext context,
    WidgetRef ref,
    DayPlan dayPlan,
    String mealPlanId,
    String dayKey,
  ) {
    final meals = <(MealType, Meal, int?)>[
      if (dayPlan.breakfast != null) (MealType.breakfast, dayPlan.breakfast!, null),
      if (dayPlan.lunch != null) (MealType.lunch, dayPlan.lunch!, null),
      if (dayPlan.dinner != null) (MealType.dinner, dayPlan.dinner!, null),
      ...dayPlan.snacks.asMap().entries.map((e) => (MealType.snack, e.value, e.key)),
    ];

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildCalorieSummary(dayPlan),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meals',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddMealDialog(context, ref, mealPlanId, dayKey),
                icon: const Icon(Icons.add),
                label: const Text('Add Meal'),
              ),
            ],
          ),
        ),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Center(
              child: Text(
                'No meals planned for this day',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...meals.map((mealData) {
            if (mealData.$1 == MealType.snack && mealData.$3 != null) {
              return _buildMealCard(
                context,
                ref,
                mealPlanId,
                dayKey,
                mealData.$1,
                mealData.$2,
                snackIndex: mealData.$3 as int,
              );
            }
            return _buildMealCard(
              context,
              ref,
              mealPlanId,
              dayKey,
              mealData.$1,
              mealData.$2,
            );
          }),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildCalorieSummary(DayPlan dayPlan) {
    final progress = dayPlan.targetCalories != null && dayPlan.targetCalories! > 0
        ? (dayPlan.totalCalories / dayPlan.targetCalories!).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories Today',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayPlan.totalCalories}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (dayPlan.targetCalories != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Target: ${dayPlan.targetCalories}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (dayPlan.targetCalories != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% of daily target',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    WidgetRef ref,
    String mealPlanId,
    String dayKey,
    MealType mealType,
    PlannedMeal meal, {
    int? snackIndex,
  }) {
    final isLogged = meal.isLogged;
    
    return Dismissible(
      key: Key('${meal.recipeId ?? meal.recipeTitle}_$snackIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final repository = ref.read(mealPlanRepositoryProvider);
        await repository.removeMealFromDay(mealPlanId, dayKey, mealType, snackIndex: snackIndex ?? 0);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isLogged
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: meal.recipeImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(meal.recipeImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: meal.recipeImageUrl == null
                ? Center(child: Text(mealType.icon, style: const TextStyle(fontSize: 24)))
                : null,
          ),
          title: Text(
            meal.recipeTitle ?? 'Custom Meal',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.local_fire_department, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${meal.calories} cal', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 12),
              Icon(Icons.restaurant, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${meal.servings} serving${meal.servings > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          trailing: isLogged
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: () async {
                    final repository = ref.read(mealPlanRepositoryProvider);
                    await repository.markMealAsLogged(
                      mealPlanId,
                      dayKey,
                      mealType,
                      snackIndex: snackIndex ?? 0,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meal logged to your daily intake!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
        ),
      ),
    );
  }

  void _showGeneratePlanDialog(BuildContext context, WidgetRef ref) {
    final tagsController = TextEditingController();
    final caloriesController = TextEditingController(text: '2000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Meal Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Calorie Target',
                hintText: '2000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Preferred Tags (comma separated)',
                hintText: 'healthy, quick, high-protein',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref, String mealPlanId, String dayKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _AddMealSheet(
            scrollController: scrollController,
            mealPlanId: mealPlanId,
            dayKey: dayKey,
          );
        },
      ),
    );
  }
}

class _AddMealSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final String mealPlanId;
  final String dayKey;

  const _AddMealSheet({
    required this.scrollController,
    required this.mealPlanId,
    required this.dayKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);
    final selectedType = ref.watch(_selectedMealTypeProvider);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Add Meal to ${dayKey.substring(0, 1).toUpperCase()}${dayKey.substring(1)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: MealType.values.map((type) {
              final isSelected = selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${type.icon} ${type.displayName}'),
                  selected: isSelected,
                  onSelected: (_) => ref.read(_selectedMealTypeProvider.notifier).state = type,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        Expanded(
          child: recipesAsync.when(
            data: (recipes) => ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      recipe.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(recipe.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('${recipe.caloriesPerServing.round()} cal • ${recipe.totalTimeMinutes} min'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    onPressed: () async {
                      final repository = ref.read(mealPlanRepositoryProvider);
                      final meal = PlannedMeal.fromRecipe(recipe, servings: 1);
                      await repository.addMealToDay(mealPlanId, dayKey, selectedType, meal);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${recipe.title} added to ${selectedType.displayName}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

final _selectedMealTypeProvider = StateProvider<MealType>((ref) => MealType.breakfast);
