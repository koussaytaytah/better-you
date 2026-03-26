import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, coach, doctor }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final int? age;
  final double? height;
  final double? weight;
  final double? targetWeight;
  final DateTime createdAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? habits;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.age,
    this.height,
    this.weight,
    this.targetWeight,
    required this.createdAt,
    this.profileImageUrl,
    this.habits,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      age: data['age'],
      height: data['height'],
      weight: data['weight'],
      targetWeight: data['targetWeight'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
      habits: data['habits'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'habits': habits,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    String? profileImageUrl,
    Map<String, dynamic>? habits,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      habits: habits ?? this.habits,
    );
  }
}
