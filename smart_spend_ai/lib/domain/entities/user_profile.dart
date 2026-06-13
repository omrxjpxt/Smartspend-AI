class UserProfile {
  final String id;
  final String name;
  final double monthlyIncome;
  final double monthlySavingsTarget; // Renamed from savingsGoal
  final String riskProfile; // e.g. 'Conservative', 'Moderate', 'Aggressive'
  final String investmentExperience; // e.g. 'Beginner', 'Intermediate', 'Expert'
  final bool onboardingCompleted;

  final String email;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.monthlyIncome,
    required this.monthlySavingsTarget,
    required this.riskProfile,
    required this.investmentExperience,
    required this.onboardingCompleted,
    required this.email,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    double? monthlyIncome,
    double? monthlySavingsTarget,
    String? riskProfile,
    String? investmentExperience,
    bool? onboardingCompleted,
    String? email,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlySavingsTarget: monthlySavingsTarget ?? this.monthlySavingsTarget,
      riskProfile: riskProfile ?? this.riskProfile,
      investmentExperience: investmentExperience ?? this.investmentExperience,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
