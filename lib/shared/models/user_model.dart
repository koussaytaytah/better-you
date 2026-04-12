import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, coach, doctor, admin }

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
  final int xp;
  final int level;
  final List<String> friends;
  final List<String> friendRequests;
  final List<String> badges;
  final bool isBanned;
  final String? warningMessage;
  final bool isOnline;
  final List<String> blockedUsers;
  final bool isPremium;
  final Map<String, dynamic>
  appLimits; // { package: { 'limit': mins, 'quest': '...' } }
  final bool hasCompletedOnboarding;

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
    this.xp = 0,
    this.level = 1,
    this.friends = const [],
    this.friendRequests = const [],
    this.badges = const [],
    this.isBanned = false,
    this.warningMessage,
    this.isOnline = false,
    this.blockedUsers = const [],
    this.isPremium = false,
    this.appLimits = const {},
    this.hasCompletedOnboarding = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      age: data['age'] is num ? (data['age'] as num).toInt() : null,
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      targetWeight: (data['targetWeight'] as num?)?.toDouble(),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      habits: data['habits'] is Map ? Map<String, dynamic>.from(data['habits']) : null,
      xp: data['xp'] is num ? (data['xp'] as num).toInt() : 0,
      level: data['level'] is num ? (data['level'] as num).toInt() : 1,
      friends: data['friends'] is List ? List<String>.from(data['friends']) : [],
      friendRequests: data['friendRequests'] is List ? List<String>.from(data['friendRequests']) : [],
      badges: data['badges'] is List ? List<String>.from(data['badges']) : [],
      isBanned: data['isBanned'] == true,
      warningMessage: data['warningMessage']?.toString(),
      isOnline: data['isOnline'] == true,
      blockedUsers: data['blockedUsers'] is List ? List<String>.from(data['blockedUsers']) : [],
      isPremium: data['isPremium'] == true,
      appLimits: data['appLimits'] is Map ? Map<String, dynamic>.from(data['appLimits']) : {},
      hasCompletedOnboarding: data['hasCompletedOnboarding'] == true,
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
      'xp': xp,
      'level': level,
      'friends': friends,
      'friendRequests': friendRequests,
      'badges': badges,
      'isBanned': isBanned,
      'warningMessage': warningMessage,
      'isOnline': isOnline,
      'blockedUsers': blockedUsers,
      'isPremium': isPremium,
      'appLimits': appLimits,
      'hasCompletedOnboarding': hasCompletedOnboarding,
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
    int? xp,
    int? level,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? badges,
    bool? isBanned,
    String? warningMessage,
    bool? isOnline,
    List<String>? blockedUsers,
    bool? isPremium,
    Map<String, dynamic>? appLimits,
    bool? hasCompletedOnboarding,
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
      xp: xp ?? this.xp,
      level: level ?? this.level,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      badges: badges ?? this.badges,
      isBanned: isBanned ?? this.isBanned,
      warningMessage: warningMessage ?? this.warningMessage,
      isOnline: isOnline ?? this.isOnline,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      isPremium: isPremium ?? this.isPremium,
      appLimits: appLimits ?? this.appLimits,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  // Gamification Rank Logic
  String getRankName() {
    if (level < 10) return 'Bronze';
    if (level < 20) return 'Silver';
    if (level < 30) return 'Gold';
    if (level < 40) return 'Platinum';
    if (level < 50) return 'Diamond';
    return 'Master';
  }

  String getRankImagePath() {
    // Return an asset path or a distinct icon string representation
    if (level < 10) return 'bronze';
    if (level < 20) return 'silver';
    if (level < 30) return 'gold';
    if (level < 40) return 'platinum';
    if (level < 50) return 'diamond';
    return 'master';
  }
}
