import 'package:bamboo_app/src/domain/entities/e_user.dart';
import 'package:bamboo_app/src/domain/infrastructure/i_user.dart';

class ServiceUser {
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

  Future<EntitiesUser?> signIn(String email, String password) async {
    // TODO: Will be migrated to use new backend login API
    throw UnimplementedError('Login will be migrated separately');
  }
}
