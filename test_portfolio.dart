import 'package:flutter/foundation.dart';

class Investment {
  final String id;
  final double quantity;
  final double investedAmount;
  Investment({required this.id, required this.quantity, required this.investedAmount});
  Investment copyWith({double? quantity, double? investedAmount}) {
    return Investment(
      id: this.id,
      quantity: quantity ?? this.quantity,
      investedAmount: investedAmount ?? this.investedAmount,
    );
  }
}

class AppTransaction {
  final String id;
  final String type;
  final String title;
  final double amount;
  final Map<String, dynamic>? metadata;
  AppTransaction(this.id, this.type, this.title, this.amount, this.metadata);
}

void main() {
  final transactions = [
    AppTransaction('1', 'Investment', 'SWASA', 33333, {'symbol': 'SWASA', 'quantity': 1}),
    AppTransaction('2', 'Investment Sale', 'SWASA', 33333, {'symbol': 'swasa', 'quantity': 1}),
  ];
  
  final investmentTxs = transactions.where((tx) =>
      tx.type == 'Investment' ||
      tx.type == 'Investment Purchase' ||
      tx.type == 'Buy Investment' ||
      tx.type == 'Investment Buy' ||
      tx.type == 'Investment Sale' ||
      tx.type == 'Sell Investment').toList();

  final Map<String, List<dynamic>> txsBySymbol = {};
  for (final tx in investmentTxs) {
    final symbol = (tx.metadata?['symbol']?.toString() ?? tx.title).trim();
    if (!txsBySymbol.containsKey(symbol)) {
      txsBySymbol[symbol] = [];
    }
    txsBySymbol[symbol]!.add(tx);
  }
  
  print(txsBySymbol.keys);
}
