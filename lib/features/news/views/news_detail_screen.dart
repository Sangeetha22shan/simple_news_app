import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _loadMoreIfNeeded(int index, int articleCount) {
    if (index >= articleCount - 2) {
      context.read<NewsViewModel>().loadMoreNews();
    }
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

            final safeIndex = _currentIndex.clamp(0, articles.length - 1);
            if (safeIndex != _currentIndex) {
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

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: false,
                    itemCount: articles.length,
                    onPageChanged: (index) {
                      _onPageChanged(index, articles.length);
                    },
                    itemBuilder: (context, index) {
                      return _ArticleDetailContent(article: articles[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Article ${safeIndex + 1} of ${articles.length}',
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

class _ArticleDetailContent extends StatelessWidget {
  final ArticleModel article;

  const _ArticleDetailContent({required this.article});

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(article.url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid article URL')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open article')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publishedDate = article.publishedAt == null
        ? 'Date unavailable'
        : DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(article.publishedAt!.toLocal());

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
                            article.newsSite.isNotEmpty
                                ? article.newsSite[0].toUpperCase()
                                : 'N',
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
                      publishedDate,
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
                      article.summary?.isNotEmpty == true
                          ? article.summary!
                          : 'No description available.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: article.url.isEmpty
                            ? null
                            : () => _openArticle(context),
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
