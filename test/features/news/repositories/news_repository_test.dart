import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_news_app/core/network/api_client.dart';
import 'package:simple_news_app/features/news/repositories/news_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient apiClient;
  late NewsRepository repository;

  setUp(() {
    apiClient = MockApiClient();
    repository = NewsRepository(apiClient: apiClient);
  });

  test('maps article results and next-page URL from the API response', () async {
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => {
        'results': [
          {
            'id': 42,
            'title': 'A new space mission',
            'url': 'https://example.com/article',
            'news_site': 'Example News',
            'published_at': '2026-11-19T08:00:00Z',
          },
        ],
        'next': 'https://example.com/articles/?page=2',
      },
    );

    final page = await repository.fetchArticles(searchQuery: 'space');

    expect(page.articles, hasLength(1));
    expect(page.articles.single.id, 42);
    expect(page.articles.single.title, 'A new space mission');
    expect(page.nextPageUrl, 'https://example.com/articles/?page=2');
    verify(
      () => apiClient.getArticles(
        pageUrl: null,
        searchQuery: 'space',
      ),
    ).called(1);
  });

  test('throws FormatException when results is not a list', () async {
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async => {'results': 'invalid'});

    await expectLater(
      repository.fetchArticles(),
      throwsA(isA<FormatException>()),
    );
  });
}
