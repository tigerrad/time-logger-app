class Reminder {
  final int id;
  String title;
  String note;
  String dateTime;
  String category;
  bool done;

  Reminder({
    required this.id,
    required this.title,
    this.note = '',
    required this.dateTime,
    this.category = 'عمومی',
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dateTime': dateTime,
        'category': category,
        'done': done,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        note: j['note'] ?? '',
        dateTime: j['dateTime'] ?? DateTime.now().toIso8601String(),
        category: j['category'] ?? 'عمومی',
        done: j['done'] ?? false,
      );
}