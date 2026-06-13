class AppTransaction {
  final String id;
  final String type; // Expense, Income, Balance Added, Investment, Goal Contribution
  final String title;
  final double amount;
  final String? category;
  final String? referenceId; // To link to original record if needed
  final DateTime createdAt;
  final String monthKey; // e.g. "2026-06"

  const AppTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.category,
    this.referenceId,
    required this.createdAt,
    required this.monthKey,
  });

  factory AppTransaction.fromMap(Map<String, dynamic> map, String id) {
    return AppTransaction(
      id: id,
      type: map['type'] ?? 'Expense',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'],
      referenceId: map['referenceId'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      monthKey: map['monthKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'amount': amount,
      if (category != null) 'category': category,
      if (referenceId != null) 'referenceId': referenceId,
      'createdAt': createdAt,
      'monthKey': monthKey,
    };
  }
}
