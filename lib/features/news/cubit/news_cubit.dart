
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/repositories/news_repository.dart';
import 'news_state.dart';
import 'dart:async';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository repository;
  Timer? _debounce;

  int _searchRequestId = 0;

  NewsCubit({
    required this.repository,
  }) : super(const NewsState());

  // Initial API request.
  Future<void> fetchNews() async {
    _debounce?.cancel();
    final requestId = ++_searchRequestId;

    emit(
      state.copyWith(
        status: NewsStatus.loading,
        clearError: true,
      ),
    );

    try {
      final page = await repository.fetchArticles();

      if (isClosed || requestId != _searchRequestId) return;

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
      if (isClosed || requestId != _searchRequestId) return;

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
  // Future<void> loadMoreNews() async {
  //   if (state.isLoadingMore ||
  //       state.isRefreshing ||
  //       !state.hasMore ||
  //       state.status != NewsStatus.success) {
  //     return;
  //   }
  //
  //   emit(
  //     state.copyWith(isLoadingMore: true),
  //   );
  //
  //   try {
  //
  //     final page = await repository.fetchArticles(
  //       searchQuery: state.searchQuery.isEmpty
  //           ? null
  //           : state.searchQuery,
  //     );
  //
  //     final existingIds = state.articles
  //         .map((article) => article.id)
  //         .toSet();
  //
  //     final newArticles = page.articles.where(
  //           (article) => !existingIds.contains(article.id),
  //     );
  //
  //     final updatedArticles = [
  //       ...state.articles,
  //       ...newArticles,
  //     ];
  //
  //     emit(
  //       state.copyWith(
  //         articles: updatedArticles,
  //         nextPageUrl: page.nextPageUrl,
  //         isLoadingMore: false,
  //         clearError: true,
  //         clearNextPage: page.nextPageUrl == null,
  //       ),
  //     );
  //   } catch (e) {
  //     emit(
  //       state.copyWith(
  //         isLoadingMore: false,
  //         errorMessage: _errorMessage(e),
  //       ),
  //     );
  //   }
  // }
  Future<void> loadMoreNews() async {
    print('========== PAGINATION CHECK ==========');
    print('Has more: ${state.hasMore}');
    print('Loading more: ${state.isLoadingMore}');
    print('Next URL: ${state.nextPageUrl}');

    if (state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore ||
        state.status != NewsStatus.success) {
      print('Pagination skipped');
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await repository.fetchArticles(
        pageUrl: state.nextPageUrl,
      );

      print('Next page articles: ${page.articles.length}');
      print('Next page URL: ${page.nextPageUrl}');

      final existingIds = state.articles
          .map((article) => article.id)
          .toSet();

      final newArticles = page.articles.where(
            (article) => !existingIds.contains(article.id),
      );

      emit(
        state.copyWith(
          articles: [
            ...state.articles,
            ...newArticles,
          ],
          nextPageUrl: page.nextPageUrl,
          isLoadingMore: false,
          clearError: true,
          clearNextPage: page.nextPageUrl == null,
        ),
      );
    } catch (e) {
      print('Pagination error: $e');

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

// Called whenever the user types.
  void searchArticles(String query) {
    _debounce?.cancel();

    final requestId = ++_searchRequestId;

    // Wait until the user stops typing.
    _debounce = Timer(
      const Duration(milliseconds: 500),
          () {
        _performSearch(query.trim(), requestId);
      },
    );
  }

// Performs the actual API request.
  Future<void> _performSearch(
      String query,
      int requestId,
      ) async {
    if (isClosed || requestId != _searchRequestId) {
      return;
    }

    emit(
      state.copyWith(
        status: NewsStatus.loading,
        articles: [],
        searchQuery: query,
        clearNextPage: true,
        clearError: true,
        isLoadingMore: false,
      ),
    );

    try {
      final page = await repository.fetchArticles(
        searchQuery: query.isEmpty ? null : query,
      );

      // Ignore outdated API responses.
      if (isClosed || requestId != _searchRequestId) {
        return;
      }

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
      if (isClosed || requestId != _searchRequestId) {
        return;
      }

      emit(
        state.copyWith(
          status: NewsStatus.failure,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }
  @override
  Future<void> close() {
    _debounce?.cancel();
    _searchRequestId++;
    return super.close();
  }
}
