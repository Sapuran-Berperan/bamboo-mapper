import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/routes/routes.dart';
import '../../data/models/auth/refresh_request.dart';
import '../../data/models/auth/refresh_response.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
  }) : _dio = dio {
    // Create a clean Dio instance for refresh requests
    // - No Authorization header (avoids sending expired token)
    // - No AuthInterceptor (avoids recursion issues)
    _refreshDio = Dio(BaseOptions(
      baseUrl: dio.options.baseUrl,
      connectTimeout: dio.options.connectTimeout,
      receiveTimeout: dio.options.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  final Dio _dio;
  late final Dio _refreshDio;
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
    // Use _refreshDio instead of _dio to avoid sending expired access token
    final response = await _refreshDio.post<Map<String, dynamic>>(
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
      contentType: requestOptions.contentType,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
    );

    // Rebuild FormData if the original request was multipart
    // FormData can only be sent once (stream gets consumed)
    dynamic data = requestOptions.data;
    final extra = requestOptions.extra;

    if (extra['isMultipart'] == true) {
      data = await _rebuildFormData(extra);
    }

    return _dio.request<dynamic>(
      requestOptions.path,
      data: data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Rebuild FormData from stored metadata for retry
  Future<FormData> _rebuildFormData(Map<String, dynamic> extra) async {
    final fields = extra['fields'] as Map<String, dynamic>? ?? {};
    final filePath = extra['filePath'] as String?;
    final fileFieldName = extra['fileFieldName'] as String? ?? 'image';

    return FormData.fromMap({
      ...fields,
      if (filePath != null) fileFieldName: await MultipartFile.fromFile(filePath),
    });
  }

  Future<void> _clearSessionAndReject(
    ErrorInterceptorHandler handler,
    DioException err,
  ) async {
    await TokenStorage.instance.clearTokens();
    _dio.options.headers.remove('Authorization');

    // Navigate to login page when session is invalid
    debugPrint('AuthInterceptor: Session expired, redirecting to login');
    router.go('/login');

    handler.reject(err);
  }
}
