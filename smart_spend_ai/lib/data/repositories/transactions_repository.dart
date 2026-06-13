import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/app_transaction.dart';
import 'auth_repository.dart';

final transactionsRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return TransactionsRepository(uid);
});

final allTransactionsProvider = StreamProvider<List<AppTransaction>>((ref) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchAllTransactions();
});

class TransactionsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TransactionsRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('transactions');

  /// Generate a monthKey like "2026-06"
  static String generateMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  Stream<List<AppTransaction>> watchAllTransactions() {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppTransaction.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<AppTransaction>> watchTransactionsByMonth(String monthKey) {
    return _transactionsRef
        .where('monthKey', isEqualTo: monthKey)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppTransaction.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addTransaction({
    required String type,
    required String title,
    required double amount,
    String? category,
    String? referenceId,
    DateTime? dateOverride,
  }) async {
    final date = dateOverride ?? DateTime.now();
    final monthKey = generateMonthKey(date);

    await _transactionsRef.add({
      'type': type,
      'title': title,
      'amount': amount,
      if (category != null) 'category': category,
      if (referenceId != null) 'referenceId': referenceId,
      'createdAt': Timestamp.fromDate(date),
      'monthKey': monthKey,
    });
  }

  Future<void> runDataMigration() async {
    final transactionsSnapshot = await _transactionsRef.limit(1).get();
    
    // Only run if transactions collection is empty
    if (transactionsSnapshot.docs.isNotEmpty) {
      return;
    }

    int expensesCount = 0;
    int investmentsCount = 0;
    int balancesCount = 0;
    int goalsCount = 0;
    int transactionsCreated = 0;

    // 1. Migrate Expenses
    final expensesRef = _firestore.collection('users').doc(userId).collection('expenses');
    final expensesSnapshot = await expensesRef.get();
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
      await addTransaction(
        type: 'Expense',
        title: data['title'] ?? 'Expense',
        amount: (data['amount'] ?? 0).toDouble(),
        category: data['category'] ?? 'Other',
        dateOverride: date,
      );
      expensesCount++;
      transactionsCreated++;
    }

    // 2. Migrate Investments
    final investmentsRef = _firestore.collection('users').doc(userId).collection('investments');
    final investmentsSnapshot = await investmentsRef.get();
    for (var doc in investmentsSnapshot.docs) {
      final data = doc.data();
      final date = (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      await addTransaction(
        type: 'Investment',
        title: data['assetName'] ?? 'Investment',
        amount: (data['investedAmount'] ?? 0).toDouble(),
        category: data['platform'] ?? 'Other',
        dateOverride: date,
      );
      investmentsCount++;
      transactionsCreated++;
    }

    // 3. Migrate Balances
    final balancesRef = _firestore.collection('users').doc(userId).collection('balance_transactions');
    final balancesSnapshot = await balancesRef.get();
    for (var doc in balancesSnapshot.docs) {
      final data = doc.data();
      final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final isAdd = data['type'] == 'add';
      await addTransaction(
        type: isAdd ? 'Balance Added' : 'Expense',
        title: isAdd ? 'Added from ${data['source'] ?? ''}' : 'Removed from Balance',
        amount: (data['amount'] ?? 0).toDouble(),
        category: data['source'] ?? 'Balance',
        dateOverride: date,
      );
      balancesCount++;
      transactionsCreated++;
    }

    // 4. Migrate Goals
    final goalsRef = _firestore.collection('users').doc(userId).collection('goals');
    final goalsSnapshot = await goalsRef.get();
    for (var doc in goalsSnapshot.docs) {
      final data = doc.data();
      final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final amount = (data['currentAmount'] ?? 0).toDouble();
      if (amount > 0) {
        await addTransaction(
          type: 'Goal Contribution',
          title: data['title'] ?? 'Goal',
          amount: amount,
          category: 'Goal',
          dateOverride: date,
        );
        goalsCount++;
        transactionsCreated++;
      }
    }

    debugPrint('--- DATA MIGRATION COMPLETE ---');
    debugPrint('Expenses found: $expensesCount');
    debugPrint('Investments found: $investmentsCount');
    debugPrint('Balances found: $balancesCount');
    debugPrint('Goals found: $goalsCount');
    debugPrint('Transactions created: $transactionsCreated');
  }
}
