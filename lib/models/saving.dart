class SavingTransaction {
  final int id;
  final double amount;
  final String type;
  final String date;
  final String note;

  SavingTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'date': date,
        'note': note,
      };

  factory SavingTransaction.fromJson(Map<String, dynamic> j) => SavingTransaction(
        id: j['id'] ?? 0,
        amount: (j['amount'] ?? 0).toDouble(),
        type: j['type'] ?? 'deposit',
        date: j['date'] ?? DateTime.now().toIso8601String(),
        note: j['note'] ?? '',
      );
}

class Saving {
  final int id;
  String title;
  double target;
  double current;
  List<SavingTransaction> history;

  Saving({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
    List<SavingTransaction>? history,
  }) : history = history ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target': target,
        'current': current,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory Saving.fromJson(Map<String, dynamic> j) => Saving(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        target: (j['target'] ?? 0).toDouble(),
        current: (j['current'] ?? 0).toDouble(),
        history: (j['history'] as List? ?? [])
            .map((e) => SavingTransaction.fromJson(e))
            .toList(),
      );
}