class Goal {
  final int id;
  String title;
  String level;
  String domain;
  int progress;

  Goal({
    required this.id,
    required this.title,
    required this.level,
    required this.domain,
    required this.progress,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'level': level,
        'domain': domain,
        'progress': progress,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        level: j['level'] ?? '',
        domain: j['domain'] ?? '',
        progress: j['progress'] ?? 0,
      );
}