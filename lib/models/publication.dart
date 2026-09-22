class Publication {
  final int id;
  String title;
  String filePath;
  String fileType;
  String category;
  String date;
  String note;

  Publication({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileType,
    this.category = 'عمومی',
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'fileType': fileType,
        'category': category,
        'date': date,
        'note': note,
      };

  factory Publication.fromJson(Map<String, dynamic> j) => Publication(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        filePath: j['filePath'] ?? '',
        fileType: j['fileType'] ?? '',
        category: j['category'] ?? 'عمومی',
        date: j['date'] ?? DateTime.now().toIso8601String(),
        note: j['note'] ?? '',
      );
}