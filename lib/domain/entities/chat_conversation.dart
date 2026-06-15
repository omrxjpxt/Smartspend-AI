import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final DateTime createdAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.createdAt,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      title: map['title'] ?? 'New Conversation',
      preview: map['preview'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'preview': preview,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
