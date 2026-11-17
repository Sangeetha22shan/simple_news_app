
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/repositories/news_repository.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_state.dart';
import '../widgets/article_card.dart';

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsCubit(
        repository: NewsRepository(
          apiClient: ApiClient(),
        ),
      )..fetchNews(),
      child: const NewsListView(),
    );
  }
}

class NewsListView extends StatefulWidget {
  const NewsListView({super.key});

  @override
  State<NewsListView> createState() => _NewsListViewState();
}

class _NewsListViewState extends State<NewsListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      context.read<NewsCubit>().loadMoreNews();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state.status == NewsStatus.loading &&
              state.articles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == NewsStatus.failure &&
              state.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ??
                        'Something went wrong',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NewsCubit>().fetchNews();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.articles.isEmpty) {
            return const Center(
              child: Text('No articles found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<NewsCubit>().refreshNews(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet =
                    constraints.maxWidth >= 600;

                final columns = isTablet ? 2 : 1;

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.articles.length +
                      (state.hasMore || state.isLoadingMore
                          ? 1
                          : 0),
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: isTablet ? 340 : 290,
                  ),
                  itemBuilder: (context, index) {
                    if (index == state.articles.length) {
                      if (state.errorMessage != null &&
                          !state.isLoadingMore) {
                        return Center(
                          child: TextButton(
                            onPressed: () {
                              context
                                  .read<NewsCubit>()
                                  .loadMoreNews();
                            },
                            child: const Text(
                              'Loading failed. Retry',
                            ),
                          ),
                        );
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final article = state.articles[index];

                    return ArticleCard(
                      article: article,
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
