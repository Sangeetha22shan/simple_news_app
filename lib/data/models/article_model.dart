
import 'package:equatable/equatable.dart';

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
