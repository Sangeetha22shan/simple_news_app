import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_news_app/core/errors/api_exception.dart';
import 'package:simple_news_app/features/news/models/article_model.dart';
import 'package:simple_news_app/features/news/repositories/news_repository.dart';
import 'package:simple_news_app/features/news/viewmodels/news_view_model.dart';
import 'package:simple_news_app/features/news/views/news_list_screen.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: viewModel,
          child: const NewsListScreen(),
        ),
      ),
    );
  }

  testWidgets('shows fetched articles in the news grid', (tester) async {
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => ArticlePage(
        articles: [
          ArticleModel(
            id: 7,
            title: 'A new space discovery',
            url: 'https://example.com/7',
            newsSite: 'Example News',
          ),
        ],
        nextPageUrl: null,
      ),
    );
    await viewModel.fetchNews();

    await pumpScreen(tester);

    expect(find.text('A new space discovery'), findsOneWidget);
    expect(find.text('Example News'), findsOneWidget);
  });

  testWidgets('shows the API error and retries when tapped', (tester) async {
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenThrow(const ApiException(message: 'Server error (HTTP 503).'));
    await viewModel.fetchNews();

    await pumpScreen(tester);

    expect(find.text('Server error (HTTP 503).'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).called(2);
  });

  testWidgets('shows the no internet error in the UI', (tester) async {
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenThrow(const ApiException(message: 'No internet connection.'));
    await viewModel.fetchNews();

    await pumpScreen(tester);

    expect(find.text('No internet connection.'), findsOneWidget);
  });
}
