class Account {
  final String id;
  final String bankName;
  final String accountType; // e.g., 'Savings', 'Credit Card'
  final String mask; // e.g., '**** 1234'
  final double balance;

  const Account({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.mask,
    required this.balance,
  });
}
