import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_news_app/core/errors/api_exception.dart';
import 'package:simple_news_app/features/news/models/article_model.dart';
import 'package:simple_news_app/features/news/repositories/news_repository.dart';
import 'package:simple_news_app/features/news/viewmodels/news_state.dart';
import 'package:simple_news_app/features/news/viewmodels/news_view_model.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

ArticleModel article(int id, String title) => ArticleModel(
  id: id,
  title: title,
  url: 'https://example.com/$id',
  newsSite: 'Example News',
);

void main() {
  late MockNewsRepository repository;
  late NewsViewModel viewModel;

  setUp(() {
    repository = MockNewsRepository();
    viewModel = NewsViewModel(repository: repository);
  });

  tearDown(() async {
    await viewModel.close();
  });

  test('starts in the initial state', () {
    expect(viewModel.state.status, NewsStatus.initial);
  });

  test('fetchNews emits initial loading and then success', () async {
    final articles = [article(1, 'First story')];
    final response = Completer<ArticlePage>();
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) => response.future);

    final states = <NewsState>[];
    final subscription = viewModel.stream.listen(states.add);
    final fetch = viewModel.fetchNews();

    expect(viewModel.state.status, NewsStatus.loading);
    expect(viewModel.state.articles, isEmpty);

    response.complete(
      ArticlePage(
        articles: articles,
        nextPageUrl: 'https://example.com/page/2',
      ),
    );
    await fetch;
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.status, NewsStatus.success);
    expect(viewModel.state.articles, articles);
    expect(viewModel.state.nextPageUrl, 'https://example.com/page/2');
    expect(
      states.map((state) => state.status),
      [NewsStatus.loading, NewsStatus.success],
    );
    await subscription.cancel();
  });

  test('fetchNews exposes API errors in the failure state', () async {
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenThrow(
      const ApiException(message: 'Server error (HTTP 503).'),
    );

    await viewModel.fetchNews();

    expect(viewModel.state.status, NewsStatus.failure);
    expect(viewModel.state.errorMessage, 'Server error (HTTP 503).');
  });

  test('retryNews preserves the active search query', () async {
    var callCount = 0;

    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        throw const ApiException(message: 'Server error (HTTP 503).');
      }

      return const ArticlePage(
        articles: [],
        nextPageUrl: null,
      );
    });

    viewModel.searchArticles('space');
    await Future<void>.delayed(const Duration(milliseconds: 550));

    await viewModel.retryNews();

    expect(viewModel.state.searchQuery, 'space');
    verify(
      () => repository.fetchArticles(
        pageUrl: null,
        searchQuery: 'space',
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  test('search waits for the debounce before making an API request', () async {
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => const ArticlePage(articles: [], nextPageUrl: null),
    );

    viewModel.searchArticles('cricket');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    verifyNever(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    verify(
      () => repository.fetchArticles(
        pageUrl: null,
        searchQuery: 'cricket',
      ),
    ).called(1);
    expect(viewModel.state.searchQuery, 'cricket');
    expect(viewModel.state.status, NewsStatus.success);
  });

  test('ignores a response from an older search', () async {
    final oldResponse = Completer<ArticlePage>();
    final currentArticles = [article(2, 'Current result')];
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((invocation) {
      final query = invocation.namedArguments[#searchQuery] as String?;
      if (query == 'old') return oldResponse.future;
      return Future.value(
        ArticlePage(articles: currentArticles, nextPageUrl: null),
      );
    });

    viewModel.searchArticles('old');
    await Future<void>.delayed(const Duration(milliseconds: 550));
    viewModel.searchArticles('current');
    await Future<void>.delayed(const Duration(milliseconds: 550));

    expect(viewModel.state.articles, currentArticles);
    expect(viewModel.state.searchQuery, 'current');

    oldResponse.complete(
      ArticlePage(
        articles: [article(1, 'Stale result')],
        nextPageUrl: null,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.articles, currentArticles);
    expect(viewModel.state.searchQuery, 'current');
  });

  test('prevents concurrent duplicate pagination requests', () async {
    final pageResponse = Completer<ArticlePage>();
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((invocation) {
      if (invocation.namedArguments[#pageUrl] == null) {
        return Future.value(
          ArticlePage(
            articles: [article(1, 'First')],
            nextPageUrl: 'https://example.com/page/2',
          ),
        );
      }
      return pageResponse.future;
    });

    await viewModel.fetchNews();
    final firstLoad = viewModel.loadMoreNews();
    final secondLoad = viewModel.loadMoreNews();

    verify(
      () => repository.fetchArticles(
        pageUrl: 'https://example.com/page/2',
        searchQuery: null,
      ),
    ).called(1);

    pageResponse.complete(
      ArticlePage(articles: [article(2, 'Second')], nextPageUrl: null),
    );
    await Future.wait([firstLoad, secondLoad]);
    expect(viewModel.state.articles.map((item) => item.id), [1, 2]);
  });

  test('pagination failure is retained until retry succeeds', () async {
    var nextPageCalls = 0;
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((invocation) async {
      if (invocation.namedArguments[#pageUrl] == null) {
        return ArticlePage(
          articles: [article(1, 'First')],
          nextPageUrl: 'https://example.com/page/2',
        );
      }

      nextPageCalls++;
      if (nextPageCalls == 1) {
        throw const ApiException(message: 'Page unavailable');
      }
      return ArticlePage(
        articles: [article(2, 'Second')],
        nextPageUrl: null,
      );
    });

    await viewModel.fetchNews();
    await viewModel.loadMoreNews();

    expect(viewModel.state.paginationError, 'Page unavailable');
    expect(viewModel.state.isLoadingMore, isFalse);

    await viewModel.loadMoreNews();
    expect(nextPageCalls, 1);

    await viewModel.retryPagination();
    expect(viewModel.state.paginationError, isNull);
    expect(viewModel.state.articles.map((item) => item.id), [1, 2]);
    expect(nextPageCalls, 2);
  });

  test('refresh replaces feed and reports successful completion', () async {
    var callCount = 0;
    final refreshedArticles = [article(2, 'Refreshed story')];
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((_) async {
      callCount++;
      return ArticlePage(
        articles: callCount == 1
            ? [article(1, 'Original story')]
            : refreshedArticles,
        nextPageUrl: null,
      );
    });

    await viewModel.fetchNews();
    final refresh = viewModel.refreshNews();

    expect(viewModel.state.isRefreshing, isTrue);
    expect(await refresh, isTrue);
    expect(viewModel.state.isRefreshing, isFalse);
    expect(viewModel.state.articles, refreshedArticles);
    verify(
      () => repository.fetchArticles(pageUrl: null, searchQuery: null),
    ).called(2);
  });

  test('loadMoreNews adds only articles not already in the feed', () async {
    final first = article(1, 'First story');
    final duplicate = article(1, 'Duplicate story');
    final next = article(2, 'Second story');

    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer((invocation) async {
      if (invocation.namedArguments[#pageUrl] == null) {
        return ArticlePage(
          articles: [first],
          nextPageUrl: 'https://example.com/page/2',
        );
      }
      return ArticlePage(
        articles: [duplicate, next],
        nextPageUrl: null,
      );
    });

    await viewModel.fetchNews();
    await viewModel.loadMoreNews();

    expect(viewModel.state.articles, [first, next]);
    expect(viewModel.state.nextPageUrl, isNull);
    expect(viewModel.state.isLoadingMore, isFalse);
  });

  test('closing the Cubit cancels a pending search debounce', () async {
    viewModel.searchArticles('pending');

    await viewModel.close();
    await Future<void>.delayed(const Duration(milliseconds: 550));

    verifyNever(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    );
  });
}
