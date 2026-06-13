class Investment {
  final String id;
  final String platform;
  final String investmentType;
  final String assetName;
  final String symbol;
  final double investedAmount;
  final double quantity;
  final double purchasePricePerShare;
  final double currentPrice;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdAt;

  const Investment({
    required this.id,
    required this.platform,
    required this.investmentType,
    required this.assetName,
    required this.symbol,
    required this.investedAmount,
    required this.quantity,
    required this.purchasePricePerShare,
    required this.currentPrice,
    required this.purchaseDate,
    this.notes,
    required this.createdAt,
  });

  // Strict mathematical formulas as requested
  double get currentValue => currentPrice * quantity;
  double get profitLoss => currentValue - investedAmount;
  double get profitLossPercent => investedAmount > 0 
      ? ((currentValue - investedAmount) / investedAmount) * 100 
      : 0;
}
