import '../../core/network/api_client.dart';
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
}
