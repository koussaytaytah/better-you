import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final String type; // 'text', 'audio', 'image'
  final String? mediaUrl;
  final int? duration;
  final List<String> readBy; // list of userIds who read this
  final Map<String, String> reactions; // userId -> emoji
  final String? replyToId; // message id being replied to
  final String? replyToText; // preview of replied message

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
    this.readBy = const [],
    this.reactions = const {},
    this.replyToId,
    this.replyToText,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'user',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      duration: data['duration'],
      readBy: data['readBy'] is List ? List<String>.from(data['readBy']) : [],
      reactions: data['reactions'] is Map
          ? Map<String, String>.from(data['reactions'])
          : {},
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
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
      'readBy': readBy,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToText': replyToText,
    };
  }

  Message copyWith({
    List<String>? readBy,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      message: message,
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
      duration: duration,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId,
      replyToText: replyToText,
    );
  }
}
