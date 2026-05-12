import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_config.dart';
import '../../models/news/news_model.dart';
import '../../services/news_service.dart';
import '../../widgets/news/news_card.dart';
import 'admin_create_news_screen.dart';
import 'news_detail_screen.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  late final NewsService _service;

  bool _loading = true;
  List<NewsModel> _items = const [];
  bool _deleting = false;

  // ── Palette ──
  static const _dark    = Color(0xFF2D5016);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF7A9B6A);
  static const _bg      = Color(0xFFF6FAF4);
  static const _border  = Color(0xFFE3EFD9);
  static const _surface = Color(0xFFEAF3E3);

  @override
  void initState() {
    super.initState();
    _service = NewsService(baseUrl: ApiConfig.apiV1Base);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getNews(page: 1, limit: 30);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      _service.showError(e.toString());
      if (mounted) setState(() => _items = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(NewsModel news) async {
    if (_deleting) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete news?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          news.bestHeadline.isEmpty
              ? 'This will permanently delete the news.'
              : news.bestHeadline,
          style: const TextStyle(
              fontSize: 14, color: _light, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel',
                style: TextStyle(color: _light, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteNews(news.id);
      await _load();
    } catch (e) {
      _service.showError(e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _loading ? _buildLoadingState() : _buildBody(),
    );
  }

  // ──────────────────────────────────────────
  // AppBar — plain PreferredSize, no Sliver
  // ──────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Color(0xFFE3EFD9), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Back
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bg,
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15, color: _dark),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_dark, _mid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.newspaper_rounded,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                // Title
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'News Manager',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _dark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Manage all articles',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _light,
                        ),
                      ),
                    ],
                  ),
                ),
                // Create pill
                GestureDetector(
                  onTap: () async {
                    await Get.to(
                      () => const AdminCreateNewsScreen(),
                      transition: Transition.rightToLeftWithFade,
                      duration: const Duration(milliseconds: 320),
                    );
                    await _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_dark, _mid],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _dark.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 15, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Body
  // ──────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _mid,
      child: _items.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  // ──────────────────────────────────────────
  // List
  // ──────────────────────────────────────────
  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      children: [
        // Deleting indicator
        if (_deleting)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _mid),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Deleting…',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _light),
                ),
              ],
            ),
          ),

        // ── Horizontal cards strip ──
        // Height 220 gives the NewsCard room; bottom padding absorbs
        // any internal shadow so the overflow warning disappears.
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            clipBehavior: Clip.none,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final news = _items[index];
              return NewsCard(
                news: news,
                onTap: () => Get.to(
                  () => NewsDetailScreen(news: news),
                  transition: Transition.rightToLeftWithFade,
                  duration: const Duration(milliseconds: 320),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Section header ──
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3, height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_dark, _mid],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'All articles',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${_items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── News tiles ──
        ..._items.map((n) => _buildNewsTile(n)),
      ],
    );
  }

  // ──────────────────────────────────────────
  // News tile
  // ──────────────────────────────────────────
  Widget _buildNewsTile(NewsModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Get.to(
          () => NewsDetailScreen(news: n),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 320),
        ),
        borderRadius: BorderRadius.circular(16),
        splashColor: _mid.withOpacity(0.06),
        highlightColor: _mid.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.article_rounded,
                    size: 20, color: _mid),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      n.bestHeadline.isEmpty ? 'News' : n.bestHeadline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.bestDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _light,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: n.id.isEmpty ? null : () => _delete(n),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFFCDD2), width: 1),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 17, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Empty state
  // ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border, width: 1.5),
                ),
                child: const Icon(Icons.newspaper_rounded,
                    size: 38, color: _light),
              ),
              const SizedBox(height: 20),
              const Text(
                'No news yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap Create to publish your first article',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _light,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  await Get.to(
                    () => const AdminCreateNewsScreen(),
                    transition: Transition.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 320),
                  );
                  await _load();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_dark, _mid],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _dark.withOpacity(0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Create article',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Loading state
  // ──────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _mid, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading articles…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _light,
            ),
          ),
        ],
      ),
    );
  }
}