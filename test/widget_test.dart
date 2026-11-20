
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:simple_news_app/main.dart';
import 'package:simple_news_app/features/news/models/article_model.dart';
import 'package:simple_news_app/features/news/repositories/news_repository.dart';
import 'package:simple_news_app/features/news/viewmodels/news_view_model.dart';

class MockNewsRepository extends Mock implements NewsRepository {}

void main() {
  group('Simple News App Widget Tests', () {
    late MockNewsRepository repository;
    late NewsViewModel viewModel;

    setUp(() {
      repository = MockNewsRepository();
      viewModel = NewsViewModel(repository: repository);

      when(
        () => repository.fetchArticles(
          pageUrl: any(named: 'pageUrl'),
          searchQuery: any(named: 'searchQuery'),
        ),
      ).thenAnswer(
        (_) async => const ArticlePage(
          articles: [],
          nextPageUrl: null,
        ),
      );
    });

    tearDown(() async {
      await viewModel.close();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      await viewModel.fetchNews();
      await tester.pumpWidget(SimpleNewsApp(viewModel: viewModel));
    }

    testWidgets('App launches successfully', (tester) async {
      await pumpApp(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Displays Discover title', (tester) async {
      await pumpApp(tester);

      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('Displays news search field', (tester) async {
      await pumpApp(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search news...'), findsOneWidget);
    });
  });
}
