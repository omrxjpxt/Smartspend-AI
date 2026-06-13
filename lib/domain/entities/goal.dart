class Goal {
  final String id;
  final String title;
  final String emoji;
  final double currentAmount;
  final double targetAmount;
  final double monthlyContribution;
  final DateTime estimatedCompletion;

  const Goal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlyContribution,
    required this.estimatedCompletion,
  });

  double get progress => currentAmount / targetAmount;
  String get completionPercentage => '${(progress * 100).toInt()}%';
}
