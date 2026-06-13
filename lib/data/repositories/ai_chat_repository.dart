import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_message.dart';
import 'auth_repository.dart';

final aiChatRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return AiChatRepository(uid);
});

final chatHistoryProvider = StreamProvider<List<ChatMessage>>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return repository.watchChatHistory();
});

class AiChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  AiChatRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('users').doc(userId).collection('aiChats');

  Stream<List<ChatMessage>> watchChatHistory() {
    return _chatsRef
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addMessage({required String role, required String message}) async {
    await _chatsRef.add({
      'role': role,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
