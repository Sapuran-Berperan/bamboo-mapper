import 'package:bamboo_app/src/domain/entities/e_user.dart';

abstract class RepositoryUser {
  Future<EntitiesUser> createUser({
    required String name,
    required String email,
    required String password,
  });
  Future<EntitiesUser?> readUser(String email);
  Future<List<EntitiesUser?>> readUsers();
  Future<EntitiesUser?> updateUser(EntitiesUser user);
  Future<void> deleteUser(String id);
}
