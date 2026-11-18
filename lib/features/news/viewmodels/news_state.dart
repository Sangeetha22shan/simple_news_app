
import 'package:equatable/equatable.dart';

import '../models/article_model.dart';

enum NewsStatus {
  initial,
  loading,
  success,
  failure,
}

class NewsState extends Equatable {
  final NewsStatus status;

  final List<ArticleModel> articles;

  final String? nextPageUrl;

  final String? errorMessage;

  // Pagination properties
  final bool isLoadingMore;
  final String? paginationError;

  // Refresh property
  final bool isRefreshing;

  // Search property
  final String searchQuery;

  const NewsState({
    this.status = NewsStatus.initial,
    this.articles = const [],
    this.nextPageUrl,
    this.errorMessage,
    this.isLoadingMore = false,
    this.paginationError,
    this.isRefreshing = false,
    this.searchQuery = '',
  });

  bool get hasMore =>
      nextPageUrl != null && nextPageUrl!.isNotEmpty;

  NewsState copyWith({
    NewsStatus? status,
    List<ArticleModel>? articles,
    String? nextPageUrl,
    String? errorMessage,
    bool? isLoadingMore,
    String? paginationError,
    bool? isRefreshing,
    String? searchQuery,
    bool clearError = false,
    bool clearNextPage = false,
    bool clearPaginationError = false,
  }) {
    return NewsState(
      status: status ?? this.status,
      articles: articles ?? this.articles,

      nextPageUrl: clearNextPage
          ? null
          : nextPageUrl ?? this.nextPageUrl,

      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,

      isLoadingMore:
      isLoadingMore ?? this.isLoadingMore,

      paginationError: clearPaginationError
          ? null
          : paginationError ?? this.paginationError,

      isRefreshing: isRefreshing ?? this.isRefreshing,

      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    status,
    articles,
    nextPageUrl,
    errorMessage,
    isLoadingMore,
    paginationError,
    isRefreshing,
    searchQuery,
  ];
}
