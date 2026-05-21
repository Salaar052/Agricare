// ============================================================
// plant_model.dart — Data Models
// ============================================================

class PlantAI {
  final List<String> pros;
  final List<String> cons;
  final String tips;

  const PlantAI({required this.pros, required this.cons, required this.tips});

  factory PlantAI.fromJson(Map<String, dynamic> json) {
    return PlantAI(
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
      tips: json['tips'] ?? '',
    );
  }

  factory PlantAI.empty() => const PlantAI(pros: [], cons: [], tips: '');
}

class PlantRecommendation {
  final int id;
  final String name;
  final String emoji;
  final String category;
  final int score;
  final int maxScore;
  final PlantAI ai;

  const PlantRecommendation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.score,
    required this.maxScore,
    required this.ai,
  });

  double get scorePercent => score / maxScore;

  factory PlantRecommendation.fromJson(Map<String, dynamic> json) {
    return PlantRecommendation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '🌱',
      category: json['category'] ?? '',
      score: json['score'] ?? 0,
      maxScore: json['maxScore'] ?? 11,
      ai: json['ai'] != null ? PlantAI.fromJson(json['ai']) : PlantAI.empty(),
    );
  }
}

class RecommendationRequest {
  final double temperature;
  final String space;
  final String sunlight;
  final String water;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;

  const RecommendationRequest({
    required this.temperature,
    required this.space,
    required this.sunlight,
    required this.water,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'space': space,
    'sunlight': sunlight,
    'water': water,
    if (latitude != null && longitude != null)
      'location': {
        'lat': latitude,
        'lng': longitude,
        if (locationLabel != null && locationLabel!.trim().isNotEmpty)
          'label': locationLabel!.trim(),
      },
  };
}

class RecommendationResponse {
  final bool success;
  final List<PlantRecommendation> plants;
  final String? message;
  final String? error;

  const RecommendationResponse({
    required this.success,
    required this.plants,
    this.message,
    this.error,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      success: json['success'] ?? false,
      plants: (json['plants'] as List<dynamic>? ?? [])
          .map((p) => PlantRecommendation.fromJson(p))
          .toList(),
      message: json['message'],
      error: json['error'],
    );
  }

  factory RecommendationResponse.error(String errorMsg) {
    return RecommendationResponse(success: false, plants: [], error: errorMsg);
  }
}
