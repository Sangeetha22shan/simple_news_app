class AppConstants {
  static const String appName = 'Simple News App';
  static const String discoverTitle = 'Discover';
  static const String searchHint = 'Search news...';
  static const String retryLabel = 'Retry';
  static const String unknownError = 'Something went wrong';
  static const String emptyArticlesTitle = 'No articles found';
  static const String emptyArticlesMessage =
      'Try searching with another keyword.';
  static const String refreshSuccessMessage = 'News refreshed successfully';
  static const String refreshFailureMessage = 'Unable to refresh news';

  static const int tabletBreakpoint = 600;
  static const int wideTabletBreakpoint = 1000;
  static const double loadMoreThreshold = 300;
  static const double articleGridPadding = 16;
  static const double articleGridSpacing = 12;
  static const double phoneArticleExtent = 290;
  static const double tabletArticleExtent = 340;
  static const double appBarTextScaleBreakpoint = 1.3;
  static const double extraCardHeightPerScale = 180;

  const AppConstants._();
}
