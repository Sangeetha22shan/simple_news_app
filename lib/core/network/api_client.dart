import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({Dio? dio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: {'Accept': 'application/json'},
          ),
        );

    // Logging interceptor for development.
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false, error: true),
    );
  }

  // Fetches the first/search page or follows the API-provided next-page URL.
  Future<Map<String, dynamic>> getArticles({
    String? pageUrl,
    String? searchQuery,
  }) async {
    try {
      final response = await _dio.get(
        pageUrl ?? ApiConstants.articlesEndpoint,
        queryParameters: pageUrl == null
            ? {
                'limit': ApiConstants.pageSize,
                if (searchQuery != null && searchQuery.trim().isNotEmpty)
                  'title_contains': searchQuery.trim(),
              }
            : null,
      );

      if (response.data is! Map) {
        throw const ApiException(message: 'Invalid server response');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Fetches one article by its API identifier.
  Future<Map<String, dynamic>> getArticleById(int id) async {
    if (id <= 0) {
      throw const FormatException('Invalid article ID');
    }

    try {
      final response = await _dio.get(
        ApiConstants.articleEndpoint(id),
      );

      if (response.data is! Map) {
        throw const ApiException(message: 'Invalid server response');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Converts transport errors into messages the app can show to users.
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(message: 'No internet connection.');

      case DioExceptionType.unknown:
        if (error.error is FormatException) {
          return const ApiException(
            message: 'Invalid server URL. Please check the base URL.',
          );
        }
        if (error.error is SocketException) {
          return const ApiException(message: 'No internet connection.');
        }
        return const ApiException(message: 'Something went wrong.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ApiException(
          message: statusCode == null
              ? 'Server error. Please try again later.'
              : 'Server error (HTTP $statusCode). Please try again later.',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled.');

      default:
        return const ApiException(message: 'Something went wrong.');
    }
  }
}
