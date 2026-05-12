import 'package:get/get.dart';

import '../api/api_config.dart';
import '../models/news/news_model.dart';
import '../services/news_service.dart';

class NewsController extends GetxController {
  late final NewsService _service;

  final RxBool isLoading = false.obs;
  final RxList<NewsModel> items = <NewsModel>[].obs;

  int _page = 1;
  final int _limit = 10;
  bool _hasNext = true;

  @override
  void onInit() {
    super.onInit();
    _service = NewsService(baseUrl: ApiConfig.apiV1Base);
  }

  Future<void> refreshFirstPage() async {
    _page = 1;
    _hasNext = true;
    items.clear();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading.value) return;
    if (!_hasNext) return;

    isLoading.value = true;
    try {
      final nextItems = await _service.getNews(page: _page, limit: _limit);
      if (_page == 1) {
        items.assignAll(nextItems);
      } else {
        items.addAll(nextItems);
      }

      if (nextItems.length < _limit) {
        _hasNext = false;
      } else {
        _page += 1;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
