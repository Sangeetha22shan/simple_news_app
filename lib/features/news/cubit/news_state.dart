
import 'package:equatable/equatable.dart';

import '../../../data/models/article_model.dart';

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
  final bool isLoadingMore;
  final bool isRefreshing;
  final String searchQuery;

  const NewsState({
    this.status = NewsStatus.initial,
    this.articles = const [],
    this.nextPageUrl,
    this.errorMessage,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.searchQuery = '',
  });

  bool get hasMore => nextPageUrl != null;

  NewsState copyWith({
    NewsStatus? status,
    List<ArticleModel>? articles,
    String? nextPageUrl,
    String? errorMessage,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool clearError = false,
    bool clearNextPage = false,
    String? searchQuery,
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
    isRefreshing,
    searchQuery,
  ];
}
