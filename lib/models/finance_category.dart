class FinanceCategory {
  final int id;
  final String name;
  final String type;
  final String color;
  final double monthlyBudget;

  FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.monthlyBudget = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'monthlyBudget': monthlyBudget,
      };

  factory FinanceCategory.fromJson(Map<String, dynamic> j) => FinanceCategory(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        type: j['type'] ?? 'expense',
        color: j['color'] ?? '#888888',
        monthlyBudget: (j['monthlyBudget'] ?? 0).toDouble(),
      );

  FinanceCategory copyWith({String? name, String? color, double? monthlyBudget}) =>
      FinanceCategory(
        id: id,
        name: name ?? this.name,
        type: type,
        color: color ?? this.color,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      );
}