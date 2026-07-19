class Goal {
  final String id;
  final String title;
  final String emoji;
  final double currentAmount;
  final double targetAmount;

  const Goal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.currentAmount,
    required this.targetAmount,
  });

  Goal copyWith({
    String? id,
    String? title,
    String? emoji,
    double? currentAmount,
    double? targetAmount,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
    );
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  String get completionPercentage => '${(progress * 100).toStringAsFixed(1)}%';
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);
}
