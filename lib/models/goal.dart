class Goal {
  final int id;
  String title;
  String level;
  String domain;
  int progress;
  String note;
  String? deadline;

  Goal({
    required this.id,
    required this.title,
    required this.level,
    required this.domain,
    required this.progress,
    this.note = '',
    this.deadline,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'level': level,
        'domain': domain,
        'progress': progress,
        'note': note,
        'deadline': deadline,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        level: j['level'] ?? '',
        domain: j['domain'] ?? '',
        progress: j['progress'] ?? 0,
        note: j['note'] ?? '',
        deadline: j['deadline'],
      );
}