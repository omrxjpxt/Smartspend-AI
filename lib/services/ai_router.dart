class AIRouter {
  static const _localKeywords = [
    'balance', 'how much', 'total expense', 'total spent',
    'income', 'savings', 'invested', 'portfolio value',
    'net worth', 'cash flow', 'health score',
  ];

  static String route(String prompt) {
    final lower = prompt.toLowerCase();
    for (final keyword in _localKeywords) {
      if (lower.contains(keyword)) {
        print("\n=========== AI ROUTER ===========");
        print("Question:\n$prompt");
        print("Selected Engine:\nLocal Engine");
        print("Reason:\nMathematical Query (Matched keyword '$keyword')");
        print("=================================\n");
        return 'local';
      }
    }
    
    print("\n=========== AI ROUTER ===========");
    print("Question:\n$prompt");
    print("Selected Engine:\nGemini");
    print("Reason:\nAdvice Query (No mathematical keywords matched)");
    print("=================================\n");
    return 'gemini';
  }
}
