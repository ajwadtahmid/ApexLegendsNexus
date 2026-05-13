import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_article.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

final _pinnedNews = [
  NewsArticle(
    title: 'Official Apex Legends News',
    description: 'Patch notes, season updates, and announcements from EA.',
    link: 'https://www.ea.com/games/apex-legends/apex-legends/news',
    imageUrl: '',
  ),
];

final newsProvider = FutureProvider<ApiResult<List<NewsArticle>>>((ref) async {
  final result = await ref.watch(newsServiceProvider).getNews();
  return ApiResult([..._pinnedNews, ...result.data], staleAt: result.staleAt);
});
