
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/repositories/news_repository.dart';
import 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;

  NewsCubit({
    required this.repository,
  }) : super(const NewsState());

  // Initial API request.
  Future<void> fetchNews() async {
    emit(
      state.copyWith(
        status: NewsStatus.loading,
        clearError: true,
      ),
    );

    try {
      final page = await repository.fetchArticles();

      emit(
        state.copyWith(
          status: NewsStatus.success,
          articles: page.articles,
          nextPageUrl: page.nextPageUrl,
          clearNextPage: page.nextPageUrl == null,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NewsStatus.failure,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }

  // Pull-to-refresh.
  Future<void> refreshNews() async {
    if (state.isRefreshing) return;

    emit(
      state.copyWith(
        isRefreshing: true,
        clearError: true,
      ),
    );

    try {
      final page = await repository.fetchArticles();

      emit(
        state.copyWith(
          status: NewsStatus.success,
          articles: page.articles,
          nextPageUrl: page.nextPageUrl,
          clearNextPage: page.nextPageUrl == null,
          clearError: true,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }

  // Pagination.
  Future<void> loadMoreNews() async {
    if (state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore ||
        state.status != NewsStatus.success) {
      return;
    }

    emit(
      state.copyWith(isLoadingMore: true),
    );

    try {
      final page = await repository.fetchArticles(
        pageUrl: state.nextPageUrl,
      );

      final existingIds = state.articles
          .map((article) => article.id)
          .toSet();

      final newArticles = page.articles.where(
            (article) => !existingIds.contains(article.id),
      );

      final updatedArticles = [
        ...state.articles,
        ...newArticles,
      ];

      emit(
        state.copyWith(
          articles: updatedArticles,
          nextPageUrl: page.nextPageUrl,
          isLoadingMore: false,
          clearError: true,
          clearNextPage: page.nextPageUrl == null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return 'Invalid data received from server.';
    }

    return 'Something went wrong. Please try again.';
  }
}
