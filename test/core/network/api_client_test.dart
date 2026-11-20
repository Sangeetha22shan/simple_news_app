import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_news_app/core/errors/api_exception.dart';
import 'package:simple_news_app/core/network/api_client.dart';

void main() {
  Dio dioWithError(DioException Function(RequestOptions) createError) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(createError(options));
        },
      ),
    );
    return dio;
  }

  Future<void> expectApiError({
    required DioException Function(RequestOptions) createError,
    required String message,
    int? statusCode,
  }) async {
    final apiClient = ApiClient(dio: dioWithError(createError));

    await expectLater(
      apiClient.getArticles(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', message)
            .having((error) => error.statusCode, 'statusCode', statusCode),
      ),
    );
  }

  test('reports host lookup failures as no internet', () async {
    final apiClient = ApiClient(
      dio: dioWithError(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException("Failed host lookup: 'invalid.example'"),
        ),
      ),
    );

    await expectLater(
      apiClient.getArticles(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'No internet connection.',
        ),
      ),
    );
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  ]) {
    test('maps $type to a timeout message', () async {
      await expectApiError(
        createError: (options) =>
            DioException(requestOptions: options, type: type),
        message: 'Request timed out. Please try again.',
      );
    });
  }

  test('maps an invalid server URL to a specific message', () async {
    await expectApiError(
      createError: (options) => DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: const FormatException('Invalid URL'),
      ),
      message: 'Invalid server URL. Please check the base URL.',
    );
  });

  test('maps other unknown errors to a generic message', () async {
    await expectApiError(
      createError: (options) => DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: StateError('Unexpected failure'),
      ),
      message: 'Something went wrong.',
    );
  });

  test('maps other Dio error types to a generic message', () async {
    await expectApiError(
      createError: (options) => DioException(
        requestOptions: options,
        type: DioExceptionType.badCertificate,
      ),
      message: 'Something went wrong.',
    );
  });

  test('includes the HTTP status code for server responses', () async {
    await expectApiError(
      createError: (options) => DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
        type: DioExceptionType.badResponse,
      ),
      message: 'Server error (HTTP 500). Please try again later.',
      statusCode: 500,
    );
  });

  test(
    'uses a generic server message when the status code is missing',
    () async {
      await expectApiError(
        createError: (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
        ),
        message: 'Server error. Please try again later.',
      );
    },
  );

  test('reports cancelled requests', () async {
    await expectApiError(
      createError: (options) =>
          DioException(requestOptions: options, type: DioExceptionType.cancel),
      message: 'Request cancelled.',
    );
  });

  test('keeps network failures labeled as no internet', () async {
    final apiClient = ApiClient(
      dio: dioWithError(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('Network is unreachable'),
        ),
      ),
    );

    await expectLater(
      apiClient.getArticles(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'No internet connection.',
        ),
      ),
    );
  });

  test(
    'reports socket failures from unknown Dio errors as no internet',
    () async {
      final apiClient = ApiClient(
        dio: dioWithError(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: const SocketException('Network is unreachable'),
          ),
        ),
      );

      await expectLater(
        apiClient.getArticles(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'No internet connection.',
          ),
        ),
      );
    },
  );
}
