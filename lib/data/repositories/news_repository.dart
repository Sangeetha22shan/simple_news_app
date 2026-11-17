
import '../../core/network/api_client.dart';
import '../models/article_model.dart';

class ArticlePage {
  final List<ArticleModel> articles;
  final String? nextPageUrl;

  const ArticlePage({
    required this.articles,
    required this.nextPageUrl,
  });
}

class NewsRepository {
  final ApiClient apiClient;

  NewsRepository({
    required this.apiClient,
  });

  Future<ArticlePage> fetchArticles({
    String? pageUrl,
  }) async {
    final response = await apiClient.getArticles(
      pageUrl: pageUrl,
    );

    final results = response['results'];

    if (results is! List) {
      throw const FormatException(
        'Invalid articles response format',
      );
    }

    final articles = results
        .whereType<Map>()
        .map(
          (json) => ArticleModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();

    return ArticlePage(
      articles: articles,
      nextPageUrl: response['next']?.toString(),
    );
  }
}
