class Meeting {
  final int id;
  String title;
  String link;
  String time;
  int duration;
  List<int> weekdays;

  Meeting({
    required this.id,
    required this.title,
    required this.link,
    required this.time,
    required this.duration,
    this.weekdays = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'time': time,
        'duration': duration,
        'weekdays': weekdays,
      };

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        link: j['link'] ?? '',
        time: j['time'] ?? '',
        duration: j['duration'] ?? 0,
        weekdays: (j['weekdays'] as List?)?.map((e) => e as int).toList() ?? [],
      );

  String get weekdaysText {
    if (weekdays.isEmpty) return 'بدون تکرار';
    const names = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه'];
    return weekdays.map((d) => names[d - 1]).join('، ');
  }
}