class Meeting {
  final int id;
  String title;
  String link;
  String time;
  int duration;

  Meeting({
    required this.id,
    required this.title,
    required this.link,
    required this.time,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'link': link,
        'time': time,
        'duration': duration,
      };

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        link: j['link'] ?? '',
        time: j['time'] ?? '',
        duration: j['duration'] ?? 0,
      );
}