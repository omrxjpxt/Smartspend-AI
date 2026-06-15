import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

final dataResetServiceProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  return DataResetService(uid: uid);
});

class DataResetService {
  final String? uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DataResetService({required this.uid});

  Future<void> resetAllData() async {
    if (uid == null) return;

    final userDocRef = _firestore.collection('users').doc(uid);

    // Reset user profile financial fields to 0
    await userDocRef.set({
      'monthlyIncome': 0.0,
      'monthlySavingsTarget': 0.0,
      'savingsGoal': 0.0,
    }, SetOptions(merge: true));

    // List of standard subcollections to delete
    final subcollections = [
      'expenses',
      'investments',
      'balance_transactions',
      'goals',
      'transactions'
    ];

    for (var collectionName in subcollections) {
      await _deleteCollection(userDocRef.collection(collectionName));
    }

    // Special handling for aiConversations because they have nested 'messages' subcollections
    final aiConversationsRef = userDocRef.collection('aiConversations');
    final conversationsSnapshot = await aiConversationsRef.get();
    
    for (var doc in conversationsSnapshot.docs) {
      // Delete messages subcollection
      await _deleteCollection(doc.reference.collection('messages'));
      // Delete conversation document
      await doc.reference.delete();
    }
  }

  Future<void> _deleteCollection(CollectionReference collectionRef) async {
    final snapshot = await collectionRef.get();
    // In a real app with many docs, this should be batched. For typical user data size, this is fine.
    WriteBatch batch = _firestore.batch();
    int count = 0;
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }
    
    if (count > 0) {
      await batch.commit();
    }
  }
}
