import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/investment.dart';
import '../../domain/entities/investment_transaction.dart';
import 'auth_repository.dart';

final investmentsRepositoryProvider = Provider((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? 'anonymous';
  return InvestmentsRepository(uid);
});

class InvestmentsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  InvestmentsRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _investmentsRef =>
      _firestore.collection('users').doc(userId).collection('investments');

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('investmentTransactions');

  Stream<List<Investment>> watchInvestments() {
    return _investmentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map<Investment>((doc) {
        final data = doc.data();
        return Investment(
          id: doc.id,
          platform: data['platform'] ?? 'Other',
          investmentType: data['investmentType'] ?? 'Other',
          assetName: data['assetName'] ?? '',
          symbol: data['symbol'] ?? '',
          investedAmount: (data['investedAmount'] ?? 0).toDouble(),
          quantity: (data['quantity'] ?? 0).toDouble(),
          purchasePricePerShare: (data['purchasePricePerShare'] ?? 0).toDouble(),
          currentPrice: (data['currentPrice'] ?? 0).toDouble(),
          purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          notes: data['notes'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Stream<List<InvestmentTransaction>> watchTransactions() {
    return _transactionsRef.orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map<InvestmentTransaction>((doc) {
        final data = doc.data();
        return InvestmentTransaction(
          id: doc.id,
          action: data['action'] ?? 'BUY',
          assetName: data['assetName'] ?? '',
          platform: data['platform'] ?? 'Other',
          amount: (data['amount'] ?? 0).toDouble(),
          quantity: (data['quantity'] ?? 0).toDouble(),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> createInvestment(Investment investment) async {
    await _investmentsRef.add({
      'platform': investment.platform,
      'investmentType': investment.investmentType,
      'assetName': investment.assetName,
      'symbol': investment.symbol,
      'investedAmount': investment.investedAmount,
      'quantity': investment.quantity,
      'purchasePricePerShare': investment.purchasePricePerShare,
      'currentPrice': investment.currentPrice,
      'purchaseDate': Timestamp.fromDate(investment.purchaseDate),
      'notes': investment.notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInvestment(Investment investment) async {
    await _investmentsRef.doc(investment.id).update({
      'platform': investment.platform,
      'investmentType': investment.investmentType,
      'assetName': investment.assetName,
      'symbol': investment.symbol,
      'investedAmount': investment.investedAmount,
      'quantity': investment.quantity,
      'purchasePricePerShare': investment.purchasePricePerShare,
      'currentPrice': investment.currentPrice,
      'purchaseDate': Timestamp.fromDate(investment.purchaseDate),
      'notes': investment.notes,
    });
  }

  Future<void> deleteInvestment(String id) async {
    await _investmentsRef.doc(id).delete();
  }

  Future<void> logInvestmentTransaction(InvestmentTransaction transaction) async {
    await _transactionsRef.add({
      'action': transaction.action,
      'assetName': transaction.assetName,
      'platform': transaction.platform,
      'amount': transaction.amount,
      'quantity': transaction.quantity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
