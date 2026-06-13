import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense.dart';
import 'auth_repository.dart';

final expensesRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return ExpensesRepository(uid);
});

class ExpensesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  ExpensesRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _firestore.collection('users').doc(userId).collection('expenses');

  Stream<List<Expense>> watchExpenses() {
    return _expensesRef.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: doc.id,
          amount: (data['amount'] ?? 0).toDouble(),
          category: data['category'] ?? 'Other',
          description: data['description'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> createExpense(Expense expense) async {
    await _expensesRef.add({
      'amount': expense.amount,
      'category': expense.category,
      'description': expense.description,
      'date': Timestamp.fromDate(expense.date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String id) async {
    await _expensesRef.doc(id).delete();
  }
}
