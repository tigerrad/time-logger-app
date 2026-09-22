class TimeEntry {
  final int id;
  final String domain;
  final String start;
  final String end;
  final int minutes;
  final String note;

  TimeEntry({
    required this.id,
    required this.domain,
    required this.start,
    required this.end,
    required this.minutes,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain,
        'start': start,
        'end': end,
        'minutes': minutes,
        'note': note,
      };

  factory TimeEntry.fromJson(Map<String, dynamic> j) => TimeEntry(
        id: j['id'] ?? 0,
        domain: j['domain'] ?? '',
        start: j['start'] ?? '',
        end: j['end'] ?? '',
        minutes: j['minutes'] ?? 0,
        note: j['note'] ?? '',
      );

  TimeEntry copyWith({
    int? id,
    String? domain,
    String? start,
    String? end,
    int? minutes,
    String? note,
  }) =>
      TimeEntry(
        id: id ?? this.id,
        domain: domain ?? this.domain,
        start: start ?? this.start,
        end: end ?? this.end,
        minutes: minutes ?? this.minutes,
        note: note ?? this.note,
      );
}