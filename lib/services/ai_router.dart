class AIRouter {
  static const _localKeywords = [
    'balance', 'how much', 'total expense', 'total spent',
    'income', 'savings', 'invested', 'portfolio value',
    'net worth', 'cash flow', 'health score',
  ];

  /// Returns 'local' or 'gemini'
  static String route(String prompt) {
    final lower = prompt.toLowerCase();
    for (final keyword in _localKeywords) {
      if (lower.contains(keyword)) {
        return 'local';
      }
    }
    return 'gemini';
  }
}
