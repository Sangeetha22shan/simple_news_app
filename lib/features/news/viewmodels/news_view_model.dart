
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../repositories/news_repository.dart';
import 'news_state.dart';

class NewsViewModel extends Cubit<NewsState> {
  final NewsRepository repository;

  Timer? _debounce;

  // Identifies the latest search/refresh operation.
  int _requestId = 0;

  NewsViewModel({
    required this.repository,
  }) : super(const NewsState());

  // --------------------------------
  // INITIAL NEWS
  // --------------------------------

  Future<void> fetchNews() async {
    _cancelDebounce();

    final requestId = ++_requestId;

    emit(
      state.copyWith(
        status: NewsStatus.loading,
        articles: [],
        searchQuery: '',
        clearNextPage: true,
        clearError: true,
        clearPaginationError: true,
        isLoadingMore: false,
        isRefreshing: false,
      ),
    );

    try {
      final page = await repository.fetchArticles();

      if (isClosed || requestId != _requestId) return;

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
      if (isClosed || requestId != _requestId) return;

      emit(
        state.copyWith(
          status: NewsStatus.failure,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }

  // --------------------------------
  // SEARCH WITH DEBOUNCE
  // --------------------------------

  void searchArticles(String query) {
    if (isClosed) return;

    _cancelDebounce();

    final requestId = ++_requestId;

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _debounce = null;
        _performSearch(query.trim(), requestId);
      },
    );
  }

  Future<void> _performSearch(
      String query,
      int requestId,
      ) async {
    if (isClosed || requestId != _requestId) return;

    emit(
      state.copyWith(
        status: NewsStatus.loading,
        articles: [],
        searchQuery: query,
        clearNextPage: true,
        clearError: true,
        clearPaginationError: true,
        isLoadingMore: false,
        isRefreshing: false,
      ),
    );

    try {
      final page = await repository.fetchArticles(
        searchQuery: query.isEmpty ? null : query,
      );

      if (isClosed || requestId != _requestId) return;

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
      if (isClosed || requestId != _requestId) return;

      emit(
        state.copyWith(
          status: NewsStatus.failure,
          errorMessage: _errorMessage(e),
        ),
      );
    }
  }

  // --------------------------------
  // PAGINATION
  // --------------------------------

  Future<void> loadMoreNews({bool retry = false}) async {
    // Prevent duplicate requests.
    if (isClosed ||
        state.status != NewsStatus.success ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }

    // Do not retry automatically after a failure.
    if (state.paginationError != null && !retry) {
      return;
    }

    final currentRequestId = _requestId;
    final nextUrl = state.nextPageUrl!;



    emit(
      state.copyWith(
        isLoadingMore: true,
        clearPaginationError: true,
      ),
    );

    try {
      final page = await repository.fetchArticles(
        pageUrl: nextUrl,
      );

      // Ignore results from an outdated search or refresh.
      if (isClosed || currentRequestId != _requestId) return;

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
          status: NewsStatus.success,
          articles: updatedArticles,
          nextPageUrl: page.nextPageUrl,
          clearNextPage: page.nextPageUrl == null,
          isLoadingMore: false,
          clearPaginationError: true,
        ),
      );


    } catch (e) {
      if (isClosed || currentRequestId != _requestId) return;

      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationError: _errorMessage(e),
        ),
      );


    }
  }

  // --------------------------------
  // RETRY PAGINATION
  // --------------------------------

  Future<void> retryPagination() async {
    await loadMoreNews(retry: true);
  }

  // --------------------------------
  // PULL TO REFRESH
  // --------------------------------

  Future<bool> refreshNews() async {
    if (isClosed || state.isRefreshing) return false;

    _cancelDebounce();

    final requestId = ++_requestId;

    emit(
      state.copyWith(
        isRefreshing: true,
        clearError: true,
        clearPaginationError: true,
        isLoadingMore: false,
      ),
    );

    try {
      final page = await repository.fetchArticles(
        searchQuery: state.searchQuery.isEmpty
            ? null
            : state.searchQuery,
      );

      if (isClosed || requestId != _requestId) return false;

      emit(
        state.copyWith(
          status: NewsStatus.success,
          articles: page.articles,
          nextPageUrl: page.nextPageUrl,
          clearNextPage: page.nextPageUrl == null,
          isRefreshing: false,
          clearError: true,
          clearPaginationError: true,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed || requestId != _requestId) return false;

      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: _errorMessage(e),
        ),
      );
      return false;
    }
  }

  // --------------------------------
  // ERROR HANDLING
  // --------------------------------

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return 'Invalid data received from server.';
    }

    return 'Something went wrong. Please try again.';
  }

  // --------------------------------
  // DISPOSE
  // --------------------------------

  void _cancelDebounce() {
    _debounce?.cancel();
    _debounce = null;
  }

  @override
  Future<void> close() {
    _cancelDebounce();
    _requestId++;

    return super.close();
  }
}
