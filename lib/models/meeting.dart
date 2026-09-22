class Meeting {
  final int id;
  String title;
  String link;
  String time;
  int duration;
  List<int> repeatWeekdays;
  String? alarmAt;

  Meeting({
    required this.id,
    required this.title,
    required this.link,
    required this.time,
    required this.duration,
    List<int>? repeatWeekdays,
    this.alarmAt,
  }) : repeatWeekdays = repeatWeekdays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'time': time,
        'duration': duration,
        'repeatWeekdays': repeatWeekdays,
        'alarmAt': alarmAt,
      };

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        link: j['link'] ?? '',
        time: j['time'] ?? '',
        duration: j['duration'] ?? 60,
        repeatWeekdays: (j['repeatWeekdays'] as List? ?? []).cast<int>(),
        alarmAt: j['alarmAt'],
      );
}