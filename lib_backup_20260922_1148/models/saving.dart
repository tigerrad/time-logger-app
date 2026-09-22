class Saving {
  final int id;
  String title;
  double target;
  double current;

  Saving({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'target': target,
        'current': current,
      };

  factory Saving.fromJson(Map<String, dynamic> j) => Saving(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        target: (j['target'] ?? 0).toDouble(),
        current: (j['current'] ?? 0).toDouble(),
      );
}