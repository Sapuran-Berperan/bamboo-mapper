import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/auth/refresh_request.dart';
import '../../data/models/auth/refresh_response.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for auth endpoints (login, register, refresh)
    final path = err.requestOptions.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    // Prevent multiple refresh attempts
    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await TokenStorage.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _isRefreshing = false;
        await _clearSessionAndReject(handler, err);
        return;
      }

      // Attempt token refresh
      final refreshResponse = await _refreshToken(refreshToken);

      // Save new tokens
      await TokenStorage.instance.saveTokens(
        accessToken: refreshResponse.accessToken,
        refreshToken: refreshResponse.refreshToken,
      );

      // Update auth header
      _dio.options.headers['Authorization'] =
          'Bearer ${refreshResponse.accessToken}';

      _isRefreshing = false;

      // Retry original request with new token
      final retryResponse = await _retryRequest(
        err.requestOptions,
        refreshResponse.accessToken,
      );

      return handler.resolve(retryResponse);
    } catch (e) {
      _isRefreshing = false;
      debugPrint('Token refresh failed: $e');
      await _clearSessionAndReject(handler, err);
    }
  }

  Future<RefreshResponse> _refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: RefreshRequest(refreshToken: refreshToken).toJson(),
    );

    final data = response.data;
    if (data == null) {
      throw const UnauthorizedException('Token refresh failed');
    }

    final apiResponse = ApiResponse.fromJson(data, RefreshResponse.fromJson);
    if (!apiResponse.isSuccess || apiResponse.data == null) {
      throw const UnauthorizedException('Token refresh failed');
    }

    return apiResponse.data!;
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _clearSessionAndReject(
    ErrorInterceptorHandler handler,
    DioException err,
  ) async {
    await TokenStorage.instance.clearTokens();
    _dio.options.headers.remove('Authorization');
    handler.reject(err);
  }
}
