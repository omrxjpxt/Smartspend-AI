class InvestmentTransaction {
  final String id;
  final String action; // e.g. 'BUY', 'SELL', 'TRANSFER'
  final String assetName;
  final String platform;
  final double amount;
  final double quantity;
  final DateTime timestamp;

  const InvestmentTransaction({
    required this.id,
    required this.action,
    required this.assetName,
    required this.platform,
    required this.amount,
    required this.quantity,
    required this.timestamp,
  });
}
