import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_news_app/features/news/models/article_model.dart';
import 'package:simple_news_app/features/news/repositories/news_repository.dart';
import 'package:simple_news_app/features/news/viewmodels/news_view_model.dart';
import 'package:simple_news_app/features/news/views/news_detail_screen.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

ArticleModel article(int id, String title) => ArticleModel(
  id: id,
  title: title,
  url: 'https://example.com/articles/$id',
  summary: 'Summary for $title',
  newsSite: 'Example News',
);

void main() {
  late MockNewsRepository repository;
  late NewsViewModel viewModel;
  final articles = [
    article(1, 'Newest Article'),
    article(2, 'Middle Article'),
    article(3, 'Oldest Article'),
  ];

  setUp(() {
    repository = MockNewsRepository();
    viewModel = NewsViewModel(repository: repository);
    when(
      () => repository.fetchArticles(
        pageUrl: any(named: 'pageUrl'),
        searchQuery: any(named: 'searchQuery'),
      ),
    ).thenAnswer(
      (_) async => ArticlePage(articles: articles, nextPageUrl: null),
    );
    when(() => repository.fetchArticleById(any())).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments.single as int;
      return articles.singleWhere((article) => article.id == id);
    });
  });

  tearDown(() async {
    await viewModel.close();
  });

  Future<void> pumpDetailScreen(
    WidgetTester tester, {
    int initialIndex = 1,
  }) async {
    await viewModel.fetchNews();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: viewModel,
          child: NewsDetailScreen(initialIndex: initialIndex),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads detail content for the selected article ID', (
    tester,
  ) async {
    await pumpDetailScreen(tester);

    expect(find.text('Middle Article'), findsOneWidget);
    expect(find.text('Summary for Middle Article'), findsOneWidget);
    expect(find.text('Article 2 of 3'), findsOneWidget);
    verify(() => repository.fetchArticleById(2)).called(1);
  });

  testWidgets('swiping left opens the next news article', (tester) async {
    await pumpDetailScreen(tester);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Article 3 of 3'), findsOneWidget);
    expect(find.text('Oldest Article'), findsOneWidget);
  });

  testWidgets('swiping right opens the previous news article', (tester) async {
    await pumpDetailScreen(tester);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Article 1 of 3'), findsOneWidget);
    expect(find.text('Newest Article'), findsOneWidget);
  });
}
