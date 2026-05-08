import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/recipe_model.dart';
import '../../../core/utils/logger.dart';

class MealPlanRepository {
  final FirebaseFirestore _firestore;

  MealPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _mealPlansCollection =>
      _firestore.collection('mealPlans');

  Future<MealPlan?> getMealPlanForWeek(String userId, DateTime weekStart) async {
    try {
      final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final snapshot = await _mealPlansCollection
          .where('userId', isEqualTo: userId)
          .where('weekStartDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('weekStartDate', isLessThan: Timestamp.fromDate(startOfWeek.add(const Duration(days: 1))))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MealPlan.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('Error fetching meal plan', e, stack);
      return null;
    }
  }

  Future<List<MealPlan>> getUserMealPlans(String userId) async {
    try {
      final snapshot = await _mealPlansCollection
          .where('userId', isEqualTo: userId)
          .orderBy('weekStartDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => MealPlan.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching user meal plans', e, stack);
      return [];
    }
  }

  Future<MealPlan> createOrUpdateMealPlan(MealPlan mealPlan) async {
    try {
      final docRef = _mealPlansCollection.doc(mealPlan.id);
      await docRef.set(mealPlan.toFirestore(), SetOptions(merge: true));
      
      final updatedDoc = await docRef.get();
      return MealPlan.fromFirestore(updatedDoc);
    } catch (e, stack) {
      AppLogger.e('Error saving meal plan', e, stack);
      throw Exception('Failed to save meal plan');
    }
  }

  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _mealPlansCollection.doc(mealPlanId).delete();
    } catch (e, stack) {
      AppLogger.e('Error deleting meal plan', e, stack);
      throw Exception('Failed to delete meal plan');
    }
  }

  Future<MealPlan> updateDayPlan(
    String mealPlanId,
    String dayKey,
    DayPlan dayPlan,
  ) async {
    try {
      await _mealPlansCollection.doc(mealPlanId).update({
        'days.$dayKey': dayPlan.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updated = await _mealPlansCollection.doc(mealPlanId).get();
      return MealPlan.fromFirestore(updated);
    } catch (e, stack) {
      AppLogger.e('Error updating day plan', e, stack);
      throw Exception('Failed to update day plan');
    }
  }

  Future<MealPlan> addMealToDay(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    PlannedMeal meal,
  ) async {
    try {
      final mealPlan = await _mealPlansCollection.doc(mealPlanId).get();
      if (!mealPlan.exists) {
        throw Exception('Meal plan not found');
      }

      final data = mealPlan.data() as Map<String, dynamic>;
      final days = (data['days'] as Map<String, dynamic>?) ?? {};
      final dayData = (days[dayKey] as Map<String, dynamic>?) ?? {};

      final updateData = <String, dynamic>{};
      
      switch (mealType) {
        case MealType.breakfast:
          updateData['days.$dayKey.breakfast'] = meal.toMap();
        case MealType.lunch:
          updateData['days.$dayKey.lunch'] = meal.toMap();
        case MealType.dinner:
          updateData['days.$dayKey.dinner'] = meal.toMap();
        case MealType.snack:
          final snacks = (dayData['snacks'] as List<dynamic>?) ?? [];
          snacks.add(meal.toMap());
          updateData['days.$dayKey.snacks'] = snacks;
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _mealPlansCollection.doc(mealPlanId).update(updateData);

      final updated = await _mealPlansCollection.doc(mealPlanId).get();
      return MealPlan.fromFirestore(updated);
    } catch (e, stack) {
      AppLogger.e('Error adding meal to day', e, stack);
      throw Exception('Failed to add meal to day');
    }
  }

  Future<MealPlan> removeMealFromDay(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    {int snackIndex = 0}
  ) async {
    try {
      final updateData = <String, dynamic>{};
      
      switch (mealType) {
        case MealType.breakfast:
          updateData['days.$dayKey.breakfast'] = FieldValue.delete();
        case MealType.lunch:
          updateData['days.$dayKey.lunch'] = FieldValue.delete();
        case MealType.dinner:
          updateData['days.$dayKey.dinner'] = FieldValue.delete();
        case MealType.snack:
          final mealPlan = await _mealPlansCollection.doc(mealPlanId).get();
          final data = mealPlan.data() as Map<String, dynamic>;
          final days = (data['days'] as Map<String, dynamic>?) ?? {};
          final dayData = (days[dayKey] as Map<String, dynamic>?) ?? {};
          final snacks = List<dynamic>.from(dayData['snacks'] ?? []);
          
          if (snackIndex >= 0 && snackIndex < snacks.length) {
            snacks.removeAt(snackIndex);
            updateData['days.$dayKey.snacks'] = snacks;
          }
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _mealPlansCollection.doc(mealPlanId).update(updateData);

      final updated = await _mealPlansCollection.doc(mealPlanId).get();
      return MealPlan.fromFirestore(updated);
    } catch (e, stack) {
      AppLogger.e('Error removing meal from day', e, stack);
      throw Exception('Failed to remove meal from day');
    }
  }

  Future<MealPlan> markMealAsLogged(
    String mealPlanId,
    String dayKey,
    MealType mealType,
    {int snackIndex = 0}
  ) async {
    try {
      final now = DateTime.now();
      final updatePath = mealType == MealType.snack
          ? 'days.$dayKey.snacks.$snackIndex'
          : 'days.$dayKey.${mealType.name}';

      await _mealPlansCollection.doc(mealPlanId).update({
        '$updatePath.isLogged': true,
        '$updatePath.loggedAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updated = await _mealPlansCollection.doc(mealPlanId).get();
      return MealPlan.fromFirestore(updated);
    } catch (e, stack) {
      AppLogger.e('Error marking meal as logged', e, stack);
      throw Exception('Failed to mark meal as logged');
    }
  }

  Stream<MealPlan?> watchMealPlan(String mealPlanId) {
    return _mealPlansCollection
        .doc(mealPlanId)
        .snapshots()
        .map((doc) => doc.exists ? MealPlan.fromFirestore(doc) : null);
  }

  Stream<MealPlan?> watchCurrentWeekMealPlan(String userId, DateTime weekStart) async* {
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    yield* _mealPlansCollection
        .where('userId', isEqualTo: userId)
        .where('weekStartDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('weekStartDate', isLessThan: Timestamp.fromDate(startOfWeek.add(const Duration(days: 1))))
        .limit(1)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.isNotEmpty ? MealPlan.fromFirestore(snapshot.docs.first) : null);
  }

  Future<MealPlan> generateWeeklyMealPlan(
    String userId,
    DateTime weekStart,
    List<String> preferredTags,
    int targetDailyCalories,
  ) async {
    try {
      final recipeSnapshot = await _firestore
          .collection('recipes')
          .where('tags', arrayContainsAny: preferredTags)
          .limit(50)
          .get();

      final recipes = recipeSnapshot.docs.map((d) => Recipe.fromFirestore(d)).toList();

      final days = <String, DayPlan>{};
      final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

      for (final dayName in dayNames) {
        final breakfastRecipes = recipes.where((r) => r.tags.contains('breakfast')).toList();
        final lunchRecipes = recipes.where((r) => r.tags.contains('lunch')).toList();
        final dinnerRecipes = recipes.where((r) => r.tags.contains('dinner')).toList();

        days[dayName] = DayPlan(
          breakfast: breakfastRecipes.isNotEmpty
              ? PlannedMeal.fromRecipe(breakfastRecipes[days.length % breakfastRecipes.length])
              : null,
          lunch: lunchRecipes.isNotEmpty
              ? PlannedMeal.fromRecipe(lunchRecipes[days.length % lunchRecipes.length])
              : null,
          dinner: dinnerRecipes.isNotEmpty
              ? PlannedMeal.fromRecipe(dinnerRecipes[days.length % dinnerRecipes.length])
              : null,
          targetCalories: targetDailyCalories,
        );
      }

      final mealPlan = MealPlan(
        id: '${userId}_${weekStart.millisecondsSinceEpoch}',
        userId: userId,
        weekStartDate: weekStart,
        days: days,
      );

      return await createOrUpdateMealPlan(mealPlan);
    } catch (e, stack) {
      AppLogger.e('Error generating meal plan', e, stack);
      throw Exception('Failed to generate meal plan');
    }
  }
}
