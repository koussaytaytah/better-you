import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final String type; // 'text' or 'audio'
  final String? mediaUrl;
  final int? duration;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.type = 'text',
    this.mediaUrl,
    this.duration,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      roomId: data['roomId'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderRole: data['senderRole'] ?? 'user',
      message: data['message'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      duration: data['duration'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'mediaUrl': mediaUrl,
      'duration': duration,
    };
  }
}
