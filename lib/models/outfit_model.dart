class Outfit {
  final String id;
  final String userId;
  final String? name;
  final String occasion;
  final String? weather;
  final String? mood;
  final String? colorPreference;
  final List<String> items;
  final int score;
  final DateTime createdAt;

  const Outfit({
    required this.id,
    required this.userId,
    this.name,
    required this.occasion,
    this.weather,
    this.mood,
    this.colorPreference,
    required this.items,
    required this.score,
    required this.createdAt,
  });

  Outfit copyWith({
    String? id,
    String? userId,
    String? name,
    String? occasion,
    String? weather,
    String? mood,
    String? colorPreference,
    List<String>? items,
    int? score,
    DateTime? createdAt,
  }) {
    return Outfit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      weather: weather ?? this.weather,
      mood: mood ?? this.mood,
      colorPreference: colorPreference ?? this.colorPreference,
      items: items ?? this.items,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'occasion': occasion,
      'weather': weather,
      'mood': mood,
      'colorPreference': colorPreference,
      'items': items,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Outfit.fromMap(Map<String, dynamic> map) {
    return Outfit(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'],
      occasion: map['occasion'] ?? '',
      weather: map['weather'],
      mood: map['mood'],
      colorPreference: map['colorPreference'],
      items: List<String>.from(map['items'] ?? []),
      score: map['score'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
