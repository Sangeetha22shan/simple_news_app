
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

  // Loads the initial feed and ignores results if a newer request replaces it.
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

  // Retries the current feed or search without clearing the active query.
  Future<void> retryNews() async {
    if (isClosed) return;

    _cancelDebounce();

    final query = state.searchQuery.trim();
    if (query.isEmpty) {
      await fetchNews();
      return;
    }

    final requestId = ++_requestId;
    await _performSearch(query, requestId);
  }

  // --------------------------------
  // SEARCH WITH DEBOUNCE
  // --------------------------------

  // Waits for typing to pause before starting a search request.
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

  // Replaces the feed with results for the latest debounced search.
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

  // Loads the next page, preventing duplicate requests and duplicate articles.
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

  // Retries a next-page request after the user selects Retry.
  Future<void> retryPagination() async {
    await loadMoreNews(retry: true);
  }

  // --------------------------------
  // PULL TO REFRESH
  // --------------------------------

  // Refreshes the current search/feed and reports whether it succeeded.
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

  // Gives known API/data errors specific messages and a safe generic fallback.
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
  // Cancels pending search work and invalidates requests before disposal.
  Future<void> close() {
    _cancelDebounce();
    _requestId++;

    return super.close();
  }
}
