import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_snack_bar.dart';

import '../models/article_model.dart';
import '../viewmodels/news_state.dart';
import '../viewmodels/news_view_model.dart';
import '../widgets/article_image.dart';

class NewsDetailScreen extends StatefulWidget {
  final int initialIndex;

  const NewsDetailScreen({super.key, required this.initialIndex});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final articleCount = context
            .read<NewsViewModel>()
            .state
            .articles
            .length;
        _loadMoreIfNeeded(_currentIndex, articleCount);
      }
    });
  }

  void _onPageChanged(int index, int articleCount) {
    setState(() {
      _currentIndex = index;
    });

    _loadMoreIfNeeded(index, articleCount);
  }

  // Starts pagination shortly before the reader reaches the final article.
  void _loadMoreIfNeeded(int index, int articleCount) {
    if (index >= articleCount - 2) {
      context.read<NewsViewModel>().loadMoreNews();
    }
  }

  // Keeps the visible page valid if a search or refresh shortens the list.
  void _clampCurrentIndex(List<ArticleModel> articles) {
    final safeIndex = _currentIndex.clamp(0, articles.length - 1);
    if (safeIndex == _currentIndex) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;

      final currentArticleCount = context
          .read<NewsViewModel>()
          .state
          .articles
          .length;
      if (currentArticleCount == 0) return;

      final currentSafeIndex = _currentIndex.clamp(
        0,
        currentArticleCount - 1,
      );
      setState(() {
        _currentIndex = currentSafeIndex;
      });
      _pageController.jumpToPage(currentSafeIndex);
    });
  }

  String _getArticlePositionText(int safeIndex, int articleCount) {
    final position = safeIndex + 1;
    return 'Article $position of $articleCount';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article Details'), centerTitle: true),
      body: SafeArea(
        child: BlocBuilder<NewsViewModel, NewsState>(
            builder: (context, state) {
              final articles = state.articles;

              if (articles.isEmpty) {
                return const Center(child: Text('No articles available'));
              }

              _clampCurrentIndex(articles);
              final safeIndex = _currentIndex.clamp(0, articles.length - 1);
              final articlePositionText = _getArticlePositionText(
                safeIndex,
                articles.length,
              );

              return Column(
              children: [
                Expanded(
                  // Swipe navigation follows the Gmail-style interaction demonstrated in the assignment's reference video.
// Left swipe  → Next article.
// Right swipe → Previous article.
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: false,
                    itemCount: articles.length,
                    onPageChanged: (index) {
                      _onPageChanged(index, articles.length);
                    },
                    itemBuilder: (context, index) {
                      return _ArticleDetailContent(
                        key: ValueKey(articles[index].id),
                        articleId: articles[index].id,
                        fallbackArticle: articles[index],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        articlePositionText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (state.isLoadingMore) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ] else if (state.paginationError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.paginationError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<NewsViewModel>().retryPagination();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArticleDetailContent extends StatefulWidget {
  final int articleId;
  final ArticleModel fallbackArticle;

  const _ArticleDetailContent({
    super.key,
    required this.articleId,
    required this.fallbackArticle,
  });

  @override
  State<_ArticleDetailContent> createState() =>
      _ArticleDetailContentState();
}

class _ArticleDetailContentState extends State<_ArticleDetailContent> {
  late Future<ArticleModel> _articleFuture;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  @override
  void didUpdateWidget(_ArticleDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articleId != widget.articleId) {
      _loadArticle();
    }
  }

  void _loadArticle() {
    final repository = context.read<NewsViewModel>().repository;
    _articleFuture = repository.fetchArticleById(widget.articleId);
  }

  // Validates the article link before opening it outside the app.
  Future<void> _openArticle(
    BuildContext context,
    ArticleModel article,
  ) async {
    final uri = Uri.tryParse(article.url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      AppSnackBar.show(context, 'Invalid article URL');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        AppSnackBar.show(context, 'Unable to open article');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.show(context, 'Something went wrong');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ArticleModel>(
      future: _articleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load article details.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(_loadArticle),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildArticle(
          context,
          snapshot.data ?? widget.fallbackArticle,
        );
      },
    );
  }

  Widget _buildArticle(BuildContext context, ArticleModel article) {
    final theme = Theme.of(context);
    final newsSiteInitial = article.newsSite.isNotEmpty
        ? article.newsSite[0].toUpperCase()
        : 'N';
    final articleSummary = article.summary?.isNotEmpty == true
        ? article.summary!
        : 'No description available.';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ArticleImage(
                  imageUrl: article.imageUrl,
                  placeholderIconSize: 55,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            newsSiteInitial,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            article.newsSite,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.getPublishedDateTime(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      articleSummary,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: article.url.isEmpty
                            ? null
                            : () => _openArticle(context, article),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Read Full Article'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
