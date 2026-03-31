class WardrobeItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String color;
  final String? pattern;
  final String? fabric;
  final List<String> seasons;
  final List<String> occasionTags;
  final String? notes;
  final String? imagePath;
  final String? styleVibe;
  final bool isFavorite;
  final DateTime dateAdded;

  const WardrobeItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.color,
    this.pattern,
    this.fabric,
    required this.seasons,
    required this.occasionTags,
    this.notes,
    this.imagePath,
    this.styleVibe,
    required this.isFavorite,
    required this.dateAdded,
  });

  WardrobeItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? color,
    String? pattern,
    String? fabric,
    List<String>? seasons,
    List<String>? occasionTags,
    String? notes,
    String? imagePath,
    String? styleVibe,
    bool? isFavorite,
    DateTime? dateAdded,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      pattern: pattern ?? this.pattern,
      fabric: fabric ?? this.fabric,
      seasons: seasons ?? this.seasons,
      occasionTags: occasionTags ?? this.occasionTags,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      styleVibe: styleVibe ?? this.styleVibe,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'color': color,
      'pattern': pattern,
      'fabric': fabric,
      'seasons': seasons,
      'occasionTags': occasionTags,
      'notes': notes,
      'imagePath': imagePath,
      'styleVibe': styleVibe,
      'isFavorite': isFavorite,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory WardrobeItem.fromMap(Map<String, dynamic> map) {
    return WardrobeItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      color: map['color'] ?? '',
      pattern: map['pattern'],
      fabric: map['fabric'],
      seasons: List<String>.from(map['seasons'] ?? []),
      occasionTags: List<String>.from(map['occasionTags'] ?? []),
      notes: map['notes'],
      imagePath: map['imagePath'],
      styleVibe: map['styleVibe'],
      isFavorite: map['isFavorite'] ?? false,
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }

  factory WardrobeItem.fromFirestore(Map<String, dynamic> data, String id) {
    return WardrobeItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      color: data['color'] ?? '',
      pattern: data['pattern'] ?? '',
      fabric: data['fabric'] ?? '',
      seasons: List<String>.from(data['seasons'] ?? []),
      occasionTags: List<String>.from(data['occasionTags'] ?? []),
      notes: data['notes'] ?? '',
      imagePath: data['imagePath'] ?? '',
      styleVibe: data['styleVibe'],
      dateAdded: data['dateAdded'] != null
          ? DateTime.parse(data['dateAdded'])
          : DateTime.now(),
      userId: data['userId'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'color': color,
      'pattern': pattern,
      'fabric': fabric,
      'seasons': seasons,
      'occasionTags': occasionTags,
      'notes': notes,
      'imagePath': imagePath,
      'styleVibe': styleVibe,
      'dateAdded': dateAdded.toIso8601String(),
      'userId': userId,
      'isFavorite': isFavorite,
    };
  }
}
