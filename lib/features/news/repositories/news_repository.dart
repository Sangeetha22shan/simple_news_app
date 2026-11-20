
import '../../../core/network/api_client.dart';
import '../models/article_model.dart';

class NewsRepository {
  final ApiClient apiClient;

  NewsRepository({
    required this.apiClient,
  });

  // Fetches the complete article details for an article ID.
  Future<ArticleModel> fetchArticleById(int id) async {
    if (id <= 0) {
      throw const FormatException('Invalid article ID');
    }

    final response = await apiClient.getArticleById(id);
    return ArticleModel.fromJson(response);
  }

  // Validates the API payload and converts its results and next-page link.
  Future<ArticlePage> fetchArticles({
    String? pageUrl,
    String? searchQuery,
  }) async {
    final response = await apiClient.getArticles(
      pageUrl: pageUrl,
      searchQuery: searchQuery,
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
          (json) =>
          ArticleModel.fromJson(
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
