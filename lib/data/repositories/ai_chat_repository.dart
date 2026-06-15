import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_conversation.dart';
import 'auth_repository.dart';

final aiChatRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return AiChatRepository(uid);
});

final recentConversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return repository.watchRecentConversations();
});

final allConversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return repository.watchAllConversations();
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return repository.watchConversationMessages(conversationId);
});

class AiChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  AiChatRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection('users').doc(userId).collection('aiConversations');

  Stream<List<ChatConversation>> watchRecentConversations() {
    return _conversationsRef
        .orderBy('updatedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatConversation.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<ChatConversation>> watchAllConversations() {
    return _conversationsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatConversation.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<ChatMessage>> watchConversationMessages(String conversationId) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<String> createConversation(String initialTitle, String initialPreview) async {
    final docRef = await _conversationsRef.add({
      'title': initialTitle,
      'preview': initialPreview,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> addMessage({required String conversationId, required String role, required String message}) async {
    final timestamp = FieldValue.serverTimestamp();
    
    // Add message
    await _conversationsRef.doc(conversationId).collection('messages').add({
      'role': role,
      'message': message,
      'timestamp': timestamp,
    });

    // Update conversation metadata
    await _conversationsRef.doc(conversationId).update({
      'updatedAt': timestamp,
      'preview': message, // last message is the preview
    });
  }

  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    await _conversationsRef.doc(conversationId).update({
      'title': newTitle,
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages inside it
    final messages = await _conversationsRef.doc(conversationId).collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    // Delete conversation document
    await _conversationsRef.doc(conversationId).delete();
  }
}
