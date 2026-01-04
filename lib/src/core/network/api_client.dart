import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_exception.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor for automatic token refresh
    _dio.interceptors.add(AuthInterceptor(dio: _dio));

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET request that returns a list of items in the 'data' field
  Future<ApiListResponse<T>> getList<T>(
    String path, {
    Map<String, String>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return _handleListResponse(response, fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiListResponse<T> _handleListResponse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data;
    if (data == null) {
      throw const ServerException('Response kosong dari server');
    }

    final apiResponse = ApiListResponse.fromJson(data, fromJson);

    if (!apiResponse.isSuccess) {
      _throwApiException(response.statusCode, apiResponse.meta);
    }

    return apiResponse;
  }

  ApiResponse<T> _handleResponse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final data = response.data;
    if (data == null) {
      throw const ServerException('Response kosong dari server');
    }

    final apiResponse = ApiResponse.fromJson(data, fromJson);

    if (!apiResponse.isSuccess) {
      _throwApiException(response.statusCode, apiResponse.meta);
    }

    return apiResponse;
  }

  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }

    final response = e.response;
    if (response == null) {
      return const NetworkException();
    }

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('meta')) {
      final meta = ApiMeta.fromJson(data['meta'] as Map<String, dynamic>);
      _throwApiException(response.statusCode, meta);
    }

    return ServerException(
      'Terjadi kesalahan: ${response.statusCode}',
      response.statusCode,
    );
  }

  Never _throwApiException(int? statusCode, ApiMeta meta) {
    switch (statusCode) {
      case 400:
        final fieldErrors = <String, String>{};
        if (meta.details != null) {
          meta.details!.forEach((key, value) {
            fieldErrors[key] = value.toString();
          });
        }
        throw ValidationException(meta.message, fieldErrors, statusCode);
      case 401:
        throw UnauthorizedException(meta.message, statusCode);
      case 409:
        throw ConflictException(meta.message, statusCode);
      default:
        throw ServerException(meta.message, statusCode);
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
