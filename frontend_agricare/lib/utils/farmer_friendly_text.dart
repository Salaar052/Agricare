// lib/utils/farmer_friendly_text.dart

class FarmerFriendlyText {
  static const Map<String, String> _replacements = {
    'utilize': 'use',
    'utilising': 'using',
    'utilizing': 'using',
    'approximately': 'about',
    'precipitation': 'rain (baarish/بارش)',
    'rainfall': 'rain (baarish/بارش)',

    // Watering terms
    'irrigation': 'watering (pani/پانی)',
    'irrigate': 'water (pani/پانی)',
    'watering': 'watering (pani/پانی)',
    'water': 'water (pani/پانی)',

    // Fertilizer terms
    'fertilization': 'fertilizer (khaad/کھاد)',
    'fertiliser': 'fertilizer (khaad/کھاد)',
    'fertilizer': 'fertilizer (khaad/کھاد)',

    // Spray / pesticide terms
    'pesticide': 'spray/pesticide (dawai/دوائی)',
    'insecticide': 'insect spray (dawai/دوائی)',
    'fungicide': 'fungus spray (dawai/دوائی)',
    'herbicide': 'weed spray (dawai/دوائی)',
    'application': 'use',
    'apply': 'use',
    'recommended': 'best',
    'optimal': 'best',
    'mitigate': 'reduce',
    'monitor': 'check',
    'symptoms': 'signs',
    'advisable': 'good',
    'ensure': 'make sure',
    'sufficient': 'enough',
    'excessive': 'too much',
    'deficiency': 'lack',
    'nutrient': 'plant food',
    'nutrients': 'plant food',
    'seed': 'seed (beej/بیج)',
    'seeds': 'seeds (beej/بیج)',
    'sowing': 'sowing (beejai/بیجائی)',
    'planting': 'planting (boi/بوائی)',
    'weeding': 'weeding (ghas nikalna/گھاس نکالنا)',
    'disease': 'disease (bimari/بیماری)',
    'pest': 'pest (keera/کیڑا)',
    'cultivation': 'growing',
    'germination': 'sprouting',
  };

  static String simplify(String input) {
    var text = input.trim();
    if (text.isEmpty) return '';

    // Normalize whitespace.
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Remove common verbose fillers.
    text = text
        .replaceAll(RegExp(r'\b(in order to|it is recommended that|it is advisable to)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+,\s+'), ', ')
        .replaceAll(RegExp(r'\s+\.'), '.')
        .trim();

    // Simple word replacements (case-insensitive, word-boundary).
    _replacements.forEach((from, to) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(from)}\\b', caseSensitive: false), to);
    });

    // If it is a long paragraph, keep it readable.
    if (text.length > 160) {
      final parts = _splitSentences(text);
      if (parts.isNotEmpty) {
        text = parts.take(2).join('. ');
        if (!text.endsWith('.')) text += '.';
      }
    }

    // Trim trailing punctuation noise.
    text = text.replaceAll(RegExp(r'[\s\-:;]+$'), '').trim();
    return text;
  }

  static List<String> simplifyList(
    List<String> items, {
    int maxItems = 12,
  }) {
    final out = <String>[];
    for (final raw in items) {
      final simplified = simplify(raw);
      if (simplified.isEmpty) continue;

      // If a single bullet contains multiple sentences, split it.
      final sub = _splitSentences(simplified);
      if (sub.length >= 2) {
        for (final s in sub) {
          final v = simplify(s);
          if (v.isNotEmpty) out.add(_capFirst(v));
        }
      } else {
        out.add(_capFirst(simplified));
      }
    }

    // De-duplicate while preserving order.
    final seen = <String>{};
    final dedup = <String>[];
    for (final s in out) {
      final key = s.toLowerCase();
      if (seen.add(key)) dedup.add(s);
    }
    return dedup.take(maxItems).toList();
  }

  static List<String> fromUnknown(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    if (value is String) {
      final parts = value
          .split(RegExp(r'[\n•\u2022]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) return parts;
      return _splitSentences(value);
    }
    return const [];
  }

  static List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _capFirst(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    return first + s.substring(1);
  }
}
