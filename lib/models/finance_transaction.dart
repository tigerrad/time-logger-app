class FinanceTransaction {
  final int id;
  final String type;
  final String category;
  final double amount;
  final String title;
  final String note;
  final String date;

  FinanceTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.title,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category,
        'amount': amount,
        'title': title,
        'note': note,
        'date': date,
      };

  factory FinanceTransaction.fromJson(Map<String, dynamic> j) => FinanceTransaction(
        id: j['id'] ?? 0,
        type: j['type'] ?? 'expense',
        category: j['category'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        title: j['title'] ?? '',
        note: j['note'] ?? '',
        date: j['date'] ?? DateTime.now().toIso8601String(),
      );

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}