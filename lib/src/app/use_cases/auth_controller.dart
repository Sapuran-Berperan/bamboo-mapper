import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/core/network/api_exception.dart';
import 'package:bamboo_app/src/domain/service/s_user.dart';

class RegisterResult {
  const RegisterResult({
    required this.success,
    this.errorMessage,
    this.fieldErrors,
  });

  final bool success;
  final String? errorMessage;
  final Map<String, String>? fieldErrors;
}

class AuthController {
  const AuthController();

  Future<bool> signIn(String email, String password) async {
    // TODO: Will be migrated to use new backend login API
    throw UnimplementedError('Login will be migrated separately');
  }

  Future<RegisterResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await ServiceUser().signUp(
        name: name,
        email: email,
        password: password,
      );
      router.go('/login');
      return const RegisterResult(success: true);
    } on ValidationException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
    } on ConflictException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: 'Email sudah terdaftar',
        fieldErrors: {'email': e.message},
      );
    } on NetworkException catch (_) {
      return const RegisterResult(
        success: false,
        errorMessage: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on ApiException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }
}
