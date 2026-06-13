class CurrencyFormatter {
  static String format(dynamic amount) {
    if (amount is int) {
      return '₹$amount';
    } else if (amount is double) {
      if (amount == amount.toInt()) {
        return '₹${amount.toInt()}';
      }
      return '₹${amount.toStringAsFixed(2)}';
    }
    return '₹$amount';
  }
}
