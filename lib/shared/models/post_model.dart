import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String content;
  final List<String> likes;
  final DateTime createdAt;
  final String? imageUrl;
  final int commentCount;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.likes,
    required this.createdAt,
    this.imageUrl,
    this.commentCount = 0,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Post(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userRole: data['userRole']?.toString() ?? 'USER',
      content: data['content']?.toString() ?? '',
      likes: data['likes'] is List ? List<String>.from(data['likes']) : [],
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      imageUrl: data['imageUrl']?.toString(),
      commentCount: data['commentCount'] is num ? (data['commentCount'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'commentCount': commentCount,
    };
  }
}
