/// Dart model classes for API serialization.
/// Maps to backend Pydantic schemas.

// ─── User ──────────────────────────────────────────────────

class User {
  final int id;
  final String name;
  final String email;
  final String stylePreference;
  final String climateRegion;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.stylePreference = 'Minimal',
    this.climateRegion = 'Tropical',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      stylePreference: json['style_preference'] ?? 'Minimal',
      climateRegion: json['climate_region'] ?? 'Tropical',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'style_preference': stylePreference,
    'climate_region': climateRegion,
  };
}

// ─── Body Profile ──────────────────────────────────────────

class BodyProfile {
  final int id;
  final int userId;
  final double heightCm;
  final double weightKg;
  final double shoulderCm;
  final double chestCm;
  final double waistCm;
  final double hipCm;
  final double inseamCm;
  final String bodyType;
  final double bmi;
  final String bmiCategory;
  final double shoulderToHipRatio;
  final double waistToHipRatio;
  final double legToHeightRatio;
  final String proportionSummary;
  final List<String> stylingSuggestions;

  BodyProfile({
    required this.id,
    required this.userId,
    required this.heightCm,
    required this.weightKg,
    required this.shoulderCm,
    required this.chestCm,
    required this.waistCm,
    required this.hipCm,
    required this.inseamCm,
    required this.bodyType,
    required this.bmi,
    required this.bmiCategory,
    required this.shoulderToHipRatio,
    required this.waistToHipRatio,
    required this.legToHeightRatio,
    required this.proportionSummary,
    required this.stylingSuggestions,
  });

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    return BodyProfile(
      id: json['id'],
      userId: json['user_id'],
      heightCm: (json['height_cm'] as num).toDouble(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      shoulderCm: (json['shoulder_cm'] as num).toDouble(),
      chestCm: (json['chest_cm'] as num).toDouble(),
      waistCm: (json['waist_cm'] as num).toDouble(),
      hipCm: (json['hip_cm'] as num).toDouble(),
      inseamCm: (json['inseam_cm'] as num).toDouble(),
      bodyType: json['body_type'],
      bmi: (json['bmi'] as num).toDouble(),
      bmiCategory: json['bmi_category'],
      shoulderToHipRatio: (json['shoulder_to_hip_ratio'] as num).toDouble(),
      waistToHipRatio: (json['waist_to_hip_ratio'] as num).toDouble(),
      legToHeightRatio: (json['leg_to_height_ratio'] as num).toDouble(),
      proportionSummary: json['proportion_summary'],
      stylingSuggestions: List<String>.from(json['styling_suggestions'] ?? []),
    );
  }
}

// ─── Wardrobe Item ─────────────────────────────────────────

class WardrobeItem {
  final int id;
  final int userId;
  final String? name;
  final String category;
  final String color;
  final String? fabric;
  final String formality;
  final String? imagePath;
  final int usageCount;

  WardrobeItem({
    required this.id,
    required this.userId,
    this.name,
    required this.category,
    required this.color,
    this.fabric,
    required this.formality,
    this.imagePath,
    this.usageCount = 0,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      category: json['category'],
      color: json['color'],
      fabric: json['fabric'],
      formality: json['formality'],
      imagePath: json['image_path'],
      usageCount: json['usage_count'] ?? 0,
    );
  }
}

// ─── Outfit Recommendation ─────────────────────────────────

class OutfitItem {
  final int id;
  final String? name;
  final String category;
  final String color;
  final String formality;

  OutfitItem({
    required this.id,
    this.name,
    required this.category,
    required this.color,
    required this.formality,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) {
    return OutfitItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      color: json['color'],
      formality: json['formality'],
    );
  }
}

class OutfitSuggestion {
  final int rank;
  final List<OutfitItem> items;
  final Map<String, dynamic> scores;
  final List<String> explanation;

  OutfitSuggestion({
    required this.rank,
    required this.items,
    required this.scores,
    required this.explanation,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestion(
      rank: json['rank'],
      items: (json['items'] as List).map((i) => OutfitItem.fromJson(i)).toList(),
      scores: Map<String, dynamic>.from(json['scores']),
      explanation: List<String>.from(json['explanation']),
    );
  }
}

class RecommendationResponse {
  final String occasion;
  final String? mood;
  final String? climate;
  final List<OutfitSuggestion> outfits;
  final String? bodyType;

  RecommendationResponse({
    required this.occasion,
    this.mood,
    this.climate,
    required this.outfits,
    this.bodyType,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      occasion: json['occasion'],
      mood: json['mood'],
      climate: json['climate'],
      outfits: (json['outfits'] as List)
          .map((o) => OutfitSuggestion.fromJson(o))
          .toList(),
      bodyType: json['body_type'],
    );
  }
}

// ─── Chat Message ──────────────────────────────────────────

class ChatMsg {
  final String role; // 'user' or 'assistant'
  final String message;
  final String? intent;
  final List<String> suggestions;

  ChatMsg({
    required this.role,
    required this.message,
    this.intent,
    this.suggestions = const [],
  });
}

class ChatApiResponse {
  final String response;
  final String intent;
  final Map<String, dynamic>? extractedPreferences;
  final List<String> suggestions;

  ChatApiResponse({
    required this.response,
    required this.intent,
    this.extractedPreferences,
    required this.suggestions,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      response: json['response'],
      intent: json['intent'],
      extractedPreferences: json['extracted_preferences'],
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}
