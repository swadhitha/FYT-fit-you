class BodyProfile {
  final String id;
  final String? bodyType;
  final double? shoulderWidth;
  final double? hipWidth;
  final double? torsoLength;
  final double? legLength;
  final double? armLength;
  final DateTime analyzedAt;

  const BodyProfile({
    required this.id,
    this.bodyType,
    this.shoulderWidth,
    this.hipWidth,
    this.torsoLength,
    this.legLength,
    this.armLength,
    required this.analyzedAt,
  });

  BodyProfile copyWith({
    String? id,
    String? bodyType,
    double? shoulderWidth,
    double? hipWidth,
    double? torsoLength,
    double? legLength,
    double? armLength,
    DateTime? analyzedAt,
  }) {
    return BodyProfile(
      id: id ?? this.id,
      bodyType: bodyType ?? this.bodyType,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      hipWidth: hipWidth ?? this.hipWidth,
      torsoLength: torsoLength ?? this.torsoLength,
      legLength: legLength ?? this.legLength,
      armLength: armLength ?? this.armLength,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bodyType': bodyType,
      'shoulderWidth': shoulderWidth,
      'hipWidth': hipWidth,
      'torsoLength': torsoLength,
      'legLength': legLength,
      'armLength': armLength,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory BodyProfile.fromMap(Map<String, dynamic> map) {
    return BodyProfile(
      id: map['id'] ?? '',
      bodyType: map['bodyType'],
      shoulderWidth: map['shoulderWidth']?.toDouble(),
      hipWidth: map['hipWidth']?.toDouble(),
      torsoLength: map['torsoLength']?.toDouble(),
      legLength: map['legLength']?.toDouble(),
      armLength: map['armLength']?.toDouble(),
      analyzedAt: DateTime.parse(map['analyzedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'shoulderWidth': shoulderWidth,
      'hipWidth': hipWidth,
      'torsoLength': torsoLength,
      'legLength': legLength,
      'armLength': armLength,
      'bodyType': bodyType,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory BodyProfile.fromFirestore(Map<String, dynamic> data, String id) =>
    BodyProfile(
      id: id,
      shoulderWidth: (data['shoulderWidth'] ?? 0).toDouble(),
      hipWidth: (data['hipWidth'] ?? 0).toDouble(),
      torsoLength: (data['torsoLength'] ?? 0).toDouble(),
      legLength: (data['legLength'] ?? 0).toDouble(),
      armLength: (data['armLength'] ?? 0).toDouble(),
      bodyType: data['bodyType'] ?? 'Rectangle',
      analyzedAt: data['analyzedAt'] != null
          ? DateTime.parse(data['analyzedAt'])
          : DateTime.now(),
    );
}
