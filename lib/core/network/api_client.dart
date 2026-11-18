
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Logging interceptor for development.
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        error: true,
      ),
    );
  }


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
          if (searchQuery != null &&
              searchQuery.trim().isNotEmpty)
            'search': searchQuery.trim(),
        }
            : null,
      );

      if (response.data is! Map) {
        throw const ApiException(
          message: 'Invalid server response',
        );
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection.',
        );

      case DioExceptionType.badResponse:
        return ApiException(
          message:
          'Server error. Please try again later.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request cancelled.',
        );

      default:
        return const ApiException(
          message: 'Something went wrong.',
        );
    }
  }
}
