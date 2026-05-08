import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';

class MealPlan {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final Map<String, DayPlan> days;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MealPlan({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.days,
    this.createdAt,
    this.updatedAt,
  });

  factory MealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final daysMap = data['days'] as Map<String, dynamic>? ?? {};
    
    return MealPlan(
      id: doc.id,
      userId: data['userId'] ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      days: daysMap.map((key, value) => MapEntry(
        key,
        DayPlan.fromMap(value as Map<String, dynamic>),
      )),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'days': days.map((key, value) => MapEntry(key, value.toMap())),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DayPlan getDayPlan(String dayKey) {
    return days[dayKey] ?? DayPlan.empty();
  }

  MealPlan copyWith({
    String? id,
    String? userId,
    DateTime? weekStartDate,
    Map<String, DayPlan>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DayPlan {
  final PlannedMeal? breakfast;
  final PlannedMeal? lunch;
  final PlannedMeal? dinner;
  final List<PlannedMeal> snacks;
  final int? targetCalories;
  final String? notes;

  DayPlan({
    this.breakfast,
    this.lunch,
    this.dinner,
    this.snacks = const [],
    this.targetCalories,
    this.notes,
  });

  factory DayPlan.empty() => DayPlan();

  factory DayPlan.fromMap(Map<String, dynamic> map) {
    return DayPlan(
      breakfast: map['breakfast'] != null
          ? PlannedMeal.fromMap(map['breakfast'] as Map<String, dynamic>)
          : null,
      lunch: map['lunch'] != null
          ? PlannedMeal.fromMap(map['lunch'] as Map<String, dynamic>)
          : null,
      dinner: map['dinner'] != null
          ? PlannedMeal.fromMap(map['dinner'] as Map<String, dynamic>)
          : null,
      snacks: (map['snacks'] as List<dynamic>?)
              ?.map((e) => PlannedMeal.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      targetCalories: (map['targetCalories'] as num?)?.toInt(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'breakfast': breakfast?.toMap(),
      'lunch': lunch?.toMap(),
      'dinner': dinner?.toMap(),
      'snacks': snacks.map((e) => e.toMap()).toList(),
      'targetCalories': targetCalories,
      'notes': notes,
    };
  }

  int get totalCalories {
    int total = 0;
    if (breakfast != null) total += breakfast!.calories;
    if (lunch != null) total += lunch!.calories;
    if (dinner != null) total += dinner!.calories;
    for (final snack in snacks) {
      total += snack.calories;
    }
    return total;
  }

  DayPlan copyWith({
    PlannedMeal? breakfast,
    PlannedMeal? lunch,
    PlannedMeal? dinner,
    List<PlannedMeal>? snacks,
    int? targetCalories,
    String? notes,
  }) {
    return DayPlan(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
      targetCalories: targetCalories ?? this.targetCalories,
      notes: notes ?? this.notes,
    );
  }
}

class PlannedMeal {
  final String? recipeId;
  final String? recipeTitle;
  final String? recipeImageUrl;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int servings;
  final bool isLogged;
  final DateTime? loggedAt;

  PlannedMeal({
    this.recipeId,
    this.recipeTitle,
    this.recipeImageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servings = 1,
    this.isLogged = false,
    this.loggedAt,
  });

  factory PlannedMeal.fromRecipe(Recipe recipe, {int servings = 1}) {
    return PlannedMeal(
      recipeId: recipe.id,
      recipeTitle: recipe.title,
      recipeImageUrl: recipe.imageUrl,
      calories: (recipe.caloriesPerServing * servings).round(),
      protein: recipe.proteinPerServing * servings,
      carbs: recipe.carbsPerServing * servings,
      fat: recipe.fatPerServing * servings,
      servings: servings,
    );
  }

  factory PlannedMeal.fromMap(Map<String, dynamic> map) {
    return PlannedMeal(
      recipeId: map['recipeId'] as String?,
      recipeTitle: map['recipeTitle'] as String?,
      recipeImageUrl: map['recipeImageUrl'] as String?,
      calories: (map['calories'] as num).toInt(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      isLogged: map['isLogged'] ?? false,
      loggedAt: map['loggedAt'] != null
          ? (map['loggedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'recipeImageUrl': recipeImageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servings': servings,
      'isLogged': isLogged,
      'loggedAt': loggedAt != null ? Timestamp.fromDate(loggedAt!) : null,
    };
  }

  PlannedMeal copyWith({
    String? recipeId,
    String? recipeTitle,
    String? recipeImageUrl,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    int? servings,
    bool? isLogged,
    DateTime? loggedAt,
  }) {
    return PlannedMeal(
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipeImageUrl: recipeImageUrl ?? this.recipeImageUrl,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servings: servings ?? this.servings,
      isLogged: isLogged ?? this.isLogged,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get icon {
    switch (this) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🥗';
      case MealType.dinner:
        return '🍽️';
      case MealType.snack:
        return '🍎';
    }
  }
}
