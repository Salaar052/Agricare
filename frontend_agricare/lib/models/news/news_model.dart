class NewsModel {
  final String id;
  final String headlineEn;
  final String headlineUr;
  final String descriptionEn;
  final String descriptionUr;
  final List<String> imageUrls;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  const NewsModel({
    required this.id,
    required this.headlineEn,
    required this.headlineUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.imageUrls,
    required this.isPublished,
    required this.publishedAt,
    required this.createdAt,
  });

  String get bestHeadline => headlineEn.isNotEmpty ? headlineEn : headlineUr;

  String get bestDescription => descriptionEn.isNotEmpty ? descriptionEn : descriptionUr;

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> headline = {};
    final rawHeadline = json['headline'];
    if (rawHeadline is Map) headline = Map<String, dynamic>.from(rawHeadline);

    Map<String, dynamic> description = {};
    final rawDesc = json['description'];
    if (rawDesc is Map) description = Map<String, dynamic>.from(rawDesc);

    final urls = <String>[];

    // New format: images: [{url, publicId}, ...]
    final rawImages = json['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final u = m['url']?.toString() ?? '';
          if (u.isNotEmpty) urls.add(u);
        }
      }
    }

    // Legacy format: image: {url, publicId}
    Map<String, dynamic> image = {};
    final rawImage = json['image'];
    if (rawImage is Map) image = Map<String, dynamic>.from(rawImage);
    final legacyUrl = image['url']?.toString() ?? '';
    if (urls.isEmpty && legacyUrl.isNotEmpty) urls.add(legacyUrl);

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return NewsModel(
      id: json['_id']?.toString() ?? '',
      headlineEn: headline['en']?.toString() ?? '',
      headlineUr: headline['ur']?.toString() ?? '',
      descriptionEn: description['en']?.toString() ?? '',
      descriptionUr: description['ur']?.toString() ?? '',
      imageUrls: urls,
      isPublished: json['isPublished'] == true,
      publishedAt: parseDate(json['publishedAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }
}
