import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/news/news_model.dart';

class NewsCard extends StatefulWidget {
  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
  });

  final NewsModel news;
  final VoidCallback onTap;

  static const _accent = Color(0xFF4A7C2C);
  static const _surface = Color(0xFFF4F9F2);

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  PageController? _pageController;
  Timer? _timer;
  int _pageIndex = 0;

  List<String> get _urls => widget.news.imageUrls;

  void _startAuto() {
    _timer?.cancel();
    _pageController?.dispose();
    _pageController = null;

    if (_urls.length <= 1) return;

    _pageController = PageController(initialPage: 0);
    _pageIndex = 0;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final controller = _pageController;
      if (!mounted || controller == null) return;
      final next = (_pageIndex + 1) % _urls.length;
      _pageIndex = next;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void didUpdateWidget(covariant NewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.news.id != widget.news.id ||
        oldWidget.news.imageUrls.length != widget.news.imageUrls.length) {
      _startAuto();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: NewsCard._surface,
      alignment: Alignment.center,
      child: const Icon(Icons.image_rounded, size: 30, color: Colors.grey),
    );
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: NewsCard._surface,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        return Container(
          color: NewsCard._surface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_rounded,
            size: 30,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _imageCarousel() {
    if (_urls.isEmpty) return _imagePlaceholder();
    if (_urls.length == 1) return _networkImage(_urls.first);

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => _pageIndex = i,
      itemCount: _urls.length,
      itemBuilder: (context, index) => _networkImage(_urls[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headline = widget.news.bestHeadline;
    final desc = widget.news.bestDescription;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // ✅ Removed fixed width:250 and right margin — card now fills
        // the full PageView width so it never fights the 210px height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD2E5CC)),
          boxShadow: [
            BoxShadow(
              color: NewsCard._accent.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅ don't stretch beyond content
          children: [
            // ── Image area: 130px → 126px to give text room ──────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 126, // ✅ was 130 — freed 4px for text section
                width: double.infinity,
                child: _imageCarousel(),
              ),
            ),

            // ── Text area: must fit in remaining 210-126 = 84px ──────────
            // padding(8+8) + headline(1line≈19px) + gap(4) + desc(1line≈17px)
            // = 16 + 19 + 4 + 17 = 56px  ✅ fits with room to spare
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // ✅ was 10/12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headline.isEmpty ? 'News' : headline,
                    maxLines: 2,           // ✅ kept 2 lines
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,        // ✅ was 15 — saves ~2.5px per line
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3748),
                      height: 1.2,         // ✅ was 1.25 — tighter leading
                    ),
                  ),
                  const SizedBox(height: 4), // ✅ was 6
                  Text(
                    desc,
                    maxLines: 1,           // ✅ was 2 — this was the overflow culprit
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,        // ✅ was 12.5
                      height: 1.3,         // ✅ was 1.35
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500, // ✅ was w600
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}