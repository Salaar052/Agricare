import 'package:flutter/material.dart';

import '../../models/news/news_model.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.news});

  final NewsModel news;

  static const _pageBg = Color(0xFFF4F9F2);

  @override
  Widget build(BuildContext context) {
    final headlineEn = news.headlineEn.trim();
    final headlineUr = news.headlineUr.trim();
    final descEn = news.descriptionEn.trim();
    final descUr = news.descriptionUr.trim();

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: const Color(0xFF3E6D25),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [

          /// ✅ IMAGE SECTION FIXED
          if (news.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: news.imageUrls.length == 1
                    ? Image.network(
                        news.primaryImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            size: 38,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : PageView.builder(
                        itemCount: news.imageUrls.length,
                        itemBuilder: (context, index) {
                          final url = news.imageUrls[index];
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) => p == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 38,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

          const SizedBox(height: 14),

          _section(
            label: 'English',
            title: headlineEn,
            body: descEn,
            emptyFallback: headlineUr.isEmpty && descUr.isEmpty
                ? 'No content available'
                : 'English content not provided.',
          ),

          const SizedBox(height: 12),

          _section(
            label: 'Urdu',
            title: headlineUr,
            body: descUr,
            emptyFallback: headlineEn.isEmpty && descEn.isEmpty
                ? 'No content available'
                : 'Urdu content not provided.',
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String label,
    required String title,
    required String body,
    required String emptyFallback,
  }) {
    final hasAny = title.isNotEmpty || body.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2E5CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          if (!hasAny)
            Text(
              emptyFallback,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: Color(0xFF2D3748),
                ),
              ),
            if (title.isNotEmpty && body.isNotEmpty)
              const SizedBox(height: 8),
            if (body.isNotEmpty)
              Text(
                body,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ]
        ],
      ),
    );
  }
}