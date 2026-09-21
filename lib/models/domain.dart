class Domain {
  final int id;
  final String name;
  final String nameEn;
  final String color;

  Domain({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'color': color,
      };

  factory Domain.fromJson(Map<String, dynamic> j) => Domain(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        nameEn: j['nameEn'] ?? '',
        color: j['color'] ?? '#888888',
      );
}