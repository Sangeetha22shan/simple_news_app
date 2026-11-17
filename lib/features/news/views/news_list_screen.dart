
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
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()
      ..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      final cubit = context.read<NewsCubit>();

      if (cubit.state.hasMore &&
          !cubit.state.isLoadingMore &&
          !cubit.state.isRefreshing) {
        cubit.loadMoreNews();
      }
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
    return Scaffold(

      appBar: AppBar(
        toolbarHeight: 65,
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<NewsCubit>().searchArticles(value);
              },
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<NewsCubit>()
                        .searchArticles('');
                    setState(() {});
                  },
                ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.10),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No articles found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try searching with another keyword.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
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
                      (state.isLoadingMore ||
                          (state.errorMessage != null && state.hasMore)
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
                      if (state.isLoadingMore) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return Center(
                        child: TextButton(
                          onPressed: () {
                            context.read<NewsCubit>().loadMoreNews();
                          },
                          child: const Text('Loading failed. Retry'),
                        ),
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
