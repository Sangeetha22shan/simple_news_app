import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/responsive_constants.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/empty_state_view.dart';
import 'news_detail_screen.dart';
import '../viewmodels/news_state.dart';
import '../viewmodels/news_view_model.dart';
import '../widgets/article_card.dart';

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NewsListView();
  }
}

class NewsListView extends StatefulWidget {
  const NewsListView({super.key});

  @override
  State<NewsListView> createState() => _NewsListViewState();
}

class _NewsListViewState extends State<NewsListView> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  // Adds one grid cell for the pagination loader or retry state when needed.
  int _getItemCount(NewsState state) {
    final shouldShowFooter =
        state.isLoadingMore || state.paginationError != null;

    return state.articles.length + (shouldShowFooter ? 1 : 0);
  }

  void _showRefreshToast(NewsViewModel viewModel, bool refreshed) {
    final message = refreshed
        ? 'News refreshed successfully'
        : viewModel.state.errorMessage ?? 'Unable to refresh news';

    AppSnackBar.show(context, message);
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  // Requests another page when the user scrolls near the end of the grid.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    if (position.pixels >=
        position.maxScrollExtent - ResponsiveConstants.loadMoreThreshold) {
      context.read<NewsViewModel>().loadMoreNews();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  // Keeps the existing news state available while navigating to the reader.
  void _openArticleDetails(BuildContext context, int initialIndex) {
    final viewModel = context.read<NewsViewModel>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: viewModel,
          child: NewsDetailScreen(initialIndex: initialIndex),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: ResponsiveLayout.appBarTitleHeight(textScaler),
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            ResponsiveLayout.searchFieldHeight(textScaler),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Search news...',
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                context.read<NewsViewModel>().searchArticles(value);
              },
            ),
          ),
        ),
      ),

      body: BlocBuilder<NewsViewModel, NewsState>(
        builder: (context, state) {
          if (state.status == NewsStatus.loading && state.articles.isEmpty) {
            return const AppLoader();
          }

          if (state.status == NewsStatus.failure && state.articles.isEmpty) {
            return AppErrorView(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () {
                context.read<NewsViewModel>().retryNews();
              },
            );
          }

          if (state.articles.isEmpty) {
            return const EmptyStateView(
              icon: Icons.search_off,
              title: 'No articles found',
              message: 'Try searching with another keyword.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final viewModel = context.read<NewsViewModel>();
              final refreshed = await viewModel.refreshNews();

              if (!mounted) return;
              _showRefreshToast(viewModel, refreshed);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridLayout = ResponsiveLayout.newsGrid(
                  availableWidth: constraints.maxWidth,
                  textScaler: textScaler,
                );

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(
                    ResponsiveConstants.articleGridPadding,
                  ),
                  itemCount: _getItemCount(state),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridLayout.columns,
                    mainAxisSpacing: ResponsiveConstants.articleGridSpacing,
                    crossAxisSpacing: ResponsiveConstants.articleGridSpacing,
                    mainAxisExtent: gridLayout.cardExtent,
                  ),

                  itemBuilder: (context, index) {
                    // Pagination footer
                    if (index == state.articles.length) {
                      // Loading indicator
                      if (state.isLoadingMore) {
                        return const AppLoader();
                      }

                      // Retry button
                      if (state.paginationError != null) {
                        return AppErrorView(
                          message: state.paginationError!,
                          compact: true,
                          onRetry: () {
                            context.read<NewsViewModel>().retryPagination();
                          },
                        );
                      }
                    }

                    final article = state.articles[index];

                    return ArticleCard(
                      article: article,
                      onTap: () => _openArticleDetails(context, index),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
