import 'package:bamboo_app/src/core/network/api_client.dart';
import 'package:bamboo_app/src/core/storage/token_storage.dart';
import 'package:bamboo_app/src/data/datasources/auth_remote_datasource.dart';
import 'package:bamboo_app/src/data/models/auth/login_request.dart';
import 'package:bamboo_app/src/domain/entities/e_user.dart';
import 'package:bamboo_app/src/domain/infrastructure/i_user.dart';
import 'package:flutter/foundation.dart';

class ServiceUser {
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource.instance;
  final TokenStorage _tokenStorage = TokenStorage.instance;
  final ApiClient _apiClient = ApiClient.instance;

  Future<EntitiesUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return InfrastructureUser().createUser(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<EntitiesUser> signIn(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    final response = await _authDataSource.login(request);

    // Save tokens
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // Set auth header
    _apiClient.setAuthToken(response.accessToken);

    // Convert to entity
    return EntitiesUser(
      id: response.user.id,
      name: response.user.name,
      email: response.user.email,
      role: response.user.role,
      createdAt: response.user.createdAt,
      updatedAt: response.user.updatedAt,
    );
  }

  Future<EntitiesUser?> restoreSession() async {
    final hasTokens = await _tokenStorage.hasTokens();
    if (!hasTokens) {
      return null;
    }

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null) {
        _apiClient.setAuthToken(accessToken);
      }

      final userResponse = await _authDataSource.getCurrentUser();

      return EntitiesUser(
        id: userResponse.id,
        name: userResponse.name,
        email: userResponse.email,
        role: userResponse.role,
        createdAt: userResponse.createdAt,
        updatedAt: userResponse.updatedAt,
      );
    } catch (e) {
      debugPrint('Failed to restore session: $e');
      await _clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _authDataSource.logout();
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    await _tokenStorage.clearTokens();
    _apiClient.clearAuthToken();
  }
}
