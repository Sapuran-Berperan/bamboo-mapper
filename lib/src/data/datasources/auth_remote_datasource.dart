import '../../core/network/api_client.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/refresh_request.dart';
import '../models/auth/refresh_response.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_response.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource._();
  static final AuthRemoteDataSource instance = AuthRemoteDataSource._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<UserResponse> register(RegisterRequest request) async {
    final response = await _apiClient.post<UserResponse>(
      '/auth/register',
      data: request.toJson(),
      fromJson: UserResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Data response tidak valid');
    }

    return response.data!;
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post<LoginResponse>(
      '/auth/login',
      data: request.toJson(),
      fromJson: LoginResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Data response tidak valid');
    }

    return response.data!;
  }

  Future<RefreshResponse> refreshToken(RefreshRequest request) async {
    final response = await _apiClient.post<RefreshResponse>(
      '/auth/refresh',
      data: request.toJson(),
      fromJson: RefreshResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Data response tidak valid');
    }

    return response.data!;
  }

  Future<UserResponse> getCurrentUser() async {
    final response = await _apiClient.get<UserResponse>(
      '/auth/me',
      fromJson: UserResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Data response tidak valid');
    }

    return response.data!;
  }

  Future<void> logout() async {
    await _apiClient.post<void>('/auth/logout');
  }
}
