
class ApiConstants {
  static const String baseUrl =
      'https://api.spaceflightnewsapi.net/v4';

  static const String articlesEndpoint = '/articles/';

  static const int pageSize = 10;

  static const Duration connectTimeout =
  Duration(seconds: 15);

  static const Duration receiveTimeout =
  Duration(seconds: 15);
}
