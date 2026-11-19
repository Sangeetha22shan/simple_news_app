import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    if (position.pixels >=
        position.maxScrollExtent - AppConstants.loadMoreThreshold) {
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

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleHeight = math.max(65.0, textScaler.scale(26) + 32);
    final searchHeight = math.max(65.0, textScaler.scale(16) + 49);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: titleHeight,
        title: const Text(
          AppConstants.discoverTitle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(searchHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<NewsViewModel>().searchArticles(value);
              },
              decoration: InputDecoration(
                hintText: AppConstants.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          context.read<NewsViewModel>().searchArticles('');
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.10),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
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
              message: state.errorMessage ?? AppConstants.unknownError,
              onRetry: () {
                context.read<NewsViewModel>().fetchNews();
              },
            );
          }

          if (state.articles.isEmpty) {
            return const EmptyStateView(
              icon: Icons.search_off,
              title: AppConstants.emptyArticlesTitle,
              message: AppConstants.emptyArticlesMessage,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final viewModel = context.read<NewsViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final refreshed = await viewModel.refreshNews();

              if (!mounted) return;

              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      refreshed
                          ? AppConstants.refreshSuccessMessage
                          : viewModel.state.errorMessage ??
                                AppConstants.refreshFailureMessage,
                    ),
                  ),
                );
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = math.max(1.0, textScaler.scale(16) / 16);
                final isTablet =
                    constraints.maxWidth >= AppConstants.tabletBreakpoint;
                final isWideTablet =
                    constraints.maxWidth >=
                    AppConstants.wideTabletBreakpoint;

                final columns =
                    textScale >= AppConstants.appBarTextScaleBreakpoint
                    ? 1
                    : isWideTablet
                    ? 3
                    : isTablet
                    ? 2
                    : 1;
                final baseCardExtent = isTablet
                    ? AppConstants.tabletArticleExtent
                    : AppConstants.phoneArticleExtent;
                final cardExtent =
                    baseCardExtent +
                    (textScale - 1) * AppConstants.extraCardHeightPerScale;

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(
                    AppConstants.articleGridPadding,
                  ),
                  itemCount:
                      state.articles.length +
                      ((state.isLoadingMore || state.paginationError != null)
                          ? 1
                          : 0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppConstants.articleGridSpacing,
                    crossAxisSpacing: AppConstants.articleGridSpacing,
                    mainAxisExtent: cardExtent,
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
                      onTap: () {
                        final viewModel = context.read<NewsViewModel>();

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BlocProvider.value(
                              value: viewModel,
                              child: NewsDetailScreen(initialIndex: index),
                            ),
                          ),
                        );
                      },
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
