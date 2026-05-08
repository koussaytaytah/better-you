import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../models/meal_plan_model.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/meal_plan_repository.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/utils/sample_data.dart';
import '../../../core/utils/logger.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository();
});

final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  var recipes = await repository.getAllRecipes();
  
  // If no recipes in Firestore, seed with sample data
  if (recipes.isEmpty) {
    AppLogger.i('No recipes found in Firestore, seeding sample data...');
    final sampleRecipes = SampleData.getSampleRecipes();
    
    // Add sample recipes to Firestore
    for (final recipe in sampleRecipes) {
      try {
        await repository.addRecipe(recipe);
      } catch (e) {
        AppLogger.w('Failed to add sample recipe ${recipe.title}: $e');
      }
    }
    
    // Return sample recipes immediately
    return sampleRecipes;
  }
  
  return recipes;
});

final recipesByTagProvider = FutureProvider.family<List<Recipe>, String>((ref, tag) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByTag(tag);
});

final recipeSearchProvider = FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.searchRecipes(query);
});

final recipeByIdProvider = FutureProvider.family<Recipe?, String>((ref, id) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipeById(id);
});

final quickRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getQuickRecipes();
});

final highProteinRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getHighProteinRecipes();
});

final lowCalorieRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getLowCalorieRecipes();
});

final selectedRecipeProvider = StateProvider<Recipe?>((ref) => null);

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final recipeSearchQueryProvider = StateProvider<String>((ref) => '');

final currentMealPlanProvider = FutureProvider.family<MealPlan?, DateTime>((ref, weekStart) async {
  final userAsync = ref.watch(currentUserAsyncProvider);
  final repository = ref.watch(mealPlanRepositoryProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Future.value(null);
      return repository.getMealPlanForWeek(user.uid, weekStart);
    },
    loading: () => Future.value(null),
    error: (_, st) => Future.value(null),
  );
});

final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
});

final currentWeekMealPlanProvider = FutureProvider<MealPlan?>((ref) async {
  final weekStart = ref.watch(selectedWeekStartProvider);
  return ref.watch(currentMealPlanProvider(weekStart).future);
});

final selectedDayProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  return dayNames[now.weekday - 1];
});

class MealPlanNotifier extends StateNotifier<AsyncValue<MealPlan?>> {
  final MealPlanRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  MealPlanNotifier(this._repository, this._ref) : super(const AsyncValue.loading());

  Future<void> loadMealPlan(String userId, DateTime weekStart) async {
    state = const AsyncValue.loading();
    try {
      final plan = await _repository.getMealPlanForWeek(userId, weekStart);
      state = AsyncValue.data(plan);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createOrUpdateMealPlan(MealPlan mealPlan) async {
    try {
      final updated = await _repository.createOrUpdateMealPlan(mealPlan);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMealToDay(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    PlannedMeal meal,
  ) async {
    try {
      final updated = await _repository.addMealToDay(mealPlanId, dayKey, mealType, meal);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeMealFromDay(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    {int snackIndex = 0}
  ) async {
    try {
      final updated = await _repository.removeMealFromDay(mealPlanId, dayKey, mealType, snackIndex: snackIndex);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markMealAsLogged(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    {int snackIndex = 0}
  ) async {
    try {
      final updated = await _repository.markMealAsLogged(mealPlanId, dayKey, mealType, snackIndex: snackIndex);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> generateWeeklyPlan(
    String userId,
    DateTime weekStart,
    List<String> preferredTags,
    int targetDailyCalories,
  ) async {
    state = const AsyncValue.loading();
    try {
      final plan = await _repository.generateWeeklyMealPlan(
        userId,
        weekStart,
        preferredTags,
        targetDailyCalories,
      );
      state = AsyncValue.data(plan);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final mealPlanNotifierProvider = StateNotifierProvider.family<MealPlanNotifier, AsyncValue<MealPlan?>, String>(
  (ref, userId) {
    final repository = ref.watch(mealPlanRepositoryProvider);
    return MealPlanNotifier(repository, ref);
  },
);

final favoritesProvider = StateProvider<Set<String>>((ref) => {});
