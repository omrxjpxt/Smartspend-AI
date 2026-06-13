class BalanceTransaction {
  final String id;
  final double amount;
  final String source;
  final String type; // 'add', 'remove', 'adjustment'
  final String? note;
  final DateTime timestamp;

  const BalanceTransaction({
    required this.id,
    required this.amount,
    required this.source,
    required this.type,
    this.note,
    required this.timestamp,
  });
}
