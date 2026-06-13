import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import 'auth_repository.dart';

final notificationsRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return NotificationsRepository(uid);
});

class NotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  NotificationsRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('users').doc(userId).collection('notifications');

  Stream<List<AppNotification>> watchNotifications() {
    return _notificationsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map<AppNotification>((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: data['type'] ?? 'system',
          isRead: data['isRead'] ?? false,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> addNotification(AppNotification notification) async {
    await _notificationsRef.add({
      'title': notification.title,
      'message': notification.message,
      'type': notification.type,
      'isRead': notification.isRead,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead(String id) async {
    await _notificationsRef.doc(id).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead() async {
    final unreadDocs = await _notificationsRef.where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
