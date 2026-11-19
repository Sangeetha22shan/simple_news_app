
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class ArticleModel extends Equatable {
  final int id;
  final String title;
  final String url;
  final String? imageUrl;
  final String? summary;
  final String newsSite;
  final DateTime? publishedAt;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.url,
    this.imageUrl,
    this.summary,
    required this.newsSite,
    this.publishedAt,
  });

  // Converts API data into an article, supplying safe values for missing fields.
  factory ArticleModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ArticleModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? 0,

      title: json['title']?.toString() ?? 'Untitled',

      url: json['url']?.toString() ?? '',

      imageUrl: _nullableString(json['image_url']),

      summary: _nullableString(json['summary']),

      newsSite:
      json['news_site']?.toString() ?? 'Unknown',

      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse(
        json['published_at'].toString(),
      ),
    );
  }

  // Formats the publication date and time in the device's local timezone.
  String getPublishedDateTime() {
    final date = publishedAt;
    if (date == null) return 'Date unavailable';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  // Formats the publication date for the compact article card.
  String getPublishedDate() {
    final date = publishedAt;
    if (date == null) return 'Date unavailable';

    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    url,
    imageUrl,
    summary,
    newsSite,
    publishedAt,
  ];
}

class ArticlePage {
  final List<ArticleModel> articles;
  final String? nextPageUrl;

  const ArticlePage({
    required this.articles,
    required this.nextPageUrl,
  });
}
