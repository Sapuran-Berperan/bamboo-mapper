import 'package:bamboo_app/src/data/datasources/auth_remote_datasource.dart';
import 'package:bamboo_app/src/data/models/auth/register_request.dart';
import 'package:bamboo_app/src/domain/entities/e_user.dart';
import 'package:bamboo_app/src/domain/repositories/r_user.dart';

class InfrastructureUser implements RepositoryUser {
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource.instance;

  @override
  Future<EntitiesUser> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final request = RegisterRequest(
      name: name,
      email: email,
      password: password,
    );

    final response = await _authDataSource.register(request);

    return EntitiesUser(
      id: response.id,
      name: response.name,
      email: response.email,
      role: response.role,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }

  @override
  Future<EntitiesUser?> readUser(String email) async {
    // TODO: Will be implemented when login is migrated
    throw UnimplementedError('Login will be migrated separately');
  }

  @override
  Future<List<EntitiesUser?>> readUsers() {
    throw UnimplementedError();
  }

  @override
  Future<EntitiesUser?> updateUser(EntitiesUser user) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String id) {
    throw UnimplementedError();
  }
}
