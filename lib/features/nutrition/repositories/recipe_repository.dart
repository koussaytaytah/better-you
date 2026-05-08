import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../../../core/utils/logger.dart';

class RecipeRepository {
  final FirebaseFirestore _firestore;

  RecipeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _recipesCollection =>
      _firestore.collection('recipes');

  Future<List<Recipe>> getAllRecipes() async {
    try {
      final snapshot = await _recipesCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching recipes', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByTag(String tag) async {
    try {
      final snapshot = await _recipesCollection
          .where('tags', arrayContains: tag)
          .get();
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching recipes by tag', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByCuisine(String cuisine) async {
    try {
      final snapshot = await _recipesCollection
          .where('cuisine', isEqualTo: cuisine)
          .get();
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching recipes by cuisine', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      final snapshot = await _recipesCollection.get();
      
      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .where((recipe) =>
              recipe.title.toLowerCase().contains(lowercaseQuery) ||
              recipe.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
              recipe.ingredients.any((ing) => ing.toLowerCase().contains(lowercaseQuery)))
          .toList();
    } catch (e, stack) {
      AppLogger.e('Error searching recipes', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getRecipesByDietaryPreference({
    bool? vegetarian,
    bool? vegan,
    bool? glutenFree,
    bool? dairyFree,
  }) async {
    try {
      Query query = _recipesCollection;
      
      if (vegetarian == true) {
        query = query.where('isVegetarian', isEqualTo: true);
      }
      if (vegan == true) {
        query = query.where('isVegan', isEqualTo: true);
      }
      if (glutenFree == true) {
        query = query.where('isGlutenFree', isEqualTo: true);
      }
      if (dairyFree == true) {
        query = query.where('isDairyFree', isEqualTo: true);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching recipes by dietary preference', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getQuickRecipes({int maxTimeMinutes = 30}) async {
    try {
      final snapshot = await _recipesCollection
          .where('cookTimeMinutes', isLessThanOrEqualTo: maxTimeMinutes)
          .orderBy('cookTimeMinutes')
          .get();
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    } catch (e, stack) {
      AppLogger.e('Error fetching quick recipes', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getHighProteinRecipes({int minProtein = 25}) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes
          .where((r) => r.proteinPerServing >= minProtein)
          .toList()
        ..sort((a, b) => b.proteinPerServing.compareTo(a.proteinPerServing));
    } catch (e, stack) {
      AppLogger.e('Error fetching high protein recipes', e, stack);
      return [];
    }
  }

  Future<List<Recipe>> getLowCalorieRecipes({int maxCalories = 400}) async {
    try {
      final allRecipes = await getAllRecipes();
      return allRecipes
          .where((r) => r.caloriesPerServing <= maxCalories)
          .toList()
        ..sort((a, b) => a.caloriesPerServing.compareTo(b.caloriesPerServing));
    } catch (e, stack) {
      AppLogger.e('Error fetching low calorie recipes', e, stack);
      return [];
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      final doc = await _recipesCollection.doc(id).get();
      if (doc.exists) {
        return Recipe.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('Error fetching recipe by ID', e, stack);
      return null;
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _recipesCollection.doc(recipe.id).set(recipe.toFirestore());
    } catch (e, stack) {
      AppLogger.e('Error adding recipe', e, stack);
      throw Exception('Failed to add recipe');
    }
  }

  Stream<List<Recipe>> watchRecipes() {
    return _recipesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  Stream<List<Recipe>> watchRecipesByTag(String tag) {
    return _recipesCollection
        .where('tags', arrayContains: tag)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }
}
