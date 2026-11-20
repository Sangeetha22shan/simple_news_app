import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_news_app/core/errors/api_exception.dart';
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

  test('parses articles from a successful API response', () async {
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
        'next': null,
      },
    );

    final page = await repository.fetchArticles();

    expect(page.articles, hasLength(1));
    expect(page.articles.single.id, 42);
    expect(page.articles.single.title, 'A new space mission');
    expect(page.articles.single.newsSite, 'Example News');
  });

  test('returns an empty article list for an empty response', () async {
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async => {'results': [], 'next': null});

    final page = await repository.fetchArticles();

    expect(page.articles, isEmpty);
    expect(page.nextPageUrl, isNull);
  });

  test('maps the API-provided next URL for pagination', () async {
    const nextUrl = 'https://example.com/articles/?page=2';
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => {'results': [], 'next': nextUrl},
    );

    final page = await repository.fetchArticles();

    expect(page.nextPageUrl, nextUrl);
  });

  test('forwards search parameters to the API client', () async {
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async => {'results': [], 'next': null});

    await repository.fetchArticles(searchQuery: 'cricket');

    verify(
      () => apiClient.getArticles(
        pageUrl: null,
        searchQuery: 'cricket',
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

  test('propagates API exceptions', () async {
    when(
      () => apiClient.getArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenThrow(const ApiException(message: 'Server unavailable'));

    await expectLater(
      repository.fetchArticles(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Server unavailable',
        ),
      ),
    );
  });

  test('fetches and maps one article by ID', () async {
    when(() => apiClient.getArticleById(42)).thenAnswer(
      (_) async => {
        'id': 42,
        'title': 'A detailed space story',
        'url': 'https://example.com/article/42',
        'news_site': 'Example News',
        'published_at': '2026-11-20T08:00:00Z',
      },
    );

    final article = await repository.fetchArticleById(42);

    expect(article.id, 42);
    expect(article.title, 'A detailed space story');
    verify(() => apiClient.getArticleById(42)).called(1);
  });
}
