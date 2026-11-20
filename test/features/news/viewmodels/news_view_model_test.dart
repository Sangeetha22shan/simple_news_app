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

  test('fetchNews emits success with articles and next-page URL', () async {
    final articles = [article(1, 'First story')];
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => ArticlePage(
        articles: articles,
        nextPageUrl: 'https://example.com/page/2',
      ),
    );

    await viewModel.fetchNews();

    expect(viewModel.state.status, NewsStatus.success);
    expect(viewModel.state.articles, articles);
    expect(viewModel.state.nextPageUrl, 'https://example.com/page/2');
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
}
