class Insight {
  final String id;
  final String message;
  final String type; // 'spending', 'savings', 'investment'
  final DateTime generatedAt;
  final bool isPositive;

  const Insight({
    required this.id,
    required this.message,
    required this.type,
    required this.generatedAt,
    required this.isPositive,
  });
}
