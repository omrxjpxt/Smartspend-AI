import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/balance_transaction.dart';
import 'auth_repository.dart';

final balanceRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return BalanceRepository(uid);
});

class BalanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  BalanceRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _balanceRef =>
      _firestore.collection('users').doc(userId).collection('balance_transactions');

  Stream<List<BalanceTransaction>> watchBalanceTransactions() {
    return _balanceRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map<BalanceTransaction>((doc) {
        final data = doc.data();
        return BalanceTransaction(
          id: doc.id,
          amount: (data['amount'] ?? 0).toDouble(),
          source: data['source'] ?? '',
          type: data['type'] ?? 'add',
          note: data['note'],
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> addBalanceTransaction(BalanceTransaction tx) async {
    await _balanceRef.add({
      'amount': tx.amount,
      'source': tx.source,
      'type': tx.type,
      'note': tx.note,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
