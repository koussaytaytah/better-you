import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String? cuisine;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final DateTime? createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    this.cuisine,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isDairyFree = false,
    this.createdAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      cookTimeMinutes: (data['cookTimeMinutes'] as num?)?.toInt() ?? 0,
      servings: (data['servings'] as num?)?.toInt() ?? 1,
      difficulty: data['difficulty'] ?? 'Easy',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      cuisine: data['cuisine'],
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
      isDairyFree: data['isDairyFree'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'ingredients': ingredients,
      'instructions': instructions,
      'tags': tags,
      'cuisine': cuisine,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'isDairyFree': isDairyFree,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  double get caloriesPerServing => calories / servings;
  double get proteinPerServing => protein / servings;
  double get carbsPerServing => carbs / servings;
  double get fatPerServing => fat / servings;

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    String? difficulty,
    List<String>? ingredients,
    List<String>? instructions,
    List<String>? tags,
    String? cuisine,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isDairyFree,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
      cuisine: cuisine ?? this.cuisine,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isDairyFree: isDairyFree ?? this.isDairyFree,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
