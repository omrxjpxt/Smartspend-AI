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

  Investment copyWith({
    String? id,
    String? platform,
    String? investmentType,
    String? assetName,
    String? symbol,
    double? investedAmount,
    double? quantity,
    double? purchasePricePerShare,
    double? currentPrice,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Investment(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      investmentType: investmentType ?? this.investmentType,
      assetName: assetName ?? this.assetName,
      symbol: symbol ?? this.symbol,
      investedAmount: investedAmount ?? this.investedAmount,
      quantity: quantity ?? this.quantity,
      purchasePricePerShare: purchasePricePerShare ?? this.purchasePricePerShare,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Strict mathematical formulas as requested
  double get currentValue => currentPrice * quantity;
  double get profitLoss => currentValue - investedAmount;
  double get profitLossPercent => investedAmount > 0 
      ? ((currentValue - investedAmount) / investedAmount) * 100 
      : 0;
}
